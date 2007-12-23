/*
  3Axis_Seek_Tester.pde - RepRap cartesian bot seek tester.

  History:
  * (0.1) Created initial version by Zach Smith.
*/

#include <SNAP.h>
#include <LimitSwitch.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>

/********************************
 * digital i/o pin assignment
 ********************************/
#define X_STEP_PIN 2
#define X_DIR_PIN 3
#define X_MIN_PIN 4
#define X_MAX_PIN 5
#define X_ENABLE_PIN 14
#define Y_STEP_PIN 6
#define Y_DIR_PIN 7
#define Y_MIN_PIN 8
#define Y_MAX_PIN 9
#define Y_ENABLE_PIN 15
#define Z_STEP_PIN 10
#define Z_DIR_PIN 11
#define Z_MIN_PIN 12
#define Z_MAX_PIN 13
#define Z_ENABLE_PIN 16

/********************************
 * how many steps do our motors have?
 ********************************/
#define X_MOTOR_STEPS 400
#define Y_MOTOR_STEPS 400
#define Z_MOTOR_STEPS 400

/********************************
 *  Global variable declarations
 ********************************/

//our cartesian bot object

CartesianBot bot(
                 'x', X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN, X_ENABLE_PIN,
                 'y', Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN, Y_ENABLE_PIN,
                 'z', Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN, Z_ENABLE_PIN
                 );
Point p;

int speed = 200;


SIGNAL(SIG_OUTPUT_COMPARE1A)
{
	if (bot.mode == MODE_SEEK)
	{
		if (bot.x.can_step)
			bot.x.doStep();

		if (bot.y.can_step)
			bot.y.doStep();

		if (bot.z.can_step)
			bot.z.doStep();
	}
}
	
void setup()
{
	bot.setupTimerInterrupt();

	bot.x.stepper.setRPM(speed);
	bot.y.stepper.setRPM(speed);
	bot.z.stepper.setRPM(speed);
	bot.setTimer(bot.x.stepper.getSpeed());
	bot.startSeek();
	
	Serial.begin(57600);
	Serial.println("Starting 3 axis exerciser.");

	Serial.print("RPM: ");
	Serial.println((int)bot.x.stepper.getRPM());
	Serial.print("Speed: ");
	Serial.println(bot.x.stepper.getSpeed());

	p.x = 6000;
	p.y = 0;
	p.z = 0;
	bot.queuePoint(p);
	
	p.x = 6000;
	p.y = 6000;
	p.z = 0;
	bot.queuePoint(p);

	p.x = 6000;
	p.y = 6000;
	p.z = 6000;
	bot.queuePoint(p);
}

void loop()
{
	//load up teh queue
	while (!bot.isQueueFull())
	{
		p.x = random(1000, 20000);
		p.y = random(1000, 20000);
		p.z = random(1000, 20000);
                bot.queuePoint(p);
	}

	//get our state status.
	bot.readState();
	
	//if we are at our target, stop us.
	if (bot.atTarget())
	{
		speed = random(200, 255);
		bot.x.stepper.setRPM(speed);
		bot.setTimer(bot.x.stepper.getSpeed());
		bot.getNextPoint();

		Serial.print("Setting RPM to ");
		Serial.println(speed);
		Serial.print("Speed is now: ");
		Serial.println(bot.x.stepper.getSpeed());

		Serial.print("Seeking to ");
		Serial.print(bot.x.getTarget());
		Serial.print(", ");
		Serial.print(bot.y.getTarget());
		Serial.print(", ");
		Serial.print(bot.z.getTarget());
		Serial.print(" at clock ");
		Serial.println((int)OCR1A);
	}
	
	//uncomment this if you want to find out what your status is.
/*
	Serial.print("At min: ");
	Serial.print(bot.x.atMin());
	Serial.print(" ");
	Serial.print(bot.y.atMin());
	Serial.print(" ");
	Serial.println(bot.z.atMin());

	Serial.print("At max: ");
	Serial.print(bot.x.atMax());
	Serial.print(" ");
	Serial.print(bot.y.atMax());
	Serial.print(" ");
	Serial.println(bot.z.atMax());
	
	Serial.print("At target: ");
	Serial.print(bot.x.atTarget());
	Serial.print(" ");
	Serial.print(bot.y.atTarget());
	Serial.print(" ");
	Serial.println(bot.z.atTarget());
	
	Serial.print("Can step: ");
	Serial.print(bot.x.can_step);
	Serial.print(" ");
	Serial.print(bot.y.can_step);
	Serial.print(" ");
	Serial.println(bot.z.can_step);
	delay(1000);
*/	
}