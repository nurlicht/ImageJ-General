// Author: Aliakbar Jafarpour (Gaussian spot synthesis by modification of the program Cross_Fader.java written by Michael Schmid)

import ij.*;
import ij.process.*;
import ij.plugin.filter.ExtendedPlugInFilter;
import ij.plugin.filter.PlugInFilterRunner;
import ij.gui.DialogListener;
import ij.gui.GenericDialog;
import java.awt.*;

public class Gaussian_Synth implements ExtendedPlugInFilter, DialogListener {
   private static int FLAGS = DOES_16 | KEEP_PREVIEW;

   private double percentage;
   private double percentageAmplitude;
   private double percentageX;
   private double percentageY;
   private ImagePlus imp;
   
   public int setup (String arg, ImagePlus imp) {
       return FLAGS;
   }

   public int showDialog (ImagePlus imp, String command, PlugInFilterRunner pfr) {
       int width;
       int height;

       if (imp.getNSlices() > 1) {
           IJ.error("A single image (not a stack) is expected.");
           return DONE;
       }
       if (imp.getNChannels() > 1) {
           IJ.error("A single-channel image is expected.");
           return DONE;
       }
       if (imp.getBitDepth() != 16) {
           IJ.error("A 16-bit image is expected.");
           return DONE;
       }

       this.imp = imp;
       width = imp.getWidth();
       height = imp.getHeight();
       GenericDialog gd = new GenericDialog(command+"...");
       gd.addSlider("Normalized Gaussian Width", 0, 100, 20.0);
       gd.addSlider("Gaussian Amplitude", 0, 100, 80.0);
       gd.addSlider("X of Center", 0, 100, 50.0);
       gd.addSlider("Y of Center", 0, 100, 50.0);
       gd.addPreviewCheckbox(pfr);
       gd.addDialogListener(this);
       gd.showDialog();           // user input (or reading from macro) happens here
       if (gd.wasCanceled())      // dialog cancelled?
           return DONE;
       return FLAGS;              // makes the user process the slice
   }

   public boolean dialogItemChanged (GenericDialog gd, AWTEvent e) {
       percentage = gd.getNextNumber();
       percentageAmplitude = gd.getNextNumber();
       percentageX = gd.getNextNumber();
       percentageY = gd.getNextNumber();
       return !gd.invalidNumber() && percentage>=0 && percentage <=100;
   }

   public void run (ImageProcessor ip) {
       synthGauss(ip);
   }

   private void synthGauss(ImageProcessor ip) {
       int xCntr;
       int yCntr;
       double pixelValue;
       double gWidth2;
       int width = ip.getWidth();
       int height = ip.getHeight();
       double xOffset = (percentageX / 50 - 0.5) * width;
       double yOffset = (percentageY / 50 - 0.5) * height;
       double Amplitude = 65535.0 * (percentageAmplitude / 100);
       
       gWidth2 = sq((width*(percentage/101.0/5.0)) + 1.0/101.0);
       for (yCntr = 0; yCntr < height; yCntr++) {
	       for (xCntr = 0; xCntr < width; xCntr++) {
	       	 pixelValue = Amplitude * 
	       	 			  Math.exp(- sq((double) xCntr - xOffset) / gWidth2 - sq((double) yCntr - yOffset) / gWidth2);
	       	 ip.putPixel(xCntr, yCntr, ip.get(xCntr, yCntr) +(int) pixelValue);
	       }
       }
       this.imp.setDefault16bitRange(0);
   }   

   private double sq(double x) {
   	 return x * x;
   }

   public void setNPasses (int nPasses) {}

}
