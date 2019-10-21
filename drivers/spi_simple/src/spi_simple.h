/*############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
############################################################################*/

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

//*******************************************************************************
// Includes
//*******************************************************************************
#include <stdint.h>
#include <stdbool.h>

//*******************************************************************************
// Definitions
//*******************************************************************************
// Return codes
typedef enum SpiSimple_ErrCode
{
	SpiSimple_Success = 0,
	SpiSimple_TxFifoFull = -1,
	SpiSimple_RxFifoFull = -2,
	SpiSimple_RxFifoNotEmpty = -3,
	SpiSimple_RxFifoEmpty = -4
} SpiSimple_ErrCode;

// Register
#define SPI_SIMPLE_REG_DATA					0x00
#define SPI_SIMPLE_REG_STATUS				0x04
#define SPI_SIMPLE_REG_RX_LEVEL				0x08
#define SPI_SIMPLE_REG_TX_LEVEL				0x0C
#define SPI_SIMPLE_REG_SLAVE_NR				0x10
#define SPI_SIMPLE_REG_STORE_RX				0x14
#define SPI_SIMPLE_REG_TX_ALM_EMPTY_LVL		0x18
#define SPI_SIMPLE_REG_RX_ALM_FULL_LVL		0x1C
#define SPI_SIMPLE_REG_IRQ_VEC				0x20
#define SPI_SIMPLE_REG_IRQ_ENA				0x24

// Status Register Bitmasks
#define SPI_SIMPLE_STATUS_TX_EMPTY 			(1 << 0)
#define SPI_SIMPLE_STATUS_TX_FULL		 	(1 << 1)
#define SPI_SIMPLE_STATUS_TX_ALM_EMPTY 		(1 << 2)
#define SPI_SIMPLE_STATUS_RX_EMPTY 			(1 << 3)
#define SPI_SIMPLE_STATUS_RX_FULL	 		(1 << 4)
#define SPI_SIMPLE_STATUS_RX_ALM_FULL	 	(1 << 5)
#define SPI_SIMPLE_STATUS_BUSY				(1 << 6)

// IRQ vector/enable bitmasks
#define SPI_SIMPLE_IRQ_TX_EMPTY 			(1 << 0)
#define SPI_SIMPLE_IRQ_TX_ALM_EMPTY		 	(1 << 1)
#define SPI_SIMPLE_IRQ_TF_DONE 				(1 << 2)
#define SPI_SIMPLE_IRQ_RX_FULL 				(1 << 3)
#define SPI_SIMPLE_IRQ_RX_ALM_FULL	 		(1 << 4)


//*******************************************************************************
// Access Functions
//*******************************************************************************
/**
 * Blocking TX only transaction (ignore RX data)
 *
 * @param baseAddr		Base address of the IP component to access
 * @param slave			Index of the slave to access
 * @param txData		Data to transmit
 */
SpiSimple_ErrCode SpiSimple_TxBlocking(const uint32_t baseAddr, const uint8_t slave, const uint32_t txData);

/**
 * Blocking RX/TX transaction (transmit data and read RX data)
 *
 * @param baseAddr		Base address of the IP component to access
 * @param slave			Index of the slave to access
 * @param txData		Data to transmit
 * @param rxData_p		Received data output
 * @return				Return Code (zero on success)
 */
SpiSimple_ErrCode SpiSimple_RxTxBlocking(const uint32_t baseAddr, const uint8_t slave, const uint32_t txData, uint32_t* rxData_p);

/**
 * Non-Blocking TX only transaction (ignore RX data). There must be space in the TX FIFO
 * for this operation to succeed.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param slave			Index of the slave to access
 * @param txData		Data to transmit
 * @return				Return Code (zero on success)
 */
SpiSimple_ErrCode SpiSimple_TxNonBlocking(const uint32_t baseAddr, const uint8_t slave, const uint32_t txData);

/**
 * Non-Blocking RX/TX transaction (ignore RX data). The RX data is stored in the RX FIFO and can be obtained
 * by using SpiSimple_GetRxData() after the transfer completed.
 * There must be some free space in the TX FIFO for this operation to succeed. However, the RX FIFO can overflow because
 * the number of outstanding RX transactions is not known. preventing RX overflows must be done by the user.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param slave			Index of the slave to access
 * @param txData		Data to transmit
 * @return				Return Code (zero on success)
 */
