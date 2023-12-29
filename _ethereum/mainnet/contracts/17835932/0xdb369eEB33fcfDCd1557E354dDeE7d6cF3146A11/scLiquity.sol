// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./Address.sol";

import "./Constants.sol";
import "./IStabilityPool.sol";
import "./IPriceFeed.sol";
import "./sc4626.sol";

contract scLiquity is sc4626 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using Address for address;

    event DepositedIntoStrategy(uint256 amount);

    uint256 public totalInvested;
    uint256 public totalProfit;

    IStabilityPool public stabilityPool = IStabilityPool(C.LIQUITY_STABILITY_POOL);
    IPriceFeed public usd2eth = IPriceFeed(C.LIQUITY_USD_ETH_PRICE_FEED);
    ERC20 public lqty = ERC20(C.LIQUITY_LQTY_TOKEN);

    // 0x swap router
    address public xrouter = C.ZERO_EX_ROUTER;

    constructor(address _admin, address _keeper, ERC20 _lusd)
        sc4626(_admin, _keeper, _lusd, "Sandclock LUSD Vault", "scLUSD")
    {
        asset.safeApprove(address(stabilityPool), type(uint256).max);
    }

    // need to be able to receive eth rewards
    receive() external payable {
        require(msg.sender == address(stabilityPool));
    }

    // @dev: The Liquity stability pool offers a marginal yield in the form of LQTY rewards for deposits made into it.
    // However, the overhead of including these LQTY rewards into the scLiquity vault is quite high, mainly due to the substantial gas costs involved.
    // Therefore, the decision was made not to incorporate LQTY rewards into the totalAssets value.
    function totalAssets() public view override returns (uint256 assets) {
        uint256 ethBalance = address(this).balance + stabilityPool.getDepositorETHGain(address(this));

        // add eth balance in lusd terms using liquity oracle
        assets = ethBalance.mulWadDown(uint256(usd2eth.lastGoodPrice()));

        // add float
        assets += asset.balanceOf(address(this));

        // add invested amount
        assets += stabilityPool.getCompoundedLUSDDeposit(address(this));
    }

    function afterDeposit(uint256, uint256) internal override {
        // float is not allowed to be greater than 25% of the total
        // invested since liquidation rewards can be dilluted by savy
        // just-in-time depositors
        uint256 float = asset.balanceOf(address(this));
        if (float > (totalInvested / 4)) {
            _depositIntoStrategy();
        }
    }

    function beforeWithdraw(uint256 assets, uint256) internal override {
        uint256 float = asset.balanceOf(address(this));

        if (assets <= float) return;

        uint256 missing = (totalAssets() - assets).mulWadDown(floatPercentage);
        uint256 withdrawAmount = assets - float + missing;

        // needed otherwise counted as loss during harvest
        totalInvested -= withdrawAmount;

        stabilityPool.withdrawFromSP(withdrawAmount);
    }

    // @dev: access control not needed, this is only separate to save
    // gas for users depositing, ultimately controlled by float %
    function depositIntoStrategy() external {
        _depositIntoStrategy();
    }

    function _depositIntoStrategy() internal {
        uint256 float = asset.balanceOf(address(this));
        uint256 targetFloat = totalAssets().mulWadDown(floatPercentage);

        if (float <= targetFloat) return; // nothing to invest

        uint256 depositAmount = float - targetFloat;

        // needed otherwise counted as profit during harvest
        totalInvested += depositAmount;

        stabilityPool.provideToSP(depositAmount, address(0));

        emit DepositedIntoStrategy(depositAmount);
    }

    function harvest(uint256 _lqtyAmount, bytes calldata _lqtySwapData, uint256 _ethAmount, bytes calldata _ethSwapData)
        external
    {
        _onlyKeeper();

        // store the old total
        uint256 oldTotalInvested = totalInvested;

        // harvest any unclaimed rewards
        stabilityPool.withdrawFromSP(0);

        // swap LQTY -> LUSD
        if (_lqtyAmount > 0) {
            lqty.safeApprove(xrouter, _lqtyAmount);
            xrouter.functionCall(_lqtySwapData);
        }

        // swap ETH -> LUSD
        if (_ethAmount > 0) {
            xrouter.functionCallWithValue(_ethSwapData, _ethAmount);
        }

        // reinvest
        _depositIntoStrategy();

        totalInvested = stabilityPool.getCompoundedLUSDDeposit(address(this));

        // profit since last harvest, zero if there was a loss
        uint256 profit = totalInvested > oldTotalInvested ? totalInvested - oldTotalInvested : 0;

        if (profit > 0) {
            totalProfit += profit;

            uint256 fee = profit.mulWadDown(performanceFee);

            // mint equivalent amount of tokens to the performance fee beneficiary ie the treasury
            _mint(treasury, convertToShares(fee));
        }
    }
}
