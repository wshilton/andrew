/*
  Analog Input

  Demonstrates analog input by reading an analog sensor on analog pin 0 and
  turning on and off a light emitting diode(LED) connected to digital pin 13.
  The amount of time the LED will be on and off depends on the value obtained
  by analogRead().

  The circuit:
  - potentiometer
    center pin of the potentiometer to the analog input 0
    one side pin (either one) to ground
    the other side pin to +5V
  - LED
    anode (long leg) attached to digital output 13 through 220 ohm resistor
    cathode (short leg) attached to ground

  - Note: because most Arduinos have a built-in LED attached to pin 13 on the
    board, the LED is optional.

  created by David Cuartielles
  modified 30 Aug 2011
  By Tom Igoe

  This example code is in the public domain.

  https://www.arduino.cc/en/Tutorial/BuiltInExamples/AnalogInput
*/

int inphase = A0;    // select the input pin for the potentiometer
int quadrature = A1;      // select the pin for the LED

int inphaseValue = 0;  // variable to store the value coming from the sensor
int quadratureValue = 0;  // variable to store the value coming from the sensor

double inphase_V = 0; //Need to check documentation for type information
double quadrature_V = 0; //Need to check documentation for type information

double amplitude_dBV = 0;

double analogToVolts = 5.0/1023.0;

void setup() {
  
  //open USB comms
  while (!Serial);
    Serial.begin(9600);
}

void loop() {
  // read the value from the sensor:
  inphaseValue = analogRead(inphase);
  quadratureValue = analogRead(quadrature);

  // convert analog reading to dBV
  //amplitude_dBV = 20.0*log10(sqrt(pow(analogToVolts*inphaseValue,2.0)+pow(analogToVolts*quadratureValue,2.0)));
  //python can handle the transformation without substantial latency at 50 ms sample rate
  //so sending over the signed integer tuple for now
  
  //send over USB
  Serial.print(inphaseValue);
  Serial.print(" ");
  Serial.print(quadratureValue);
  Serial.print("\n");

  delay(50);
  
}
