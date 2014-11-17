import processing.pdf.*;
PFont font;
PShape template;
Table data;
int numRows, cr = 0; // current row

void setup() {
  size(792, 612);
  font = createFont("BebasNeue Book.otf", 32);
  textFont(font);
  smooth();
  template = loadShape("template.svg");
  
  // load data
  data = loadTable("master_data.tsv", "header");
  numRows = data.getRowCount();
  
  buildProfile(data.getRow(0));
}

void draw() {
  /*buildProfile(data.getRow(cr));
  cr++;
  if (cr == numRows) exit();*/
}

void buildProfile(TableRow row) {
  String countyName = getString(row, "County");
  String stateName = getString(row, "State");
  String fullCountyName = countyName + ", " + stateName;
  beginRecord(PDF, "/profiles/" + fullCountyName + ".pdf");

  background(255);
  shape(template, 0, 0);
  
  
  /* ----------- Sizing Up Text ------------ */
  String popsize = getString(row, "PopulationSize");
  String cbsa_name = getString(row, "cbsa_name");
  String cbsa_level = getString(row, "cbsa_level");
  String is_central = getString(row, "is_central");
    
  String centralText = "";
  if (cbsa_name == "1") centralText = ", central";
  else if (cbsa_name == "0") centralText = ", outlying";
  String metroText = " not in a metropolitan/micropolitan area.";
  if (cbsa_level == "1") metroText = " in the " + is_central + " micropolitan area.";
  else if (cbsa_level == "2") metroText = " in the " + is_central + " metropolitan area.";

  String sizeText1 = fullCountyName + " has a county government.";
  String sizeText2 = countyName + " is a " + popsize + centralText + " county" + metroText;
  
  /* ------------ Sizing Up Numbers -------------- */
  int population = row.getInt("Population");
  int gdp = row.getInt("RGDP2014");
  Float unemp_rate = row.getFloat("unem2014");
  int avg_pay = row.getInt("avgWage13");
  Float avg_pay_growth = row.getFloat("avgWageGrowth12");
  
  String popText = nfc(population); 
  if (population >= 1000000) popText = nf(population/1000000, 0, 1) + " MILLION";
  String gdpText = "$" + nfc(gdp);
  if (gdp > 1000000) gdpText = "$" + nf(gdp/1000000, 0, 1) + " MILLION";
  else if (gdp > 1000000000) gdpText = "$" + nf(gdp/1000000000, 0, 1) + " BILLION";
  String avgPayText = "$" + nfc(avg_pay);
  String avgPayGrowthText = nf(avg_pay_growth, 0, 1) + "%";
  String unempRateText = nf(unemp_rate, 0, 1) + "%";
  
  
  /* --------------- Graph Data -------------------- */
  fill(0);
  textSize(12);
  
  int startYear = 2002, endYear = 2014;
  float graphHeight = 76, graphWidth = 126, graphSep = 165;
  int graphsOriginX = 135, graphOriginY = 260;
  String[] indicators = {"unem", "jobs", "RGDP", "HHprice"};
  
  String sizeTypeText = popsize + " counties";
  
  for (int ind_num = 0; ind_num < indicators.length; ind_num++) {
    String indicator = indicators[ind_num];
    float graphOriginX = graphsOriginX + graphSep * ind_num;
    
    float[] countyVals = new float[endYear - startYear + 1];
    float[] aggVals = new float[endYear - startYear + 1];
    
    float lowVal, highVal;
    float yTickStep = 5;   
    
    // get data values
    if (indicator == "unem") {
      // unemployment is graphed differently from others
      float lowestVal = 100, highestVal = 0;
      
      for (int year = startYear; year <= endYear; year++) {
        float countyVal = row.getFloat(indicator + Integer.toString(year));
        float aggVal = row.getFloat("agg" + indicator + Integer.toString(year));

        // store the values in array
        countyVals[year - startYear] = countyVal;
        aggVals[year - startYear] = aggVal;
        
        // update lowest and highest values
        if (countyVal < lowestVal) lowestVal = countyVal;
        if (countyVal > highestVal) highestVal = countyVal;
        if (aggVal < lowestVal) lowestVal = aggVal;
        if (aggVal > highestVal) highestVal = aggVal;
      }
      
      // round off lowest and highest val to a single decimal point
      highestVal = ceil(highestVal);
      lowestVal = floor(lowestVal);     
      yTickStep = (highestVal - lowestVal) / 5;

      lowVal = lowestVal;
      highVal = highestVal;
    } else {
      // find lowest and highest values
    int lowestVal = 100, highestVal = 100;
      float baseCountyVal = -1.0, baseAggVal = -1.0;
  
      for (int year = startYear; year <= endYear; year++) {
        float countyVal = row.getFloat(indicator + Integer.toString(year));
        float aggVal = row.getFloat("agg" + indicator + Integer.toString(year));
        
        // scale the values with respect to the start year
        if (year == startYear) {
          baseCountyVal = countyVal;
          baseAggVal = aggVal;
          countyVal = 100;
          aggVal = 100;
        } else {
          countyVal = 100 * countyVal / baseCountyVal;
          aggVal = 100 * aggVal / baseAggVal;
        }
  
        // store the scaled values in array
        countyVals[year - startYear] = int(countyVal);
        aggVals[year - startYear] = int(aggVal);
        
        // store lowest and highest values
        if (int(countyVal) < lowestVal) lowestVal = int(countyVal);
        if (int(countyVal) > highestVal) highestVal = int(countyVal);
        if (int(aggVal) < lowestVal) lowestVal = int(aggVal);
        if (int(aggVal) > highestVal) highestVal = int(aggVal);          
      }
      
      // round range endpoints to the nearest 5, if range is more than 40, round to nearest 10 
      highestVal = (highestVal / 5) * 5 + 5;
      lowestVal = (lowestVal / 5) * 5;
      if (highestVal - lowestVal > 40) {
        yTickStep = 10;
        highestVal = (highestVal / 10) * 10 + 10;
        lowestVal = (lowestVal / 10) * 10;
      }

      lowVal = float(lowestVal);
      highVal = float(highestVal);
    }
    
    float pixelsPerYear = graphWidth / (endYear - startYear);
    float pixelsPerPoint = graphHeight / (highVal - lowVal);

    
    // draw peak year line
    stroke(100);
    strokeWeight(2);
    int peakYear = row.getInt("peak" + indicator + "year");
    float xCoordPeak = graphOriginX + pixelsPerYear * (peakYear - startYear);
    line(xCoordPeak, graphOriginY, xCoordPeak, graphOriginY - graphHeight);

    // draw recovery period
    strokeWeight(0);
    fill(220);
    int troughYear = row.getInt("trough" + indicator + "year");    
    if (troughYear > peakYear) {
      float xCoordTrough = graphOriginX + pixelsPerYear * (troughYear - startYear);
      float widthTrough = pixelsPerYear * (endYear - troughYear);
      rect(xCoordTrough, graphOriginY, widthTrough, -graphHeight);
    } 
    
    
    // draw y ticks and y labels
    fill(100);
    strokeWeight(1);
    textAlign(RIGHT, CENTER);
    for (float val = lowVal; val <= highVal; val += yTickStep) {
      float xCoord = graphOriginX;
      float yCoord = graphOriginY - pixelsPerPoint * (val - lowVal);
      if (indicator == "unem") text(nf(val, 0, 1) + "%", xCoord - 2, yCoord); 
      else text(int(val), xCoord - 2, yCoord);
      line(xCoord, yCoord, xCoord + graphWidth, yCoord);
    }


    // draw line
    strokeWeight(2);
    for (int i = 0; i < countyVals.length - 1; i++) {
      float startX = graphOriginX + pixelsPerYear * i;
      float endX = graphOriginX + pixelsPerYear * (i + 1);
      float startY = graphOriginY - pixelsPerPoint * (countyVals[i] - lowVal);
      float endY = graphOriginY - pixelsPerPoint * (countyVals[i+1] - lowVal);
      stroke(0);
      line(startX, startY, endX, endY);

      // draw lines for aggregate levels
      float aggStartY = graphOriginY - pixelsPerPoint * (aggVals[i] - lowVal);
      float aggEndY = graphOriginY - pixelsPerPoint * (aggVals[i+1] - lowVal);
      stroke(150);
      line(startX, aggStartY, endX, aggEndY);
    }    
  }


  /* --------------- Bar Data -------------------- */
  float barGraphHeight = 15, barGraphWidth = 100, barSep = 50;
  float barOriginX = 550, barOriginsY = 350;
  float baseGDP = 0;
  
  for (int i = 1; i <= 5; i++) {
    float barOriginY = barOriginsY + barSep * (i - 1);
    
    String description = getString(row, "industry_desc" + i);
    float gdpVal = row.getFloat("industry_gdp" + i);    
    if (i == 1) baseGDP = gdpVal; 
    float barWidth = (gdpVal / baseGDP) * barGraphWidth;
    
    println("gdp: " + gdpVal + ", baseGDP: " + baseGDP + ", barWidth: " + barWidth);
    
    textAlign(LEFT);
    text(description, barOriginX, barOriginY);
    strokeWeight(0);
    fill(150);
    rect(barOriginX, barOriginY + 10, barWidth, barGraphHeight);
  }
  
  endRecord();   
}

String getString(TableRow row, String colName) {
  String value = row.getString(colName);
  return value.substring(1, value.length() - 1);
}
