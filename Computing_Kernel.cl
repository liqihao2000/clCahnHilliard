#include "Settings_and_Parameters.h"

////////////////////////////////////////////////////////////////////////////////
// Laplacation operator definition, to calculate diffusive fluxes
////////////////////////////////////////////////////////////////////////////////

float LaplacianXY(__global float* C, int row, int column)
{
	float retval;
	float dx = dX;
	float dy = dY;
	
	int current = row * Grid_Width + column;
	int left    = row * Grid_Width + column-1;
	int right   = row * Grid_Width + column+1;
	int top     = (row-1) * Grid_Width + column;
	int bottom  = (row+1) * Grid_Width + column;
	
	retval = ( C[left] + C[right]  - 2 * C[current] )/dx/dx +
    ( C[top]  + C[bottom] - 2 * C[current] )/dy/dy;
    
	return retval;
}

////////////////////////////////////////////////////////////////////////////////
// Simulation kernel
////////////////////////////////////////////////////////////////////////////////

__kernel void
CahnHilliard_Kernel_Phase1 (__global float* C, __global float* Int)
{
    
    float gamma = Gamma;
    
    size_t current = get_global_id(0);
	int row		= floor((float)current/(float)Grid_Width);
	int column	= current%Grid_Width; 
    
    if(row > 0 && row < Grid_Height-1 && column > 0 && column < Grid_Width-1)
	{
        Int[current]  = C[current]*C[current]*C[current] - C[current] - gamma*LaplacianXY(C, row, column);
        //Int[current]  = powf(C[current],3) - C[current] - gamma*LaplacianXY(C, row, column);
	}
    else
	{
        Int[current]  = 0;
	}
    
    barrier(CLK_GLOBAL_MEM_FENCE);
    
}

__kernel void
CahnHilliard_Kernel_Phase2 (__global float* C, __global float* Int)
{
    float d = D;
    float dC;
    
    size_t current = get_global_id(0);
	
	int row		= floor((float)current/(float)Grid_Width);
	int column	= current%Grid_Width;  //
    
    if(row > 1 && row < Grid_Height-2 && column > 1 && column < Grid_Width-2)
	{
        //Now calculating terms for the P Matrix
        dC = d*LaplacianXY(Int, row, column);
        C[current]=C[current]+(dC)*dT;
    }
    
    // barrier(CLK_GLOBAL_MEM_FENCE);
    
    // HANDLE Boundaries
    
    if(row<=1)
	{
        C[current]=C[(row + Grid_Height - 4) * Grid_Width + column];
	}
    else if(row>=Grid_Height-2)
	{
        C[current]=C[(row - Grid_Height + 4) * Grid_Width + column];
	}
    else if(column<=1)
	{
        C[current]=C[row * Grid_Width + column + Grid_Width - 4];
	}
    else if(column>=Grid_Width-2)
	{
        C[current]=C[row * Grid_Width + column - Grid_Width + 4];
	}
    
    // barrier(CLK_GLOBAL_MEM_FENCE);
    
} // End Mussels_PDE_Kernel
