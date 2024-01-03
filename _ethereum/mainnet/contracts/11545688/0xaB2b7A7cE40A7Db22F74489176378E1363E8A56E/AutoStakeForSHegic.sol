// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./ISHegic.sol";
import "./AutoStake.sol";


/**
 * @title AutoStakeForSHegic
 * @notice Pools HegicIOUToken (rHEGIC) together and deposits to the rHEGIC --> HEGIC
 * redemption contract; withdraws HEGIC and deposits to jmonteer's hegicstakingpool.co
 * at regular intervals.
 */
 contract AutoStakeForSHegic is AutoStake {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    ISHegic public immutable sHEGIC;
    IERC20 public immutable WBTC;

    uint public ACCURACY = 1e32;

    uint public ethProfitPerToken = 0;
    uint public wbtcProfitPerToken = 0;
    uint public totalEthProfitClaimed = 0;
    uint public totalWbtcProfitClaimed = 0;

    constructor(
        IERC20 _WBTC,
        IERC20 _HEGIC,
        IERC20 _rHEGIC,
        ISHegic _sHEGIC,
        IGradualTokenSwap _GTS,
        uint _feeRate,
        address _feeRecipient
    )
    AutoStake(_HEGIC, _rHEGIC, _GTS)
    {
        WBTC = _WBTC;
        sHEGIC = _sHEGIC;
        feeRate = _feeRate;
        feeRecipient = _feeRecipient;
    }

    // Required for contract to receive ETH
    receive() external payable {}

    /**
     * @notice Redeem the maximum possible amount of rHEGIC to HEGIC, then stake
     * in the sHEGIC contract. The developer will call this at regular intervals.
     * Anyone can call this as well, although no benefit.
     * @return amountRedeemed Amount of HEGIC redeemed
     * @return amountStaked Amount of sHEGIC received from staking HEGIC
     */
    function redeemAndStake() override external returns (uint amountRedeemed, uint amountStaked) {
        amountRedeemed = GTS.available(address(this));
        require(amountRedeemed > 0, "No HEGIC to redeem");

        GTS.withdraw();
        HEGIC.approve(address(sHEGIC), amountRedeemed);
        sHEGIC.deposit(amountRedeemed);

        amountStaked = amountRedeemed;  // For sHEGIC, these are always equal
        totalRedeemed = totalRedeemed.add(amountRedeemed);
        totalStaked = totalStaked.add(amountStaked);
        totalWithdrawable = totalWithdrawable.add(amountStaked);
        lastRedemptionTimestamp = block.timestamp;
    }

    /**
     * @notice Withdraw all available sHEGIC claimable by the user, as well as ETH
     * and WBTC profits pro-rata.
     */
    function withdraw() override external {
        require(allowWithdrawal(), "Withdrawal not opened yet");

        uint amount = amountDeposited[msg.sender].sub(amountWithdrawn[msg.sender]);
        require(amount > 0, "No sHEGIC token available for withdrawal");

        claimProfit();

        uint fee = amount.mul(feeRate).div(10000);
        uint amountAfterFee = amount.sub(fee);
        uint ethProfit = ethProfitPerToken.mul(amount).div(ACCURACY);
        uint wbtcProfit = wbtcProfitPerToken.mul(amount).div(ACCURACY);

        // Transfer sHEGIC and ETH/WBTC profits to user
        sHEGIC.transfer(msg.sender, amountAfterFee);
        payable(msg.sender).transfer(ethProfit);
        WBTC.transfer(msg.sender, wbtcProfit);

        // Transfer sHEGIC fee to developer
        sHEGIC.transfer(feeRecipient, fee);

        // Update state variables
        amountWithdrawn[msg.sender] = amountWithdrawn[msg.sender].add(amount);
        totalWithdrawable = totalWithdrawable.sub(amount);
        totalWithdrawn = totalWithdrawn.add(amountAfterFee);
        totalFeeCollected = totalFeeCollected.add(fee);

        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }

    /**
     * @notice Determine if withdrawl is opened.
     * @return true if all rHEGIC have been redeemed & staked; false if otherwise
     */
    function allowWithdrawal() public view returns (bool) {
        if (totalRedeemed > 0 && totalRedeemed == totalDeposited) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Helper function. Calculates the total amount of staking profits
     * that have been claimed or can be claimed.
     * @return ethProfit The amount of profit in ETH
     * @return wbtcProfit The amount of profit in WBTC
     */
    function getClaimableProfit() public view returns (uint ethProfit, uint wbtcProfit) {
        uint ethProfitToBeClaimed = sHEGIC.profitOf(address(this), 1);
        uint wbtcProfitToBeClaimed = sHEGIC.profitOf(address(this), 0);

        ethProfit = totalEthProfitClaimed.add(ethProfitToBeClaimed);
        wbtcProfit = totalWbtcProfitClaimed.add(wbtcProfitToBeClaimed);
    }

    /**
     * @notice Claim ETH and WBTC profit from the staking pool contract, and calculate
     * how much profit should be distributed to each staked token.
     */
    function claimProfit() public {
        uint ethBalanceBeforeClaim = address(this).balance;
        uint wbtcBalanceBeforeClaim = WBTC.balanceOf(address(this));

        sHEGIC.claimAllProfit();

        uint ethBalanceAfterClaim = address(this).balance;
        uint wbtcBalanceAfterClaim = WBTC.balanceOf(address(this));

        uint ethClaimed = ethBalanceAfterClaim.sub(ethBalanceBeforeClaim);
        uint wbtcClaimed = wbtcBalanceAfterClaim.sub(wbtcBalanceBeforeClaim);

        ethProfitPerToken = ethProfitPerToken
            .add(ethClaimed.mul(ACCURACY).div(totalWithdrawable));
        wbtcProfitPerToken = wbtcProfitPerToken
            .add(wbtcClaimed.mul(ACCURACY).div(totalWithdrawable));

        totalEthProfitClaimed = totalEthProfitClaimed.add(ethClaimed);
        totalWbtcProfitClaimed = totalWbtcProfitClaimed.add(wbtcClaimed);
    }
}
