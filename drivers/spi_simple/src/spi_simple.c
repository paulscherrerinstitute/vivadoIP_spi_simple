/*############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
############################################################################*/

#include "spi_simple.h"
#include <xil_io.h>

//*******************************************************************************
// Helper Functions
//*******************************************************************************
void SetSlaveNr(const uint32_t baseAddr, const uint8_t slave)
{
	Xil_Out32(baseAddr + SPI_SIMPLE_REG_SLAVE_NR, slave);
}

void SetStoreRx(const uint32_t baseAddr, const bool storeRx)
{
	uint32_t val = 0;
	if (storeRx) {
		val = 1;
	}
	Xil_Out32(baseAddr + SPI_SIMPLE_REG_STORE_RX, val);	
}

void WaitNotBusy(const uint32_t baseAddr)
{
	while (SpiSimple_IsBusy(baseAddr)){}
}


//*******************************************************************************
// Access Functions
//*******************************************************************************

SpiSimple_ErrCode SpiSimple_TxBlocking(const uint32_t baseAddr, const uint8_t slave, const uint32_t txData)
{	
	//variable definition
	SpiSimple_ErrCode retCode;
	
	//configure
	SetSlaveNr(baseAddr, slave);
	SetStoreRx(baseAddr, false);

	//wait for space in TX fifo if it is full
	while (SpiSimple_IsTxFifoFull(baseAddr)){}	
	
	//transfer
	retCode = SpiSimple_TxNonBlocking(baseAddr, slave, txData);
	if (SpiSimple_Success != retCode) 
	{
		return retCode;
	} 
	WaitNotBusy(baseAddr);
	return SpiSimple_Success;
}

SpiSimple_ErrCode SpiSimple_RxTxBlocking(const uint32_t baseAddr, const uint8_t slave, const uint32_t txData, uint32_t* rxData_p)
{
	//variable definition
	SpiSimple_ErrCode retCode;
	
	//wait until core is idle to ensure state does not change because of ongoing transfers
	WaitNotBusy(baseAddr);
	
	//checks 
	if (!SpiSimple_IsRxFifoEmpty(baseAddr)) 
	{
		return SpiSimple_RxFifoNotEmpty; // if RX FIFO is not empty, the RX value cannot be read from the FIFO
	} 
	
	//configure
	SetSlaveNr(baseAddr, slave);
	SetStoreRx(baseAddr, true);	
	
	//transfer
	retCode = SpiSimple_RxTxNonBlocking(baseAddr, slave, txData);
	if (SpiSimple_Success != retCode) 
	{
		return retCode;
	} 
	WaitNotBusy(baseAddr);	
	retCode = SpiSimple_GetRxData(baseAddr, rxData_p);
	if (SpiSimple_Success != retCode) 
	{
		return retCode;
	} 
	return SpiSimple_Success;
}

SpiSimple_ErrCode SpiSimple_TxNonBlocking(const uint32_t baseAddr, const uint8_t slave, const uint32_t txData)
{
	//checks 
	if (SpiSimple_IsTxFifoFull(baseAddr)) 
	{
		return SpiSimple_TxFifoFull; // if TX FIFO is full, the access cannot be executed
	} 	
	
	//configure
	SetSlaveNr(baseAddr, slave);
	SetStoreRx(baseAddr, false);	

	//start transfer	
	Xil_Out32(baseAddr + SPI_SIMPLE_REG_DATA, txData);
	return SpiSimple_Success;
}

SpiSimple_ErrCode SpiSimple_RxTxNonBlocking(const uint32_t baseAddr, const uint8_t slave, const uint32_t txData)
{
	//checks 
	if (SpiSimple_IsTxFifoFull(baseAddr)) 
	{
		return SpiSimple_TxFifoFull; // if TX FIFO is full, the access cannot be executed
	} 	
	if (SpiSimple_IsRxFifoFull(baseAddr)) 
	{
		return SpiSimple_RxFifoFull; // if TX FIFO is full, the access cannot be executed
	}	
	
	//configure
	SetSlaveNr(baseAddr, slave);
	SetStoreRx(baseAddr, true);	

	//start transfer	
	Xil_Out32(baseAddr + SPI_SIMPLE_REG_DATA, txData);
	return SpiSimple_Success;
}

SpiSimple_ErrCode SpiSimple_GetRxData(const uint32_t baseAddr, uint32_t* rxData_p)
{
	//checks
	if (SpiSimple_IsRxFifoEmpty(baseAddr))
	{
		return SpiSimple_RxFifoEmpty;
	}
	
	//execute
	*rxData_p = Xil_In32(baseAddr + SPI_SIMPLE_REG_DATA);
	return SpiSimple_Success;
	
}

//*******************************************************************************
// Status Functions
//*******************************************************************************
bool SpiSimple_IsTxFifoFull(const uint32_t baseAddr)
{
	return (SpiSimple_GetStatusReg(baseAddr) & SPI_SIMPLE_STATUS_TX_FULL);
}

bool SpiSimple_IsTxFifoEmtpy(const uint32_t baseAddr)
{
	return (SpiSimple_GetStatusReg(baseAddr) & SPI_SIMPLE_STATUS_TX_EMPTY);
}

bool SpiSimple_IsRxFifoEmpty(const uint32_t baseAddr)
{
	return (SpiSimple_GetStatusReg(baseAddr) & SPI_SIMPLE_STATUS_RX_EMPTY);
}

bool SpiSimple_IsRxFifoFull(const uint32_t baseAddr)
{
	return (SpiSimple_GetStatusReg(baseAddr) & SPI_SIMPLE_STATUS_RX_FULL);
}

bool SpiSimple_IsBusy(const uint32_t baseAddr)
{
	return (SpiSimple_GetStatusReg(baseAddr) & SPI_SIMPLE_STATUS_BUSY);
}

uint32_t SpiSimple_GetRxFifoLevel(const uint32_t baseAddr)
{
	return Xil_In32(baseAddr + SPI_SIMPLE_REG_RX_LEVEL);
}

uint32_t SpiSimple_GetTxFifoLevel(const uint32_t baseAddr)
{
	return Xil_In32(baseAddr + SPI_SIMPLE_REG_TX_LEVEL);
}

uint32_t SpiSimple_GetIrqVec(const uint32_t baseAddr)
{
	return Xil_In32(baseAddr + SPI_SIMPLE_REG_IRQ_VEC);
}

uint32_t SpiSimple_GetStatusReg(const uint32_t baseAddr)
{
	return Xil_In32(baseAddr + SPI_SIMPLE_REG_STATUS);
}

//*******************************************************************************
// Configuration Functions
//*******************************************************************************
void SpiSimple_ClrIrqVec(const uint32_t baseAddr, const uint32_t mask)
{
	Xil_Out32(baseAddr + SPI_SIMPLE_REG_IRQ_VEC, mask);
}

void SpiSimple_SetIrqEna(const uint32_t baseAddr, const uint32_t mask)
{
	Xil_Out32(baseAddr + SPI_SIMPLE_REG_IRQ_ENA, mask);
}

void SpiSimple_SetTxAlmEmptyThreshold(const uint32_t baseAddr, const uint32_t threshold)
{
	Xil_Out32(baseAddr + SPI_SIMPLE_REG_TX_ALM_EMPTY_LVL, threshold);
}

void SpiSimple_SetRxAlmFullThreshold(const uint32_t baseAddr, const uint32_t threshold)
{
	Xil_Out32(baseAddr + SPI_SIMPLE_REG_RX_ALM_FULL_LVL, threshold);
}

