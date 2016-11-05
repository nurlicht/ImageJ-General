/**
 * Plots the average Mean Square Distance (MSD) vs. Lag Time of a given track. The curvature and the slope of this curve are important signatures of the transport regime.
 * Program		Transport_Regime.java
 * @author		Aliakbar Jafarpour <jafarpour.a.j@ieee.org>
 * Affiliation	Center for Molecular Biology at University of Heidelberg (ZMBH)
 * @version		1.0 
 * @param
 * @return
 */

import ij.*;
import ij.gui.*;
import ij.plugin.PlugIn;
import ij.process.*;
import pal.math.*;

public class Transport_Regime implements PlugIn {
	public void run(String arg) {
		new Initialize();
		Track track = new Track();
		ImagePlus imp = NewImage.createRGBImage("synthesized Tracks", track.nX, track.nY, 1, NewImage.FILL_WHITE);

		track.initializeXYT();
		track.setFirstPoint();
		track.setMinMaxStep();
		track.setSubsequentPoints();
		
		track.drawAllPoints(imp.getProcessor());
		imp.show();

		int lagMax = 20;
		Diffusion diff = new Diffusion(track.x, track.y, track.t, lagMax);
		diff.setCorrFunc();
		diff.plotCorr().show();
	}
}

class Initialize {
	public Initialize() {
		IJ.run("Close All");
	}
}

class Track {
	int nPoints;
	int nX;
	int nY;

	int[] x;
	int[] y;
	int[] t;

	int xDiameter;
	int yDiameter;
	int xDiameterHalf;
	int yDiameterHalf;

	int xMin;
	int xMax;
	int dx;

	int yMin;
	int yMax;
	int dy;

	public int clipValue(int x, int xMin, int xMax) {
		return (int) Math.min(Math.max(x, xMin), xMax);		
	}

	public void drawAllPoints(ImageProcessor im) {
		int cntr, fraction;
		for (cntr = 0; cntr < nPoints; cntr++) {
			fraction = (int) (255 * cntr / (nPoints - 1));
			im.setColor((int) ((int) (fraction << 16) + 255 - fraction));
			im.fillOval(x[cntr] - xDiameterHalf, y[cntr] - yDiameterHalf,xDiameter, yDiameter);
		}
	}

	public void drawSinglePoint(ImageProcessor im, int fraction) {
		im.setColor((int) ((int) (fraction << 16) + 255 - fraction));
		im.fillOval(x[0] - xDiameterHalf, y[0] - yDiameterHalf,xDiameter, yDiameter);
	}

	public void setSubsequentPoints() {
		/*
		while (x.length == 0) {
			IJ.log("zero-length detected; waiting ...");
		}
		*/
		//Random r = new Random();
		MersenneTwisterFast r = new MersenneTwisterFast();
		int cntr;
		for (cntr = 1; cntr < nPoints; cntr++) {
			x[cntr] = clipValue(x[cntr - 1] + (int)(dx * (r.nextFloat() - 0.5)), xMin, xMax);
			y[cntr] = clipValue(y[cntr - 1] + (int)(dy * (r.nextFloat() - 0.5)), yMin, yMax);
			t[cntr] = cntr;
		}
	}

	public void setFirstPoint() {
		x[0] = (int) (nX / 2);
		y[0] = x[0];
		t[0] = 0;
	}

	public void setMinMaxStep() {
		xMin = 0;
		xMax = nX - 1;
		dx = Math.max((int) 1, (int) (nX * 0.04));
	
		yMin = xMin;
		yMax = xMax;
		dy = dx;
	}
	
	public Track() {
		setNXYTDefault();
		setDiametersDefault();
	}

	public Track(int np, int nx, int ny) {
		this.setNXYT(np, nx, ny);
		this.setDiametersDefault();
	}

	public Track(int np, int nx, int ny, int d) {
		this.setNXYT(np, nx, ny);
		this.setDiameters(d);
	}

	public void initializeXYT() {
		x = new int[nPoints];
		y = new int[nPoints];
		t = new int[nPoints];
	}

	public void setDiameters(int d) {
		xDiameter = d;
		yDiameter = xDiameter;
		xDiameterHalf = (int) (xDiameter / 2);
		yDiameterHalf = (int) (yDiameter / 2);
	}

	private void setDiametersDefault() {
		xDiameter = 10;
		yDiameter = xDiameter;
		xDiameterHalf = (int) (xDiameter / 2);
		yDiameterHalf = (int) (yDiameter / 2);
	}

	public void setNXYT(int np, int nx, int ny) {
		nPoints = np;
		nX = nx;
		nY = ny;
	}
	
	private void setNXYTDefault() {
		nPoints = (int) 100;
		nX = (int) 500;
		nY = (int) nX;
	}
}

class Diffusion {
	int nMax;
	int N;
	int lagMax;

	int[] x;
	int[] y;
	int[] t;
	
	float[] corrFunction;
	float[] lagVariable;

	public Diffusion (int[] x_, int[] y_, int[] t_, int nMax_) {
		N = x_.length;
		t = t_;
		setNMax(nMax_);
		initializeParams(x_, y_);
	}
	
	public Diffusion (int[] x_, int[] y_, int[] t_) {
		N = x_.length;
		t = t_;
		setNMaxDefault();
		initializeParams(x_, y_);
	}
	
	public Diffusion (int[] x_, int[] y_) {
		N = x_.length;
		t = new int[N];
		int cntr;
		for (cntr = 0; cntr < N; cntr++) {
			t[cntr] = cntr;
		}
		setNMaxDefault();
		initializeParams(x_, y_);
	}

	private void initializeParams(int[] x_, int[] y_) {
		x = x_;
		y = y_;
		lagMax = t[N - 1] - t[0];
		nMax = Math.min(nMax , lagMax);
		corrFunction = new float[nMax];
		lagVariable = new float [nMax];
	}

	private void setNMaxDefault() {
		nMax = 5;
	}

	private void setNMax(int m) {
		nMax = m;
	}

	public void setCorrFunc() {
		int lagCntr;
		float dummy_1;
		int dummy_2;
		int cntr;
		for (lagCntr = 1; lagCntr <= nMax; lagCntr++) {
			lagVariable[lagCntr - 1] = (float) lagCntr;
			dummy_1 = (float) 0;
			dummy_2 = 0;
			for (cntr = 0; cntr < (N - lagCntr); cntr++) {
				if ( (t[cntr + lagCntr] - t[cntr] ) == lagCntr) {
					dummy_1 += powerX(x[cntr + lagCntr]-x[cntr], 2) + powerX(y[cntr + lagCntr]-y[cntr], 2) ;
					dummy_2++;
				}
			}
			corrFunction[lagCntr - 1] = (float) dummy_1 / (float) dummy_2;
		}
	}
	
	private float powerX(int x, int n) {
		float x_ = (float) x;
		float y = (float) 1;
		int cntr;
		for (cntr = 0; cntr < n; cntr++) {
			y *= x_;
		}
		return y;
	}

	public Plot plotCorr() {
		Plot plt = new Plot("Correlation analysis of the track (diffusion regime estimation)", "Lag Time", "Mean Square Distance", lagVariable, corrFunction);
		return plt;
	}
}

