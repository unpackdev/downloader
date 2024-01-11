// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./StakingRewards.sol";

contract Leaderboard is Ownable {
    using SafeMath for uint112;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @notice Token that is staked
    address public immutable stakingToken;
    /// @notice UniswapRouter
    IUniswapV2Router02 public immutable router;
    /// @notice UniswapFactory
    IUniswapV2Factory public immutable factory;

    /// @notice List of all StakingRewards
    mapping(uint256 => StakingRewards) public stakingRewards;
    /// @notice Disable status of each StakingRewards
    mapping(uint256 => bool) public stakingRewardsDisabled;
    /// @notice Number of deployed StakingRewards
    uint256 public stakingRewardsCount;
    /// @notice Buyback proprtion in BPS
    uint256 public buybackProportion;

    // == Iteration tracking variables for runEpoch ==
    uint256 internal _pointer;
    StakingRewards internal _max;
    uint256 internal _maxAmount;

    event StakingRewardsDisabledChanged(uint256 index, bool disabled);
    event BuybackExecuted(address indexed token, uint256 amount);
    event BuybackProportionChanged(
        uint256 prevBuybackProportion,
        uint256 nextBuybackProportion
    );
    event Recovered(address token, uint256 amount);
    event RecoveredETH(uint256 amount);

    constructor(
        address _stakingToken,
        IUniswapV2Router02 _router,
        uint256 _buybackProportion
    ) {
        stakingToken = _stakingToken;
        router = _router;
        factory = IUniswapV2Factory(_router.factory());
        buybackProportion = _buybackProportion;
    }

    /// @notice Deploy and add a new StakingRewards
    /// @param token The rewards token and the representative token
    function addStakingContract(address token) external onlyOwner {
        stakingRewards[stakingRewardsCount] = new StakingRewards(
            address(this),
            address(this),
            token,
            stakingToken
        );
        stakingRewardsCount += 1;
    }

    /// @notice Enable/Disable a StakingRewards from the leaderboard
    /// @param index The index of the StakingRewards
    /// @param disabled The desired disabled status
    function setStakingRewardsDisabled(uint256 index, bool disabled)
        external
        onlyOwner
    {
        require(index < stakingRewardsCount, "index out of range");
        stakingRewardsDisabled[index] = disabled;
        emit StakingRewardsDisabledChanged(index, disabled);
    }

    /// @notice Change the buybackProportion
    /// @param _buybackProportion The new buybackProportion
    function setBuybackProportion(uint256 _buybackProportion)
        external
        onlyOwner
    {
        require(
            _buybackProportion <= BPS_DENOMINATOR,
            "_buybackProportion too large"
        );
        emit BuybackProportionChanged(buybackProportion, _buybackProportion);
        buybackProportion = _buybackProportion;
    }

    /// @notice Run the epoch
    /// @param batchSize Max number of StakingRewards to iterate over
    function runEpoch(uint256 batchSize) external onlyOwner {
        require(batchSize > 0, "batchSize must be positive");
        uint256 end = _pointer + batchSize;
        if (end > stakingRewardsCount) {
            end = stakingRewardsCount;
        }
        for (; _pointer < end; _pointer++) {
            if (!stakingRewardsDisabled[_pointer]) {
                StakingRewards s = stakingRewards[_pointer];
                uint256 totalSupply = s.totalSupply();
                if (totalSupply > _maxAmount) {
                    _max = s;
                    _maxAmount = totalSupply;
                }
            }
        }
    }

    /// @notice Finalize the epoch with a buyback
    /// @param minOut Minimum amount of tokens received from the buyback. Used for slippage protection
    function buyback(uint256 minOut) external onlyOwner {
        buybackSpecificETH(minOut, address(this).balance);
    }

    /// @notice Finalize the epoch with a buyback and a specific ETH amount to use
    /// @param minOut Minimum amount of tokens received from the buyback. Used for slippage protection
    /// @param ethAmount Amount of ETH to use
    function buybackSpecificETH(uint256 minOut, uint256 ethAmount)
        public
        onlyOwner
    {
        require(_pointer == stakingRewardsCount, "runEpoch incomplete");
        require(ethAmount <= address(this).balance, "ethAmount too large");
        // Only run if _max is not the 0 address. Covers edge case when all
        // staking rewards are disabled
        if (address(_max) != address(0)) {
            IERC20 token = _max.rewardsToken();
            if (ethAmount > 0) {
                address[] memory path = new address[](2);
                path[0] = router.WETH();
                path[1] = address(token);
                router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: ethAmount
                }(minOut, path, address(this), block.timestamp);
            }
            uint256 transferAmount = token
                .balanceOf(address(this))
                .mul(buybackProportion)
                .div(BPS_DENOMINATOR);
            token.safeTransfer(address(_max), transferAmount);
            _max.notifyRewardAmount(transferAmount);
            emit BuybackExecuted(address(token), transferAmount);
        }
        // Reset
        _pointer = 0;
        _max = StakingRewards(address(0));
        _maxAmount = 0;
    }

    /* ========== StakingReward management ========== */

    /// @notice Manually notify rewards
    /// @param index The index of the StakingRewards
    /// @param reward The amount of rewards to distrubute over the rewardsDuration
    function notifyRewardAmount(uint256 index, uint256 reward)
        external
        onlyOwner
    {
        require(index < stakingRewardsCount, "index out of range");
        stakingRewards[index].notifyRewardAmount(reward);
    }

    /// @notice Emergency token recovery for a StakingRewards
    /// @param index The index of the StakingRewards
    /// @param tokenAddress The ERC20 token to recover
    /// @param tokenAmount The amount to recover
    function recoverStakingRewardsERC20(
        uint256 index,
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        require(index < stakingRewardsCount, "index out of range");
        stakingRewards[index].recoverERC20(tokenAddress, tokenAmount);
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

    /// @notice Change a StakingReward's rewardDuration
    /// @param index The index of the StakingRewards
    /// @param rewardsDuration The new rewards duration
    function setRewardsDuration(uint256 index, uint256 rewardsDuration)
        external
        onlyOwner
    {
        require(index < stakingRewardsCount, "index out of range");
        stakingRewards[index].setRewardsDuration(rewardsDuration);
    }

    /* ========== Emergency recovery ========== */

    /// @notice Emergency token recovery
    /// @param tokenAddress The ERC20 token to recover
    /// @param tokenAmount The amount to recover
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /// @notice Emergency ETH recovery
    /// @param amount The amount to recover
    function recoverETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
        emit RecoveredETH(amount);
    }

    receive() external payable {}
}
