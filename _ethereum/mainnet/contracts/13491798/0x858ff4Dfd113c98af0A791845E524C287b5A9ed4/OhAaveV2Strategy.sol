// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IStrategy.sol";
import "./TransferHelper.sol";
import "./OhStrategy.sol";
import "./OhAaveV2Helper.sol";
import "./OhAaveV2StrategyStorage.sol";

/// @title Oh! Finance Aave V2 Strategy
/// @notice Standard strategy using Aave V2 Protocol
/// @dev Underlying: USDC, USDT, etc.
/// @dev Derivative: aToken, 1:1 ratio with underlying
/// @dev https://docs.aave.com/developers/the-core-protocol/atokens
contract OhAaveV2Strategy is IStrategy, OhAaveV2Helper, OhStrategy, OhAaveV2StrategyStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice Initialize the AaveV2 Strategy Logic
    constructor() initializer {
        assert(registry() == address(0));
        assert(bank() == address(0));
        assert(underlying() == address(0));
        assert(reward() == address(0));
    }

    /// @notice Initialize the AaveV2 Strategy Proxy
    /// @param registry_ the registry contract
    /// @param bank_ the bank associated with the strategy
    /// @param underlying_ the underlying token that is deposited
    /// @param derivative_ the aToken address received from Aave
    /// @param reward_ the address of the reward token stkAAVE
    /// @param lendingPool_ the AaveV2 lending pool that we lend to
    /// @param incentivesController_ the AaveV2 rewards contract
    /// @dev The function should be called at time of deployment
    function initializeAaveV2Strategy(
        address registry_,
        address bank_,
        address underlying_,
        address derivative_,
        address reward_,
        address stakedToken_,
        address lendingPool_,
        address incentivesController_
    ) public initializer {
        initializeStrategy(registry_, bank_, underlying_, derivative_, reward_);
        initializeAaveV2Storage(stakedToken_, lendingPool_, incentivesController_);
    }

    /// @notice Balance of underlying invested in AaveV2
    /// @dev aTokens are 1:1 with underlying, they are continuously distributed to users
    function investedBalance() public view override returns (uint256) {
        return derivativeBalance();
    }

    /// @notice Balance of stkAAVE await liquidation
    /// @dev Rewards are first received in stkAAVe, then must undergo 10 day cooldown
    /// @dev Before batch claiming.
    function stakedBalance() public view returns (uint256) {
        return IERC20(stakedToken()).balanceOf(address(this));
    }

    /// @notice Invest in the AaveV2 Strategy
    /// @dev Compound by claiming stkAAVE, then unwrapping + liquidating if cooldown permits
    /// @dev Deposit all underlying to receive aTokens
    function invest() external override onlyBank {
        _compound();
        _deposit();
    }

    /// @notice
    function withdraw(uint256 amount) external override onlyBank returns (uint256) {
        uint256 withdrawn = _withdraw(msg.sender, amount);
        return withdrawn;
    }

    /// @notice
    function withdrawAll() external override onlyBank {
        uint256 amount = derivativeBalance();
        _withdraw(msg.sender, amount);
    }

    /// @dev Compound stkAAVE rewards on a alternating cooldown schedule
    function _compound() internal {
        uint256 currentCooldown = rewardCooldown();

        // if the current cooldown has passed
        if (block.timestamp > currentCooldown) {
            // save state variables
            uint256 balance = stakedBalance();
            address staked = stakedToken();
            uint256 expiration = currentCooldown.add(unstakingWindow(staked));

            // if we have stkAAVE and the unstaking window hasn't passed
            if (balance > 0 && block.timestamp < expiration) {
                // redeem all available AAVE
                redeem(staked, balance);

                // validate we received AAVE
                uint256 amount = rewardBalance();
                if (amount > 0) {
                    // liquidate for underlying
                    liquidate(reward(), underlying(), amount);
                }
            }

            // claim new batch of available stkAAVE rewards
            claimRewards(incentivesController(), derivative());

            balance = stakedBalance();
            if (balance > 0) {
                // initiate a new cooldown
                cooldown(staked);

                // validate the cooldown was set
                uint256 newCooldown = stakersCooldown(staked);
                require(newCooldown == block.timestamp, "AaveV2: Cooldown failed");

                // find reward cooldown, new timestamp when rewards are claimable
                uint256 newRewardCooldown = newCooldown.add(cooldownWindow(staked));
                _setRewardCooldown(newRewardCooldown);
            }
        }
    }

    function _deposit() internal {
        uint256 amount = underlyingBalance();
        if (amount > 0) {
            lend(lendingPool(), underlying(), amount);
        }
    }

    // withdraw tokens from protocol after converting aTokens to underlying
    function _withdraw(address recipient, uint256 amount) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        uint256 reclaimed = reclaim(lendingPool(), underlying(), amount);
        uint256 withdrawn = TransferHelper.safeTokenTransfer(recipient, underlying(), reclaimed);
        return withdrawn;
    }
}
