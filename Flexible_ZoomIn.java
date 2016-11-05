// Program: Flexible_ZoomIn.java
// Version: 1
// Programming language: Java (ImageJ Plugin)
// Description: Replaces the exhaustive iterations of {zoom-in, zoom-out} with auxilary zoomed-in image(s). By simply clicking at arbitrary points (ROI centers in the original image), a zoomed-in version of the ROI will show up as a different image. Such new ROI images can be closed automatically upon a new zoom-in action.

// Programmer: Aliakbar Jafarpour
// Affiliation: Center for Molecular Biology at University of Heidelberg (ZMBH)
// Email: jafarpour.a.j@ieee.org

import ij.*;
import ij.io.*;
import ij.gui.*;
import ij.process.*;
import ij.IJ.*;
import ij.plugin.PlugIn;
import java.awt.event.*;
import ij.gui.Roi.*;

public class Flexible_ZoomIn extends MouseAdapter implements PlugIn {
	ImagePlus imp;
	ImagePlus impROI;
	AllParams ap;
	
	public void run(String arg) {
		new Initialize();
		ap = new AllParams();
		loadOriginalImage();
	}

	public void loadOriginalImage() {
		String imagePath = new OpenDialog("Please select an image.").getPath();
		Opener opener = new Opener();
		imp = opener.openImage(imagePath);
		imp.show();
		imp.getCanvas().addMouseListener(this);
		new WaitForUserDialog("Click to specify ROI Centers; Shift+Click for the last one").show();
		IJ.run(imp, "Select None", "");
		IJ.wait(1);
	}

    public void mouseClicked(MouseEvent evt){
        processClick(evt.getX(), evt.getY(), evt.getModifiers());
    }

    public void processClick(int x, int y, int flags) {
		if (ap.getMouseResponseFlag() > 0) {
			int D = ap.getSelectionWidthParam();
			int zoomPercent = ap.getZoomPercentParam();

			int DH = (int) (D / 2);
			int D_ = (int) (D * zoomPercent / 100);
			
			IJ.run(imp, "Select None", "");
			imp.setRoi(new Roi(x - DH, y - DH, D, D));
			if ((ap.getClickCounter() > 1) && ap.getClosePreviousROIsFlag()) {
				impROI.changes = false;
				impROI.close();
			}
			impROI = imp.duplicate();
			impROI.setTitle("ROI Image #" + d2s(ap.getClickCounter()));
			IJ.run(impROI, "Size...", "width=" + d2s(D_) + " height=" + d2s(D_) + " constrain average interpolation=Bilinear");			
			impROI.show();
			
			ap.setMouseResponseFlag((flags & 1) == 0);
			ap.incClickCounter();
		}
    }

    private String d2s(int x) {
    	return Integer.toString(x);
    }

    private int s2d(String s) {
    	return Integer.parseInt(s);
    }
}


class Initialize {
	public Initialize() {
		IJ.run("Close All");
		IJ.setTool("rectangle");
	}
}

class AllParams {
	int N;
	String[] allParams;

	public AllParams() {
		setNParams(5);
		setAllParamsDimension();
		
		allParams[0] = "" + d2s(1);				// closePreviousROIsFlag
		allParams[1] = "" + d2s(40);			// selectionWidth
		allParams[2] = "" + d2s(500);			// zoomPercent
		allParams[3] = "" + d2s(1);				// mouseResponseFlag
		allParams[4] = "" + d2s(1);				// clickCounter
	}

	public void setNParams(int n) {
		N = n;
	}

	public void setAllParamsDimension() {
		allParams = new String[N];
	}

	public boolean getClosePreviousROIsFlag() {
		return (s2d(allParams[0]) > 0);
	}

	public int getSelectionWidthParam() {
		return s2d(allParams[1]);
	}

	public int getZoomPercentParam() {
		return s2d(allParams[2]);
	}

	public int getMouseResponseFlag() {
		return s2d(allParams[3]);
	}

	public void setMouseResponseFlag(boolean b) {
		int newValue = (b) ? 1 : 0;
		allParams[3] = d2s(newValue);
	}

	public int getClickCounter() {
		return s2d(allParams[4]);
	}

	public void setClickCounter(int c) {
		allParams[4] = d2s(c);
	}

	public void incClickCounter() {
		allParams[4] = d2s(1 + s2d(allParams[4]));
	}

    private int s2d(String s) {
    	return Integer.parseInt(s);
    }

    private String d2s(int x) {
    	return Integer.toString(x);
    }
}
