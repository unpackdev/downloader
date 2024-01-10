// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

import "./Ownable.sol";
import "./IPlatformFees.sol";

contract PlatformFees is Ownable, IPlatformFees {

    uint256 public stakeFeeNumerator;
    uint256 public stakeFeeDenominator;
    uint256 public unstakeFeeNumerator;
    uint256 public unstakeFeeDenominator;
    uint256 public minStakeAmount;
    uint256 public stakeTxLimit;

    address payable public feeWallet;
    bool private initDone;

    function init(
        uint256 stakeFeeNumerator_,
        uint256 stakeFeeDenominator_,
        uint256 unstakeFeeNumerator_,
        uint256 unstakeFeeDenominator_,
        uint256 minStakeAmount_,
        uint256 stakeTxLimit_,
        address payable feeWallet_,
        address serviceAdmin
    ) internal {
        require(!initDone, "PlatformFee: init done");

        stakeFeeNumerator = stakeFeeNumerator_;
        stakeFeeDenominator = stakeFeeDenominator_;
        unstakeFeeNumerator = unstakeFeeNumerator_;
        unstakeFeeDenominator = unstakeFeeDenominator_;
        minStakeAmount = minStakeAmount_;
        stakeTxLimit = stakeTxLimit_;
        feeWallet = feeWallet_;

        Ownable.init(serviceAdmin);
        initDone = true;
    }

    function setStakeFeeNumerator(uint256 numerator_) external override anyAdmin {
        stakeFeeNumerator = numerator_;
    }

    function setStakeFeeDenominator(uint256 denominator_) external override anyAdmin {
        require(denominator_ > 0, "PlatformFee: denominator can not be zero");
        stakeFeeDenominator = denominator_;
    }

    function setUnstakeFeeNumerator(uint256 numerator_) external override anyAdmin {
        unstakeFeeNumerator = numerator_;
    }

    function setUnstakeFeeDenominator(uint256 denominator_) external override anyAdmin {
        require(denominator_ > 0, "PlatformFee: denominator can not be zero");
        unstakeFeeDenominator = denominator_;
    }

    function setMinStakeAmount(uint256 amount_) external override anyAdmin {
        require(amount_ > 0, "PlatformFee: amount can not be zero");
        minStakeAmount = amount_;
    }

    function setStakeTxLimit(uint256 limit_) external override anyAdmin {
        require(limit_ > 0, "PlatformFee: limit can not zero");
        stakeTxLimit = limit_;
    }

    function setFeeWallet(address payable feeWallet_) external override anyAdmin {
        require(feeWallet_ != address(0), "PlatformFee: address can not be zero address");
        feeWallet = feeWallet_;
    }

}
