// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./IWasabiFeeManager.sol";

/**
 * @dev An implementation of the IWasabiFeeManager
 */
contract WasabiFeeManager2 is IWasabiFeeManager, Ownable {
    address public receiver;
    uint96 public fraction;
    uint96 public denominator;
    uint96 public unitDiscount;
    IERC1155 public wasabiPass;
    uint256 public passId;
    uint8 public maxPassAmount = 10;

    constructor(IERC1155 _wasabiPass, uint256 _passId, uint96 _fraction, uint96 _denominator, uint96 _unitDiscount) {
        receiver = owner();
        wasabiPass = _wasabiPass;
        passId = _passId;
        fraction = _fraction;
        denominator = _denominator;
        unitDiscount = _unitDiscount;
    }

    /// @inheritdoc IWasabiFeeManager
    function getFeeData(address, uint256 _amount) external view returns (address, uint256) {
        uint256 passBalance = wasabiPass.balanceOf(tx.origin, passId);
        if (passBalance > maxPassAmount) {
            passBalance = maxPassAmount;
        }
        uint256 discountedFraction = fraction - passBalance * unitDiscount;
        uint256 amount = (_amount * discountedFraction) / denominator;
        return (receiver, amount);
    }

    /// @inheritdoc IWasabiFeeManager
    function getFeeDataForOption(uint256, uint256 _amount) external view returns (address, uint256) {
        uint256 passBalance = wasabiPass.balanceOf(tx.origin, passId);
        if (passBalance > maxPassAmount) {
            passBalance = maxPassAmount;
        }
        uint256 discountedFraction = fraction - passBalance * unitDiscount;
        uint256 amount = (_amount * discountedFraction) / denominator;
        return (receiver, amount);
    }

    /**
     * @dev     Sets the receiver of the fee
     * @param   _receiver  the receiver
     */
    function setReceiver(address _receiver) external onlyOwner {
        receiver = _receiver;
    }

    /**
     * @dev     Sets the fraction of the fee
     * @param   _fraction  the fraction
     */
    function setFraction(uint96 _fraction) external onlyOwner {
        fraction = _fraction;
    }

    /**
     * @dev     Sets the denominator of the fee
     * @param   _denominator the denominator
     */
    function setDenominator(uint96 _denominator) external onlyOwner {
        denominator = _denominator;
    }

    /**
     * @dev     Sets the unit discount of the fee
     * @param   _unitDiscount the unit discount
     */
    function setUnitDiscount(uint96 _unitDiscount) external onlyOwner {
        unitDiscount = _unitDiscount;
    }
}