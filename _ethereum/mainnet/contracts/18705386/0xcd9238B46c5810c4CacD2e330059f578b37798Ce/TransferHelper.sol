// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Errors.sol";
import "./Constants.sol";
import "./TransferUtils.sol";
import "./IRewardHandler.sol";

abstract contract TransferHelper is Initializable, OwnableUpgradeable {

    event RewardHandlerUpdate(address rewardHandler);
    event RewardsActiveUpdate(bool rewardsActiveFlag);

    IRewardHandler internal rewardHandler;
    address internal _rewardAddress;
    uint256 public rewardsActive;

    function initializeTransferData(address rewardAddress) public onlyInitializing {
        __Ownable_init();
        if (rewardAddress == address(0)) revert Errors.InvalidAddress();
        _rewardAddress = rewardAddress;
        rewardHandler = IRewardHandler(rewardAddress);
        rewardsActive = 2;
    }

    function _transferClaim(address maker, address taker, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 fee, uint8 feeType) internal {
        if (tokenB == Constants.NATIVE_ADDRESS) {
            TransferUtils._transferETH(_rewardAddress, fee);
            TransferUtils._transferETH(maker, amountB);
            TransferUtils._transferERC20(tokenA, taker, amountA);
            _logNativeFee(fee);
            return;
        }
        else if (tokenA == Constants.NATIVE_ADDRESS) {
            uint256 payment = amountA - fee;
            TransferUtils._transferETH(_rewardAddress, fee);
            TransferUtils._transferETH(taker, payment);
            TransferUtils._transferFromERC20(tokenB, taker, maker, amountB);
            _logNativeFee(fee);
            return;
        }
        else if (feeType == Constants.FEE_TYPE_TOKEN_B) {
            TransferUtils._transferFromERC20(tokenB, taker, _rewardAddress, fee);
            TransferUtils._transferFromERC20(tokenB, taker, maker, amountB);
            TransferUtils._transferERC20(tokenA, taker, amountA);
            _logTokenFee(tokenB, fee);
            return;
        }
        else if (feeType == Constants.FEE_TYPE_TOKEN_A) {
            uint256 payment = amountA - fee;
            TransferUtils._transferERC20(tokenA, _rewardAddress, fee);
            TransferUtils._transferERC20(tokenA, taker, payment);
            TransferUtils._transferFromERC20(tokenB, taker, maker, amountB);
            _logTokenFee(tokenA, fee);
            return;
        }
        else if (feeType == Constants.FEE_TYPE_ETH_FIXED) {
            TransferUtils._transferETH(_rewardAddress, fee);
            TransferUtils._transferERC20(tokenA, taker, amountA);
            TransferUtils._transferFromERC20(tokenB, taker, maker, amountB);
            _logNativeFee(fee);
            return;
        }
        revert Errors.UnknownFeeType(feeType);
    }

    function _transferFee(address taker, address feeToken, uint256 fee, uint8 feeType) internal {
        if (feeType == Constants.FEE_TYPE_ETH_FIXED || feeToken == Constants.NATIVE_ADDRESS) {
            TransferUtils._transferETH(_rewardAddress, fee);
            _logNativeFee(fee);
            return;
        }
        else if (feeType == Constants.FEE_TYPE_TOKEN_B) {
            TransferUtils._transferFromERC20(feeToken, taker, _rewardAddress, fee);
            _logTokenFee(feeToken, fee);
            return;
        }
        else if (feeType == Constants.FEE_TYPE_TOKEN_A) {
            TransferUtils._transferERC20(feeToken, _rewardAddress, fee);
            _logTokenFee(feeToken, fee);
            return;
        }
        revert Errors.UnknownFeeType(feeType);
    }

    function setRewardHandler(address rewardAddress) external onlyOwner {
        if (rewardAddress == address(0)) revert Errors.InvalidAddress();
        _rewardAddress = rewardAddress;
        rewardHandler = IRewardHandler(rewardAddress);
        emit RewardHandlerUpdate(rewardAddress);
    }

    function setRewardsActive(bool rewardsActiveFlag) external onlyOwner {
        rewardsActive = rewardsActiveFlag ? 1 : 2;
        emit RewardsActiveUpdate(rewardsActiveFlag);
    }

    function _logTokenFee(address token, uint256 fee) internal {
        if (rewardsActive == 2) return;
        if (!rewardHandler.logTokenFee(token, fee)) revert Errors.RewardHandlerLogFailed();
    }

    function _logNativeFee(uint256 fee) internal {
        if (rewardsActive == 2) return;
        if (!rewardHandler.logNativeFee(fee)) revert Errors.RewardHandlerLogFailed();
    }

}

