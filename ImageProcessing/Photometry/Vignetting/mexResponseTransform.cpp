/***************************************************************
 * Vignetting Correction Package
 *
 * Response Calculations
 *
 * C. Kirst, The Rockefeller University 2014
 *
 ***************************************************************/

#include "mex.h"

#include <vector>
using namespace std;

#include "MexCheck.h"
#include "MexUtils.h"
#include "Response.h"

/* Input Arguments */
#define IN_I                      prhs[0]
#define IN_X                      prhs[1]
#define IN_Y                      prhs[2]
#define IN_X_SIZE                 prhs[3]
#define IN_Y_SIZE                 prhs[4]
#define IN_EXPOSURE               prhs[5]
#define IN_VIGNETTING_CENTER      prhs[6]
#define IN_VIGNETTING_PARAM       prhs[7]
#define IN_RESPONSE_TYPE          prhs[8]
#define IN_RESPONSE_PARAM         prhs[9]
#define IN_INVERSE                prhs[10]

/* Output Arguments */
#define OUT_I                     plhs[0]

#define IJ(i,j) ((j)*m + (i))

#include <iostream>

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )      
{ 
   /* Check for proper number of arguments */
   if (nrhs != 11) {
      mexErrMsgTxt("ResponseTransform: 8 input arguments required: intensity, x, y, exposure, vig_center, vig_param, response_type, response_param, inverse lag.");
   } else if (nlhs !=1 && nlhs !=2 && nlhs !=4) {
      mexErrMsgTxt("ResponseTransform: 1 output argument required: transformed intensity.");
   }

   /* Check Size of Input: Vector or Image */
   bool image_input = false;
   
   mexCheckArg(IN_I, (mwSize) 2, MexCheckError("ResponseTransform", "x position"));
   const mwSize* size = mxGetDimensions(IN_I);

   double xsize, ysize;
   if ((size[0] == 1) || (size[1] == 1)) {// vector
      // check sizes
      image_input = false;
      
      mexCheckArg(IN_X, (mwSize) 2, size, MexCheckError("ResponseTransform", "x position"));
      mexCheckArg(IN_Y, (mwSize) 2, size, MexCheckError("ResponseTransform", "y position"));
      
      xsize = mxGetScalar(IN_X_SIZE);
      ysize = mxGetScalar(IN_Y_SIZE);
      
   } else {
      image_input = true;
      
      xsize = mxGetM(IN_I);
      ysize = mxGetN(IN_I);
   }
   
   /* Check Exposure */ 
   mexCheckArg(IN_EXPOSURE, (mwSize) 1, (mwSize) 1, MexCheckError("ResponseTransform", "exposure"));

   /* Check Vignetting */
   mexCheckArg(IN_VIGNETTING_CENTER, (mwSize) 1, (mwSize) 2, MexCheckError("ResponseTransform", "vignetting center"));
   mexCheckArg(IN_VIGNETTING_PARAM,  (mwSize) 1, (mwSize) 4, MexCheckError("ResponseTransform", "vignetting parameter"));
   
   /* Check Response */
   mexCheckArg(IN_RESPONSE_TYPE,  (mwSize) 1, (mwSize) 1, MexCheckError("ResponseTransform", "response type"));
   mexCheckArg(IN_RESPONSE_PARAM, (mwSize) 1, (mwSize) 6, MexCheckError("ResponseTransform", "response parameter"));
  
   /* Response Direction */ 
   mexCheckArg(IN_INVERSE, (mwSize) 1, (mwSize) 1, MexCheckError("ResponseTransform", "response direction"));

   
   /* Define parameter */
   double exposure = mxGetScalar(IN_EXPOSURE);
  
   double vig_center_x = mexUtilsArrayElement(IN_VIGNETTING_CENTER, 0);
   double vig_center_y = mexUtilsArrayElement(IN_VIGNETTING_CENTER, 1);    
   std::vector<double> vig_param = mexUtilsArrayToVector(IN_VIGNETTING_PARAM);

   int resp_type = int(mxGetScalar(IN_RESPONSE_TYPE));
   std::vector<double> resp_param = mexUtilsArrayToVector(IN_RESPONSE_PARAM);
   
   int inv = int(mxGetScalar(IN_INVERSE));
   
   /* Output */
   //OUT_I = mxCreateNumericArray(ndim, size, mxDOUBLE_CLASS, mxREAL); 
   
   
   /* Create Response Object */
   Photometry::Response response(xsize, ysize, Photometry::Response::ResponseType(resp_type));
   
   response.exposure = exposure;

   response.vignettingCenterX = vig_center_x;
   response.vignettingCenterY = vig_center_y;
   response.vignettingParameter = vig_param;
   
   response.initEMoRLUT(resp_param);

   /* Create output image */
   OUT_I = mxCreateNumericArray(2, size, mxDOUBLE_CLASS, mxREAL);

   /* Debug */
   std::cout << exposre
   
   if (image_input) {
      
      double * ini = mxGetPr(IN_I);
      double * outi = mxGetPr(OUT_I);

      if (inv) {
         for (int i = 0; i < xsize; i++) {
            for (int j = 0; j < ysize; j++) {
               *outi = response.applyInverse(*ini, i, j);
               ini++; outi++;
            }
         }
      } else {
         for (int i = 0; i < xsize; i++) {
            for (int j = 0; j < ysize; j++) {
               *outi = response.apply(*ini, i, j);
               ini++; outi++;
            }
         }
      }
   } else { // vectors of intensities, x, and ys
      mwSize n = mxGetNumberOfElements(IN_I);
      if (inv) {
         response.applyInverseVector(n, mxGetPr(IN_I), mxGetPr(IN_X), mxGetPr(IN_Y), mxGetPr(OUT_I));
      } else {
         response.applyVector(n, mxGetPr(IN_I), mxGetPr(IN_X), mxGetPr(IN_Y), mxGetPr(OUT_I));
      }
   }
   
   return;
}






