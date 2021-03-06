import papaya.*;

float theta1 = 0;
float theta2 = 0;
float a1 = 100;
float a2 = 100;

float centerPos = 300;
float sizeOfAxis = 10;

int grabSlider = 0;
int isIKMode = 0;
int isStartIKMode = 0;
int previousState = 0;
float slidePos1, slidePos2;

float[][] y0 = {{1,0,0,0},{0,1,0,0},{0,0,1,0},{0,0,0,1}};
float[][] pol0 = {{10,20,10,10},{10,10,20,10},{0,0,0,0},{1,1,1,1}};

PFont titleFont = createFont("Helvetica",20,true);
PFont smallFont = createFont("Helvetica",12,true);
PFont tinyFont = createFont("Helvetica",9,true);

void setup() {
	size(600,600);
}

void draw() {
	background(255);

	drawPanel();	

	if (isStartIKMode==1) {

		float[] tmp = calcInverseKinematics(mouseX - centerPos, centerPos - mouseY, a1, a2);

		if (previousState == 1) {
			if (tmp[1] > 0) {
				theta1 = tmp[0];
				theta2 = tmp[1];
			} else {
				theta1 = tmp[2];
				theta2 = tmp[3];
			}
		} else {
			if (tmp[1] < 0) {
				theta1 = tmp[0];
				theta2 = tmp[1];
			} else {
				theta1 = tmp[2];
				theta2 = tmp[3];
			}
		}

		drawBody(theta1, theta2);

	} else {

		drawBody(theta1, theta2);

		if (theta2 < 0) { previousState = -1; }
		else { previousState = 1; }

	}
}

