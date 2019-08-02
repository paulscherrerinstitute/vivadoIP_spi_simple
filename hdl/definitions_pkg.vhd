------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	use work.psi_common_math_pkg.all;
	
------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package definitions_pkg is

	constant Irq_TxEmpty_c		: natural 	:= 0;		-- tested
	constant Irq_TxAlmEmpty_c	: natural	:= 1;		-- tested
	constant Irq_TfDone_c		: natural	:= 2;		-- tested
	constant Irq_RxFull_c		: natural	:= 3;		
	constant Irq_RxAlmFull_c	: natural	:= 4;		-- tested	
	constant IrqSize_c			: natural 	:= IRq_RxAlmFull_c+1;
	subtype Irq_t is std_logic_vector(IrqSize_c-1 downto 0);
	
	-- Addresses 
	constant RegIdx_Data_c				: natural 	:= 0;	-- tested

	constant RegIdx_Status_c			: natural	:= 1;
	constant BitIdx_Status_TxEmpty_c	: natural 	:= 0;	-- tested
	constant BitIdx_Status_TxFull_c		: natural	:= 1;
	constant BitIDx_Status_TxAlmEmpty_c	: natural	:= 2;	
	constant BitIdx_Status_RxEmpty_c	: natural	:= 3;	
	constant BitIdx_Status_RxFull_c		: natural	:= 4;	-- tested
	constant BitIdx_Status_RxAlmFull_c	: natural	:= 5;	
	constant BitIdx_Status_Busy_c		: natural	:= 6;	-- tested
	constant StatusSize_c				: natural	:= BitIdx_Status_Busy_c+1;
	subtype Status_t is std_logic_vector(StatusSize_c-1 downto 0);
	
	constant RegIdx_RxLevel_c			: natural	:= 2;	-- tested
	constant RegIdx_TxLevel_c			: natural	:= 3;	-- tested
	constant RegIdx_SlaveNr_c			: natural  	:= 4;	-- tested
	constant RegIdx_StoreRx_c			: natural	:= 5;	-- tested
	constant RegIdx_TxAlmEmptyLevel_c	: natural	:= 6;	-- tested
	constant RegIdx_RxAlmFullLevel_c	: natural	:= 7;	-- tested
	constant RegIdx_IrqVec_c			: natural	:= 8;	-- tested
	constant RegIdx_IrqEna_c			: natural	:= 9;	-- tested
	
	constant RegCount_c					: natural	:= RegIdx_IrqEna_c+1;

end package;






