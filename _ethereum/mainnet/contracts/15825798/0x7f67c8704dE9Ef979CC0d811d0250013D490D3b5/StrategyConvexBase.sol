// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./Address.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./BaseStrategy.sol";
import "./IConvexRewards.sol";
import "./IConvexDeposit.sol";

abstract contract StrategyConvexBase is BaseStrategy {
    using Address for address;
    using SafeMath for uint256;

    // convex stuff
    address internal constant _DEPOSIT_CONTRACT = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31; // this is the deposit contract that all pools use, aka booster
    IConvexRewards public rewardsContract; // This is unique to each curve pool
    address public virtualRewardsPool; // This is only if we have bonus rewards
    uint256 public pid; // this is unique to each pool

    // Swap stuff
    address internal constant _SUSHI_SWAP = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // we use this to sell our bonus token

    IERC20 internal constant _CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 internal constant _CONVEX_TOKEN = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 internal constant _WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // keeper stuff
    uint256 public harvestProfitMin; // minimum size in USD (6 decimals) that we want to harvest
    uint256 public harvestProfitMax; // maximum size in USD (6 decimals) that we want to harvest
    uint256 public creditThreshold; // amount of credit in underlying tokens that will automatically trigger a harvest

    string internal _stratName;

    // convex-specific variables
    bool public claimRewards; // boolean if we should always claim rewards when withdrawing, usually via withdrawAndUnwrap (generally this should be false)

    constructor(address _vault) BaseStrategy(_vault) {}

    function name() external view override returns (string memory) {
        return _stratName;
    }

    /// @notice How much want we have staked in Convex
    function stakedBalance() public view returns (uint256) {
        return rewardsContract.balanceOf(address(this));
    }

    /// @notice Balance of want sitting in our strategy
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    /// @notice How much CRV we can claim from the staking contract
    function claimableBalance() public view returns (uint256) {
        return rewardsContract.earned(address(this));
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfWant().add(stakedBalance());
    }

    // solhint-disable-next-line no-unused-vars
    function _adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }
        // Send all of our Curve pool tokens to be deposited
        uint256 _toInvest = balanceOfWant();
        // deposit into convex and stake immediately (but only if we have something to invest)
        if (_toInvest > 0) {
            IConvexDeposit(_DEPOSIT_CONTRACT).deposit(pid, _toInvest, true);
        }
    }

    function _liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 _wantBal = balanceOfWant();
        if (_amountNeeded > _wantBal) {
            uint256 _stakedBal = stakedBalance();
            if (_stakedBal > 0) {
                rewardsContract.withdrawAndUnwrap(Math.min(_stakedBal, _amountNeeded.sub(_wantBal)), claimRewards);
            }
            uint256 _withdrawnBal = balanceOfWant();
            _liquidatedAmount = Math.min(_amountNeeded, _withdrawnBal);
            _loss = _amountNeeded.sub(_liquidatedAmount);
        } else {
            // we have enough balance to cover the liquidation available
            return (_amountNeeded, 0);
        }
    }

    // fire sale, get rid of it all!
    function _liquidateAllPositions() internal override returns (uint256) {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            // don't bother withdrawing zero
            rewardsContract.withdrawAndUnwrap(_stakedBal, claimRewards);
        }
        return balanceOfWant();
    }

    // in case we need to exit into the convex deposit token, this will allow us to do that
    // make sure to check claimRewards before this step if needed
    // plan to have gov sweep convex deposit tokens from strategy after this
    function withdrawToConvexDepositTokens() external onlyGovernance {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            rewardsContract.withdraw(_stakedBal, claimRewards);
        }
    }

    // we don't want for these tokens to be swept out. We allow gov to sweep out cvx vault tokens; we would only be holding these if things were really, really rekt.
    function _protectedTokens() internal view override returns (address[] memory) {}

    // We usually don't need to claim rewards on withdrawals, but might change our mind for migrations etc
    function setClaimRewards(bool _claimRewards) external onlyGovernance {
        claimRewards = _claimRewards;
    }
}
