// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./BLXMRewardProvider.sol";
import "./IBLXMStaker.sol";
import "./Initializable.sol";

import "./IWETH.sol";

import "./TransferHelper.sol";
import "./BLXMLibrary.sol";


contract BLXMStaker is Initializable, BLXMRewardProvider, IBLXMStaker {
    using SafeMath for uint256;

    address public override BLXM;

    function initialize(address _BLXM) public initializer {
        __ReentrancyGuard_init();
        __BLXMMultiOwnable_init();

        updateRewardFactor(30, 1000000000000000000);
        updateRewardFactor(90, 1300000000000000000);
        updateRewardFactor(180, 1690000000000000000);
        updateRewardFactor(360, 2197000000000000000);

        BLXM = _BLXM;
    }

    function addRewards(uint256 totalBlxmAmount, uint16 supplyDays) external override returns (uint256 amountPerHours) {
        TransferHelper.safeTransferFrom(BLXM, msg.sender, getTreasury(), totalBlxmAmount);
        amountPerHours = _addRewards(totalBlxmAmount, supplyDays);
    }

    function stake(uint256 amount, address to, uint16 lockedDays) external override {
        require(amount > 0, "ZERO_AMOUNT");
        TransferHelper.safeTransferFrom(BLXM, msg.sender, getTreasury(), amount);
        _stake(to, amount, lockedDays);
    }

    function withdraw(uint256 amount, address to, uint256 idx) external override returns (uint256 rewardAmount) {
        require(amount > 0, "ZERO_AMOUNT");
        rewardAmount = _withdraw(to, amount, idx);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}
