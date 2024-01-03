// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IZLotPool.sol";
import "./AutoStake.sol";


/**
 * @title AutoStakeToZHegic
 * @notice Pools HegicIOUToken (rHEGIC) together and deposits to the rHEGIC --> HEGIC
 * redemption contract; withdraws HEGIC and deposits to zLOT HEGIC pool at regular
 * intervals.
 */
 contract AutoStakeForZHegic is AutoStake {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable zHEGIC;
    IZLotPool public immutable zLotPool;

    constructor(
        IERC20 _HEGIC,
        IERC20 _rHEGIC,
        IERC20 _zHEGIC,
        IZLotPool _zLotPool,
        IGradualTokenSwap _GTS,
        uint _feeRate,
        address _feeRecipient
    )
    AutoStake(_HEGIC, _rHEGIC, _GTS)
    {
        zHEGIC = _zHEGIC;
        zLotPool = _zLotPool;
        feeRate = _feeRate;
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Redeem the maximum possible amount of rHEGIC to HEGIC, then stake
     * in the sHEGIC contract. The developer will call this at regular intervals.
     * Anyone can call this as well, albeit no benefit.
     * @return amountRedeemed Amount of HEGIC redeemed
     * @return amountStaked Amount of zHEGIC received from staking HEGIC
     */
    function redeemAndStake() override external returns (uint amountRedeemed, uint amountStaked) {
        amountRedeemed = GTS.available(address(this));
        require(amountRedeemed > 0, "No HEGIC to redeem");

        GTS.withdraw();
        HEGIC.approve(address(zLotPool), amountRedeemed);
        amountStaked = zLotPool.deposit(amountRedeemed);

        totalRedeemed = totalRedeemed.add(amountRedeemed);
        totalStaked = totalStaked.add(amountStaked);
        totalWithdrawable = totalWithdrawable.add(amountStaked);

        lastRedemptionTimestamp = block.timestamp;
    }

    /**
     * @notice Withdraw all available zHEGIC claimable by the user.
     */
    function withdraw() override external {
        uint amount = getUserWithdrawableAmount(msg.sender);
        require(amount > 0, "No zHEGIC token available for withdrawal");

        uint fee = amount.mul(feeRate).div(10000);
        uint amountAfterFee = amount.sub(fee);

        zHEGIC.safeTransfer(msg.sender, amountAfterFee);
        zHEGIC.safeTransfer(feeRecipient, fee);

        amountWithdrawn[msg.sender] = amountWithdrawn[msg.sender].add(amount);

        totalWithdrawable = totalWithdrawable.sub(amount);
        totalWithdrawn = totalWithdrawn.add(amountAfterFee);
        totalFeeCollected = totalFeeCollected.add(fee);

        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }

    /**
     * @notice Calculate the maximum amount of zHEGIC token available for withdrawable
     * by a user.
     * @param account The user's account address
     * @return amount The user's withdrawable amount
     */
    function getUserWithdrawableAmount(address account) public view returns (uint amount) {
        if (totalDeposited == 0) {
            amount = 0;
        } else {
            amount = totalStaked
                .mul(amountDeposited[account])
                .div(totalDeposited)
                .sub(amountWithdrawn[account]);
        }
        if (totalWithdrawable < amount) {
            amount = totalWithdrawable;
        }
    }
}
