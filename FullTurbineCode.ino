#include <DHT.h>
#include <DHT_U.h>
#include <SPI.h>
#include <Stepper.h>

#define DHTPIN 13
#define DHTTYPE DHT11
#define SPEED_PIN 18
#define CURRENT_PIN A1
#define THERM_PIN A2

volatile int numberOfPasses = 0;
int lastTime = 0;
int dT = 0;
float fanSpeed = 0;
float voltage = 0;
float current = 0;
float avg_current_val = 0;
float avg_therm_val = 0;
float therm_temp = 0;
float dht_avg_humi = 0;
float dht_avg_tempC = 0;
const float therm_k = 11.45;

//Section 2


DHT dht(DHTPIN, DHTTYPE);
#define STEPS 2038 // the number of steps in one revolution of your motor (28BYJ-48)
Stepper stepper(STEPS, 8, 10, 9, 11);

//pin declarations
int soundSensor = A0;
#define CLK 2
#define DT 3
#define SW 4

volatile int currentStateCLK;
volatile int lastStateCLK;

volatile int vaneAngle = 0; //set to 0 at setup
float currentAngle = 0;

void setup() {
  // put your setup code here, to run once:
  dht.begin();
 
  pinMode(SPEED_PIN, INPUT);
  pinMode(CURRENT_PIN, INPUT);
  pinMode(THERM_PIN, INPUT);
  
  // Set encoder pins as inputs
  pinMode(CLK, INPUT);
  pinMode(DT, INPUT);
  pinMode(SW, INPUT_PULLUP);

   // Read the initial state of CLK
  lastStateCLK = digitalRead(CLK);

  attachInterrupt(digitalPinToInterrupt(CLK),vanePosition, CHANGE); //trigger anytime moves
  attachInterrupt(digitalPinToInterrupt(SPEED_PIN), bladePassed, RISING);
  lastTime = millis();

  // Setup Serial Monitor
  Serial.begin(38400);
 
}

void loop() {
   dT = millis() - lastTime;
   lastTime = millis();
   fanSpeed = ((numberOfPasses / 3.0) / dT) * 1000.0 * 60.0;
   numberOfPasses = 0;

   voltage = 5.0 * (avg_current_val / 1023.0);
   current = (voltage / 10) * 1000.0;

   therm_temp = (5.0 * (avg_therm_val / 1023.0)) * therm_k;
   
   avg_current_val = 0;
   avg_therm_val = 0;
   dht_avg_humi = 0;
   dht_avg_tempC = 0;
   int cnt = 50;
   for(int i = 0; i < cnt; i++){
      avg_current_val += analogRead(CURRENT_PIN);
      avg_therm_val += analogRead(THERM_PIN);
      dht_avg_humi += dht.readHumidity();
      dht_avg_tempC += dht.readTemperature();
   }
   avg_current_val = avg_current_val / cnt;
   avg_therm_val = avg_therm_val / cnt;
   dht_avg_humi = dht_avg_humi / cnt;
   dht_avg_tempC = dht_avg_tempC / cnt;


//vane data
  String windDirection = String(vaneAngle);
  moveStepper(vaneAngle);
  String amountSound = soundData();
  String dataToSend = ", windDirection:" + windDirection + "," + "turbineSound:" + amountSound;


   Serial.print("Speed: ");
   Serial.print(fanSpeed);
   Serial.print(", Current: ");

   Serial.print(current);
   Serial.print(", Therm temp: ");

   Serial.print(therm_temp);
   Serial.print(", DHT Temp: ");
   Serial.print(dht_avg_tempC);
   Serial.print(", DHT Humidity: ");
   Serial.print(dht_avg_humi);

    Serial.println(dataToSend);
   

}

void bladePassed() {
  numberOfPasses = numberOfPasses + 1;
}


String soundData()
{
  int currentSound = analogRead(soundSensor);
  return String(currentSound/1023.0*5.0); //converting to 
}

String vanePosition()
{

 // noInterrupts();
  // Read the current state of CLK
  currentStateCLK = digitalRead(CLK);

  float degPerClick = 360.0 / 20.0;

  // If last and current state of CLK are different, then pulse occurred
  // React to only 1 state change to avoid double count
  if (currentStateCLK != lastStateCLK  && currentStateCLK == 1) {

    // If the DT state is different than the CLK state then
    // the encoder is rotating CCW so decrement
    if (digitalRead(DT) != currentStateCLK) {
      vaneAngle -= degPerClick;
    } else {
      // Encoder is rotating CW so increment
      vaneAngle += degPerClick;
    }
    if (vaneAngle > 360)
    {
      vaneAngle = 0 + degPerClick;
    }
    else if (vaneAngle < 0)
    {
      vaneAngle = 360 - degPerClick;
    }

  }

  // Remember last CLK state
  lastStateCLK = currentStateCLK;
  
  //interrupts();
  //delay(1);
  //return String(vaneAngle);
}

String moveStepper(float desiredAngle)
{
  stepper.setSpeed(6); // 6 rpm

  float stepsPerDeg = 2038.0 / 360;
  float vaneAngleToMove = desiredAngle - currentAngle;

  if (vaneAngleToMove <= 180) //step forwards
  {
    stepper.step(-vaneAngleToMove * stepsPerDeg);
    currentAngle = desiredAngle;
  }
  else //desired-current > 180
  {
    vaneAngleToMove = 360 - vaneAngleToMove; //since moving in reverse
    stepper.step(vaneAngleToMove * stepsPerDeg);
    currentAngle = desiredAngle;
  }

  return String(currentAngle);
}
