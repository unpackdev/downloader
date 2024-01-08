pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IStakingRewards.sol";
import "./IOracle.sol";
import "./SafeMathCopy.sol";
import "./UniswapV2Library.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

/// @title CompoundingStaker
/// Implementation of a compounding staker that farms TRIBE on the Fei Rewards
/// contract and compound the earned TRIBE to get more FEI-TRIBE LP tokens.
/// @author eswak
contract CompoundingStaker is Ownable, ERC20, ReentrancyGuard {
    using Decimal for Decimal.D256;
    using SafeMathCopy for uint256;
    using SafeERC20 for IERC20;

    // References to Fei Protocol contracts
    address public fei;
    address public tribe;
    address public feiTribePair;
    address public univ2Router2;
    address public feiStakingRewards;

    // Percent of farmed TRIBE kept to cover fees
    uint256 public fee = 500; // fee 5% forever
    uint256 public constant FEE_GRANULARITY = 10000;

    // Uniswap swap paths
    address[] public tribeFeiPath;

    // Constructor
    constructor(
      address _fei,
      address _tribe,
      address _feiTribePair,
      address _univ2Router2,
      address _feiStakingRewards,
      address _owner
    ) public ERC20("Compounding Staker Shares", "CSS"){
        transferOwnership(_owner);

        fei = _fei;
        tribe = _tribe;
        feiTribePair = _feiTribePair;
        univ2Router2 = _univ2Router2;
        feiStakingRewards = _feiStakingRewards;

        tribeFeiPath = new address[](2);
        tribeFeiPath[0] = tribe;
        tribeFeiPath[1] = fei;

        ERC20(fei).approve(univ2Router2, uint(-1));
        ERC20(tribe).approve(univ2Router2, uint(-1));
        ERC20(feiTribePair).approve(feiStakingRewards, uint(-1));
    }

    // Number of LP tokens managed by the CompoundingStaker.
    function staked() public view returns (uint256) {
        return IStakingRewards(feiStakingRewards).balanceOf(address(this));
    }

    // deposit() function : add LP tokens to the CompoundingStaker.
    // This will transfer the user's LP tokens to the CompoundingStaker, and
    // stake them on the FeiRewards contract. A user gets minted an ERC20 to
    // keep track of their share of the total LP tokens managed.
    // @dev: token is assumed not deflationary (no burn on transfer)
    function deposit(uint256 _amount) public nonReentrant {
        // compute share of the pool and get tokens
        uint256 _pool = staked();
        IERC20(feiTribePair).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = Decimal.from(_amount).mul(totalSupply()).div(_pool).asUint256();
        }

        // stake
        uint256 _lpTokenBalance = ERC20(feiTribePair).balanceOf(address(this));
        IStakingRewards(feiStakingRewards).stake(_lpTokenBalance);

        // mint caller's share of the pool
        _mint(msg.sender, shares);
    }

    // withdraw() function : remove LP tokens from the CompoundingStaker.
    // This will unstake the LP tokens from the FeiRewards contract, and
    // return them to the user. If harvest() has been called between a user
    // deposit() and withdraw(), their share will be worth more LP tokens
    // than what they originally deposited.
    function withdraw(uint256 _shares) public nonReentrant {
        uint256 r = Decimal.from(staked()).mul(_shares).div(totalSupply()).asUint256();
        _burn(msg.sender, _shares);

        IStakingRewards(feiStakingRewards).withdraw(r);
        IERC20(feiTribePair).safeTransfer(msg.sender, r);
    }

    // harvest function : claim TRIBE rewards, swap half TRIBE for FEI, add
    // liquidity on Uniswap-v2, and stake Uni-v2 FEI-TRIBE LP tokens for
    // compounding TRIBE rewards.
    // Restricted to onlyOwner to prevent flashloan sandwich attacks.
    function harvest() public onlyOwner {
        // Collects TRIBE tokens
        IStakingRewards(feiStakingRewards).getReward();
        uint256 tribeBalance = ERC20(tribe).balanceOf(address(this));

        if (tribeBalance > 0) {
            // some part is kept as fees
            uint256 keptFees = Decimal.from(tribeBalance).mul(fee).div(FEE_GRANULARITY).asUint256();
            IERC20(tribe).safeTransfer(owner(), keptFees);
            tribeBalance = tribeBalance - keptFees;

            // Get FEI-TRIBE pair reserves
            (uint256 _token0, uint256 _token1, ) = IUniswapV2Pair(feiTribePair).getReserves();
            (uint256 tribeReserve, uint256 feiReserve) =
                IUniswapV2Pair(feiTribePair).token0() == tribe
                    ? (_token0, _token1)
                    : (_token1, _token0);

            // Prepare swap
            uint256 amountIn = tribeBalance / 2;
            uint256 amountOut = UniswapV2Library.getAmountOut(
              amountIn,
              tribeReserve,
              feiReserve
            );

            // Perform swap
            IERC20(tribe).safeTransfer(feiTribePair, amountIn);
            (uint256 amount0Out, uint256 amount1Out) =
                IUniswapV2Pair(feiTribePair).token0() == tribe
                    ? (uint256(0), amountOut)
                    : (amountOut, uint256(0));
            IUniswapV2Pair(feiTribePair).swap(amount0Out, amount1Out, address(this), new bytes(0));

            // Add liquidity
            uint256 feiBalance = ERC20(fei).balanceOf(address(this));
            tribeBalance = ERC20(tribe).balanceOf(address(this));

            // Adds in liquidity for FEI/TRIBE
            if (feiBalance > 0 && tribeBalance > 0) {
                IUniswapV2Router02(univ2Router2).addLiquidity(
                    fei,
                    tribe,
                    feiBalance,
                    tribeBalance,
                    0,
                    0,
                    address(this),
                    now + 60
                );
            }

            // Dust
            feiBalance = ERC20(fei).balanceOf(address(this));
            tribeBalance = ERC20(tribe).balanceOf(address(this));
            if (feiBalance > 0) {
                IERC20(fei).safeTransfer(owner(), feiBalance);
            }
            if (tribeBalance > 0) {
                IERC20(tribe).safeTransfer(owner(), tribeBalance);
            }

            // stake LP tokens to get rewards
            uint256 lpTokens = ERC20(feiTribePair).balanceOf(address(this));
            if (lpTokens > 0) {
                IStakingRewards(feiStakingRewards).stake(lpTokens);
            }
        }
    }

    // Allow to recover ERC20s mistakenly sent to the contract
    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
