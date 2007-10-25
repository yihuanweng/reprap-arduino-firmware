/******************
* Get our libraries
******************/
#include <CartesianBot.h>
#include <ThermoplastExtruder.h>

/********************************
* digital i/o pin assignment
********************************/
#define X_HOME_PIN 2
#define Y_HOME_PIN 3
#define EXTRUDER_MOTOR_DIR_PIN 4
#define EXTRUDER_MOTOR_SPEED_PIN 5
#define EXTRUDER_HEATER_PIN 6
#define X_DIR_PIN 7
#define X_STEP_PIN 8
#define Y_DIR_PIN 9
#define Y_STEP_PIN 10
#define Z_HOME_PIN 11
#define Z_DIR_PIN 12
#define Z_STEP_PIN 13

/********************************
* analog input pin assignments
********************************/
#define EXTRUDER_THERMISTOR_PIN 0
#define X_ENCODER_PIN 1
#define Y_ENCODER_PIN 2
#define Z_ENCODER_PIN 3
#define EXTRUDER_MOTOR_ENCODER_PIN 4

/********************************
*  Global variable declarations
********************************/

//our main objects
CartesianBot bot();
ThermoplastExtruder extruder(EXTRUDER_MOTOR_DIR_PIN, EXTRUDER_MOTOR_SPEED_PIN, EXTRUDER_HEATER_PIN, EXTRUDER_THERMISTOR_PIN);

void setup()
{
	//fire up our serial comms.
	Serial.begin(57600);
	Serial.println("RepDuino v1.0 started up.");

	//add our stepper motors in.
	bot.addStepper('x', 200, X_DIR_PIN, X_STEP_PIN);
	bot.addStepper('y', 200, Y_DIR_PIN, Y_STEP_PIN);
	bot.addStepper('z', 200, Z_DIR_PIN, Z_STEP_PIN);

	//also, our home switches.
	bot.addHomeSwitch('x', X_HOME_PIN);
	bot.addHomeSwitch('y', Y_HOME_PIN);
	bot.addHomeSwitch('z', Z_HOME_PIN);

	//what about our encoders?
	bot.addEncoder('x', X_ENCODER_PIN);
	bot.addEncoder('y', Y_ENCODER_PIN);
	bot.addEncoder('z', Z_ENCODER_PIN);
}

void loop()
{
	receiveCommands();
	readState();
	updateStatus();
	executeCommands();
}

void receiveCommands()
{
	int incoming;
	
	while (Serial.available() > 1)
	{
		incoming = Serial.read();
		
		//get our version
		if (incoming == 'A')
			printVersion();
		//queue point
		else if (incoming == 'B')
			queuePoint();
		//abort our print!
		else if (incoming == 'C')
			abortPrint();
		//set our heater temperature
		else if (incoming == 'D')
			extruder.setTargetTemp(Serial.read());
		//take me home, country roads!
		else if (incoming == 'E')
			goHome();
		//set our extruder speed
		else if (incoming == 'F')
			readExtruderSettings();
		//what did you say to me?!?
		else
		{
			Serial.print("Command not understood: ");
			Serial.println(incoming);
		}
	}
}

void readState()
{
	extruder.readState();
	bot.readState();
}

void updateStatus()
{
	//let them know its our status line.
	//Serial.print('Status:');

/*	
	//our analog readings.
	Serial.print("T:");
	Serial.print(thermistor_reading);
	Serial.print('Xe:');
	Serial.print(x_encoder_reading);
	Serial.print('Ye:');
	Serial.print(y_encoder_reading);
	Serial.print('Ze:');
	Serial.print(z_encoder_reading);
	Serial.print('Ee:');
	Serial.print(extruder_motor_encoder_reading);

	//our current position and such
	Serial.print('Xp:');
	Serial.print(x_position);
	Serial.print('Yp:');
	Serial.print(y_position);
	Serial.print('Zp:');
	Serial.print(z_position);

	//are we at our limit?
	Serial.print('Xmin:');
	Serial.print(x_at_home);
	Serial.print('Ymin:');
	Serial.print(y_at_home);
	Serial.print('Zmin:');
	Serial.print(z_at_home);

	//what direction?
	Serial.print('Xdir:');
	Serial.print(x_direction);
	Serial.print('Ydir:');
	Serial.print(y_direction);
	Serial.print('Zdir:');
	Serial.print(z_direction);

	//what about our extruder?
	Serial.print('Edir:');
	Serial.print(extruder_direction);
	Serial.print('Espeed:');
	Serial.print(extruder_speed);
	Serial.print('Heater:');
	Serial.print(extruder_heater_pwm);
	Serial.print();
*/	
	//end our data transmission
	Serial.println('!');
}

void executeCommands()
{
	extruder.manageTemp();
	cartesianbot.move();
}

struct Point unqueuePoint()
{
	Point temp;
	
	//get our first point.
	temp = point_queue[0];
	
	//shift the array down now.
	for (int i=0; i<point_index-1; i++)
		point_queue[i] = point_queue[i+1];
	point_index++;
	
	//send it!
	return temp;
}

void checkCartesianBot()
{
	//if we're at our point, get a new one!
	if (atPoint(target_point))
	{
		//if we have any points left, get one!
		if (point_index > 0)
			target_point = unqueuePoint();
		else
			return;
	}

	//okay, now step to this!
	stepToPoint(target_point);
}

bool atPoint(struct Point &target)
{
	if (target.x == current_position.x && target.y == current_position.y && target.z == current_position.z)
		return true;
	else
		return false;
}

void stepToPoint(struct Point &target)
{
	if (target.x != current_position.x)
		x_stepper.step();
	
	if (target.y != current_position.y)
		y_stepper.step();
		
	if (target.z != current_position.z)
		z_stepper.step();
}

void printVersion()
{
	Serial.println("RepDuino v1.0");
}

void queuePoint()
{
	if(point_index < (POINT_QUEUE_SIZE - 1))
	{
		//read in our points.
		point_queue[point_index].x = readInt();
		point_queue[point_index].y = readInt();
		point_queue[point_index].z = readInt();
		
		//move our pointer forward.
		point_index++;
	}
	else
		Serial.println("Point queue is full!");
}

int readInt()
{
	int tmp;

	//read in an integer.
	tmp = Serial.read();
	tmp = tmp << 8;
	tmp |= Serial.read();
	
	return tmp;
}

void abortPrint()
{
	extruder.abort();
	cartesianbot.abort();
}

void goHome()
{
	//clear our queue, and tell it to go home.
	//the endstops will take care of the rest. (hopefully)
	point_index = 0;
	point_queue[0].x = -100;
	point_queue[0].y = -100;
	point_queue[0].z = -100;
}

void readExtruderSettings()
{
	extruder.setDirection(Serial.read());
	extruder.setSpeed(Serial.read());
}