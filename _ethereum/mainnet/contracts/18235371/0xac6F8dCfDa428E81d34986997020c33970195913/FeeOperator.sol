// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IFeeManager.sol";
import "./Ownable.sol";

/**
 * @title FeeOperator
 */
abstract contract FeeOperator is Ownable {
    /*
     * @dev The address of the fee manager.
     */
    address public feeManager;

    /*
     * @dev Emitted when the fee manager is updated.
     * @param feeManager The address of the new fee manager.
     */
    event FeeManagerUpdated(address feeManager);

    /*
     * @dev Insufficient funds to complete the transaction and pay fees.
     */
    error InsufficientFees();

    /*
     * @dev Fees were unable to be transferred to the fee manager.
     */
    error FeeTransferFailed();

    /*
     * @dev Excess funds were unable to be refunded to the caller.
     */
    error RefundFailed();

    /**
     * @dev Function modifier to handle transaction fees for bridging and swapping.
     * @param bridgeFee The amount of native being transferred to the bridge protocol.
     * @param amountIn The amount of native or erc20 being transferred.
     * @param tokenIn The address of the token being transferred, zero address for native currency.
     * @param nativeOut The amount of unwrapped native being transferred.
     */
    modifier handleFees(uint256 bridgeFee, uint256 amountIn, address tokenIn, uint256 nativeOut) {
        if (feeManager != address(0)) {
            (uint256 fee, uint256 commission) = IFeeManager(feeManager).calculateFees(amountIn, tokenIn);

            uint256 boxFees = fee + commission;
            uint256 amountRequired =
                tokenIn == address(0) ? amountIn + nativeOut + bridgeFee + boxFees : nativeOut + bridgeFee + boxFees;

            if (msg.value < amountRequired) {
                revert InsufficientFees();
            }

            _transferFees(boxFees);
            _transferRefund(msg.value - amountRequired);
        }

        _;
    }

    /**
     * @dev Updates the address of the fee manager used for calculating and collecting fees.
     * @param _feeManager The address of the new fee manager.
     */
    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
        emit FeeManagerUpdated(_feeManager);
    }

    /**
     * @dev Internal function to transfer fees to the fee manager.
     * @param fees The amount of fees being transferred.
     */
    function _transferFees(uint256 fees) internal {
        (bool success,) = payable(feeManager).call{value: fees}("");
        if (!success) {
            revert FeeTransferFailed();
        }
    }

    /**
     * @dev Internal function to transfer excess funds to the caller.
     * @param refund The amount of funds to transfer.
     */
    function _transferRefund(uint256 refund) internal {
        if (refund > 0) {
            (bool success,) = payable(_msgSender()).call{value: refund}("");
            if (!success) {
                revert RefundFailed();
            }
        }
    }
}
