// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import "./SafeTransferLib.sol";

/**
 * @title Motivator V2
 * @author Federation - https://x.com/FederationWTF
 */
abstract contract MotivatorV2 {
    struct MotivatorConfig {
        /// Base gas to refund
        uint256 refundBaseGas;
        /// Max priority fee used for refunds
        uint256 maxRefundPriorityFee;
        /// Max gas units that will be refunded
        uint256 maxRefundGasUsed;
        /// Max base fee
        uint256 maxRefundBaseFee;
        /// The tip amount
        uint256 tipAmount;
    }

    /// The config for the contract
    MotivatorConfig public motivatorConfig;

    /**
     * @notice A gas refund has been issued
     * @param to The address of the recipient
     * @param amount The amount refunded
    */
    event Refund(address indexed to, uint256 amount);

    /**
     * @notice A withdraw has been made
     * @param amount The amount withdrawn
     * @param to The address of the recipient
    */
    event Withdraw(uint256 amount, address to);

    /**
     * @notice A tip has been issued
     * @param to The address of the recipient
     * @param amount The amount tipped
    */
    event Tip(address indexed to, uint256 amount);

    /// Refunds gas to the caller if there are funds available
    modifier refundGas {
        uint256 gasAtStart = gasleft();

        _;
        
        if (address(this).balance > 0) {
            uint256 basefee = _min(block.basefee, motivatorConfig.maxRefundBaseFee);
            uint256 gasPrice = _min(tx.gasprice, basefee + motivatorConfig.maxRefundPriorityFee);
            uint256 gasUsed = _min(gasAtStart - gasleft() + motivatorConfig.refundBaseGas, motivatorConfig.maxRefundGasUsed);
            
            uint256 refund = _min(gasPrice * gasUsed, address(this).balance);

            SafeTransferLib.forceSafeTransferETH(tx.origin, refund);
            emit Refund(tx.origin, refund);
        }
    }

    /**
     * @notice Withdraws funds stored in the contract
     * @param _amount The amount to withdraw
     * @param _to The address to withdraw to
     * @return The new balance
    */
    function _withdraw(uint256 _amount, address _to) internal returns (uint256) {
        SafeTransferLib.forceSafeTransferETH(_to, _amount);
        emit Withdraw(_amount, _to);
        return address(this).balance;
    }

    /**
     * @notice Tips the caller
     * @return The amount tipped
    */
    function _tip() internal returns (uint256) {
        uint256 tipAmount = _min(motivatorConfig.tipAmount, address(this).balance);

        SafeTransferLib.forceSafeTransferETH(tx.origin, tipAmount);

        emit Tip(tx.origin, tipAmount);

        return tipAmount;
    }

    /**
     * @notice Changes the motivator config
     * @param _motivatorConfig The new config
    */
    function _setMotivatorConfig(MotivatorConfig calldata _motivatorConfig) internal {
        motivatorConfig = _motivatorConfig;
    }

    /**
     * @notice Returns the minimum of two integers
     * @param _a The first integer
     * @param _b The second integer
     * @return The minimum value
    */
    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}