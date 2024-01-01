// SPDX-License-Identifier: ISC

pragma solidity 0.8.19;

import "./AugustusStorage.sol";
import "./Utils.sol";
import "./IFeeClaimer.sol";
import "./IERC20.sol";

contract FeeModel is AugustusStorage {

    uint256 public immutable partnerSharePercent;
    uint256 public immutable maxFeePercent;
    IFeeClaimer public immutable feeClaimer;
    uint256 public immutable minFeePercent;

    constructor(
        uint256 _partnerSharePercent,
        uint256 _maxFeePercent,
        uint256 _minFeePercent,
        IFeeClaimer _feeClaimer
    ) {
        partnerSharePercent = _partnerSharePercent;
        maxFeePercent = _maxFeePercent;
        minFeePercent = _minFeePercent;
        feeClaimer = _feeClaimer;
    }

    function takeFromTokenFee(
        address fromToken,
        uint256 fromAmount,
        address payable partner,
        uint256 feePercent
    ) internal returns (uint256 newFromAmount) {
        uint256 fixedFeeBps = _getFixedFeeBps(feePercent);
        (uint256 partnerShare, uint256 paraswapShare) = _calcFixedFees(fromAmount, fixedFeeBps, partner);
        return _distributeFees(fromAmount, fromToken, partner, partnerShare, paraswapShare);
    }

    function _getFixedFeeBps(uint256 feePercent) internal view returns (uint256 fixedFeeBps) {
        return feePercent > maxFeePercent ? maxFeePercent : (feePercent < minFeePercent ? minFeePercent : feePercent);
    }

    function _calcFixedFees(uint256 amount, uint256 fixedFeeBps, address partner)
        private
        view
        returns (uint256 partnerShare, uint256 paraswapShare)
    {
        uint256 fee = amount * fixedFeeBps / 10000;
        if (partner == address(0)) {
            partnerShare = 0;
            paraswapShare = fee;
        } else {
            partnerShare = fee * partnerSharePercent / 10000;
            paraswapShare = fee - partnerShare;
        }
    }

    function _distributeFees(
        uint256 currentBalance,
        address token,
        address payable partner,
        uint256 partnerShare,
        uint256 paraswapShare
    ) private returns (uint256 newBalance) {
        uint256 totalFees = partnerShare + paraswapShare;
        if (totalFees == 0) return currentBalance;

        require(totalFees <= currentBalance, "Insufficient balance to pay for fees");

        Utils.transferTokens(token, payable(address(feeClaimer)), totalFees);
        if (partnerShare != 0) {
            feeClaimer.registerFee(partner, IERC20(token), partnerShare);
        }
        if (paraswapShare != 0) {
            feeClaimer.registerFee(feeWallet, IERC20(token), paraswapShare);
        }
        return currentBalance - totalFees;
    }
}