SpiSimple_ErrCode SpiSimple_RxTxNonBlocking(const uint32_t baseAddr, const uint8_t slave, const uint32_t txData);

/**
 * Read one entry from the RX data FIFO. RX data is read in the same order as the transactions were started.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param rxData_p		Received data output
 * @return				Return Code (zero on success)
 */
SpiSimple_ErrCode SpiSimple_GetRxData(const uint32_t baseAddr, uint32_t* rxData_p);

//*******************************************************************************
// Status Functions
//*******************************************************************************
/**
 * Check if the TX FIFO is full
 *
 * @param baseAddr		Base address of the IP component to access
 * @return				true if the FIFO is full
 */
bool SpiSimple_IsTxFifoFull(const uint32_t baseAddr);

/**
 * Check if the TX FIFO is empty
 *
 * @param baseAddr		Base address of the IP component to access
 * @return				true if the FIFO is empty
 */
bool SpiSimple_IsTxFifoEmtpy(const uint32_t baseAddr);

/**
 * Check if the RX FIFO is empty
 *
 * @param baseAddr		Base address of the IP component to access
 * @return				true if the FIFO is empty
 */
bool SpiSimple_IsRxFifoEmpty(const uint32_t baseAddr);

/**
 * Check if the RX FIFO is full
 *
 * @param baseAddr		Base address of the IP component to access
 * @return				true if the FIFO is full
 */
bool SpiSimple_IsRxFifoFull(const uint32_t baseAddr);

/**
 * Check if an SPI transaction is currently ongoing.
 *
 * @param baseAddr		Base address of the IP component to access
 * @return				true if one or more transactions are ongoing
 */
bool SpiSimple_IsBusy(const uint32_t baseAddr);

/**
 * Get the current RX FIFO level
 *
 * @param baseAddr		Base address of the IP component to access
 * @return				Number of entries in the RX FIFO
 */
uint32_t SpiSimple_GetRxFifoLevel(const uint32_t baseAddr);

/**
 * Get the current TX FIFO level
 *
 * @param baseAddr		Base address of the IP component to access
 * @return				Number of entries in the TX FIFO
 */
uint32_t SpiSimple_GetTxFifoLevel(const uint32_t baseAddr);

/**
 * Read the IRQ vector. See constant definitions for the bit-masks of the individual flags.
 *
 * @param baseAddr		Base address of the IP component to access
 * @return				IRQ vector
 */
uint32_t SpiSimple_GetIrqVec(const uint32_t baseAddr);

/**
 * Read the status register. See constant definitions for the bit-masks of the individual flags.
 *
 * @param baseAddr		Base address of the IP component to access
 * @return				Status register content
 */
uint32_t SpiSimple_GetStatusReg(const uint32_t baseAddr);

//*******************************************************************************
// Configuration Functions
//*******************************************************************************
/**
 * Clear bits in the IRQ vector.
 *
 * Usually all vector bits that are recognized by the ISR are cleared. Example below:
 * vec = SpiSimple_GetIrqVec(ip_addr);
 * SpiSimple_ClrIrqVec(ip_addr, vec);
 *
 * @param baseAddr		Base address of the IP component to access
 * @param mask			Bits to clear. See constant definitions for the bit-masks of the individual flags. 
 */
void SpiSimple_ClrIrqVec(const uint32_t baseAddr, const uint32_t mask);

/**
 * Enable individual bits to cause an IRQ. Disabled bits are still latched for the vector but will not
 * produce and interrupt. On reset, all bits are disabled.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param mask			IRQ enable for individual flags. See constant definitions for the bit-masks of the individual flags. 
 */
void SpiSimple_SetIrqEna(const uint32_t baseAddr, const uint32_t mask);

/**
 * Set the threshold level for the TX FIFO almost empty condition.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param threshold		Threshold to generate an almost empty condition at
 */
void SpiSimple_SetTxAlmEmptyThreshold(const uint32_t baseAddr, const uint32_t threshold);

/**
 * Set the threshold level for the RX FIFO almost full condition.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param threshold		Threshold to generate an almost full condition at
 */
void SpiSimple_SetRxAlmFullThreshold(const uint32_t baseAddr, const uint32_t threshold);

#ifdef __cplusplus
}
#endif