void drawBody(float th1, float th2) {
	// calculation forward kinematics
	float[][] T_0_1 = Mat.multiply(RotM('a', th1), TransM(a1,0,0));
	float[][] T_1_2 = Mat.multiply(RotM('a', th2), TransM(a2,0,0));
	float[][] T_total = Mat.multiply(T_0_1, T_1_2);

	float[][] y0_1 = Mat.multiply(T_0_1, y0);
	float[][] y0_2 = Mat.multiply(T_total, y0);
	//

	float[] originX = { y0[0][3], y0_1[0][3], y0_2[0][3] };
	float[] originY = { y0[1][3], y0_1[1][3], y0_2[1][3] };

	// draw ellipse of joint
	noFill();
	stroke(200);
	ellipse(centerPos + y0[0][3], centerPos - y0[1][3], a1*2, a1*2);
	ellipse(centerPos + y0_1[0][3], centerPos - y0_1[1][3], a2*2, a2*2);

	// draw body lines
	strokeWeight(2);
	stroke(color(#8E8E8E));
	line(centerPos + originX[0], centerPos - originY[0], centerPos + originX[1], centerPos - originY[1]);
	line(centerPos + originX[1], centerPos - originY[1], centerPos + originX[2], centerPos - originY[2]);
	//

	// print angle of axis
	fill(50);
	textFont(tinyFont);
	text(nfs(theta1*180/PI,0,2), centerPos + originX[0], centerPos - originY[0] + 20);
	text(nfs(theta2*180/PI,0,2), centerPos + originX[1], centerPos - originY[1] + 20);
	String endPos = "( "+nfs(originX[2],0,2)+", "+nfs(originY[2],0,2)+" )";
	text(endPos, centerPos + originX[2]+20, centerPos - originY[2]+20);
	//

	drawBodyAxis(y0, centerPos, sizeOfAxis);
	drawBodyAxis(y0_1, centerPos, sizeOfAxis);
	drawBodyAxis(y0_2, centerPos, sizeOfAxis);

	float[][] pol0 = {{10,20,10},{10,10,20},{0,0,0},{1,1,1}};
	float[][] pol0_1 = Mat.multiply(T_0_1, pol0);
	float[][] pol0_2 = Mat.multiply(T_total, pol0);

	drawObject(pol0, centerPos);
	drawObject(pol0_1, centerPos);
	drawObject(pol0_2, centerPos);

	detectEndEffector(y0_2, centerPos);
}

float[] calcInverseKinematics(float Px, float Py, float a1, float a2) {
	float th2_1 =  2*atan( sqrt( ( sq( a1 + a2) - ( sq(Px) + sq(Py) ) ) / ( sq(Px) + sq(Py) - sq( a1 - a2 ) ) ) );
	float th2_2 = -2*atan( sqrt( ( sq( a1 + a2) - ( sq(Px) + sq(Py) ) ) / ( sq(Px) + sq(Py) - sq( a1 - a2 ) ) ) );
	float th1_1 = atan2(Py, Px) - atan( a2*sin(th2_1) / ( a1 + a2*cos(th2_1) ) );
	float th1_2 = atan2(Py, Px) - atan( a2*sin(th2_2) / ( a1 + a2*cos(th2_2) ) );

	if ((Float.isNaN(th2_1))||(Float.isNaN(th2_2))||(Float.isNaN(th1_1))||(Float.isNaN(th1_2))) {
		textFont(smallFont);
		text("Unsolved Inverse Kinematics.", centerPos - 80, centerPos - 50);
		th1_1 = th1_2 = theta1;
		th2_1 = th2_2 = theta2;
	}

	return new float[]{th1_1, th2_1, th1_2, th2_2};
}

void detectEndEffector(float[][] endMat, float centerPos) {
	if ((abs(mouseX - (endMat[0][3]+centerPos)) < 10) && (abs(mouseY - (centerPos-endMat[1][3])) < 10)) {
		noFill();
		stroke(150);
	 	ellipse(centerPos + endMat[0][3], centerPos - endMat[1][3], 10, 10);
	 	isIKMode = 1;
	} else {
		isIKMode = 0;
	}
}

float[][] RotM(char axis, float theta) {
	if (axis=='a') {
		return new float[][]{{cos(theta),-sin(theta), 0,0},{sin(theta),cos(theta), 0,0},{0,0,1,0},{0,0,0,1}};
	} else if (axis=='o') {
		return new float[][]{{cos(theta),0,sin(theta),0},{0,1,0,0},{-sin(theta),0,cos(theta),0},{0,0,0,1}};
	} else {
		return new float[][]{{1,0,0,0},{0,cos(theta),-sin(theta),0},{0,sin(theta),cos(theta),0},{0,0,0,1}};
	}
}

float[][] TransM(float x, float y, float z) {
	return new float[][]{{1,0,0,x},{0,1,0,y},{0,0,1,z},{0,0,0,1}};
}

void drawObject(float[][] obTarget, float centerPos) {
	stroke(color(#000000));
	noFill();
	beginShape();
		vertex(centerPos + obTarget[0][0], centerPos - obTarget[1][0]);
		vertex(centerPos + obTarget[0][1], centerPos - obTarget[1][1]);
		vertex(centerPos + obTarget[0][2], centerPos - obTarget[1][2]);
	endShape(CLOSE);
}

void drawBodyAxis(float[][] bodyMat, float centerPos, float sizeOfAxis) {
	stroke(color(#FF0000));
	line(centerPos + bodyMat[0][3], centerPos - bodyMat[1][3],
		centerPos + bodyMat[0][3] + bodyMat[0][0]*sizeOfAxis,
		centerPos - (bodyMat[1][3] + bodyMat[1][0]*sizeOfAxis));

	stroke(color(#008000));
	line(centerPos + bodyMat[0][3], centerPos - bodyMat[1][3],
		centerPos + bodyMat[0][3] + bodyMat[0][1]*sizeOfAxis,
		centerPos - (bodyMat[1][3] + bodyMat[1][1]*sizeOfAxis));	
}

void drawPanel() {
	fill(50);
	textFont(titleFont);
	text("Kinematics Example of Two Link Planar",140,25);
	textFont(smallFont);
	text("by PinkWink",500,45);

	stroke(150);
	line(50,550,280,550);
	line(320,550,550,550);

	if (grabSlider==1) {
		theta1 = (float(mouseX)-(50+280)/2)/115*PI;
	}

	if (grabSlider==2) {
		theta2 = (float(mouseX)-(320+550)/2)/115*PI;
	}

	slidePos1 = theta1*115/PI + (50+280)/2;
	slidePos2 = theta2*115/PI + (320+550)/2;

	stroke(100);
	fill(255);
	if (grabSlider==1) {fill(200);}
	ellipse(slidePos1,550,10,10);
	fill(255);
	if (grabSlider==2) {fill(200);}
	ellipse(slidePos2,550,10,10);
	fill(255);
	if (isStartIKMode==1) {
		fill(200);
		ellipse(mouseX, mouseY, 10, 10);
	}
}

void mousePressed() {
	if (mouseButton==LEFT) {
		if (abs(mouseX-(50+280)/2)<165 && abs(mouseY-550)<5) { grabSlider = 1; }
		if (abs(mouseX-(320+550)/2)<165 && abs(mouseY-550)<5) { grabSlider = 2; }
		if (isIKMode==1) { isStartIKMode = 1; }
		else { isStartIKMode = 0; }
	}
}

void mouseReleased() {
	if (mouseButton==LEFT) { 
		grabSlider = 0; 
		isIKMode = 0;
		isStartIKMode = 0;
	}
}