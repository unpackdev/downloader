// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./OwnableTwoSteps.sol";
import "./LowLevelERC20Transfer.sol";
import "./Pausable.sol";
import "./ITransferManager.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./ERC4626.sol";
import "./OracleLibrary.sol";
import "./IUniswapV3Pool.sol";

import "./IStakingRewards.sol";
import "./ISwapRouter.sol";
import "./IWrappedLooksRareToken.sol";
import "./UnsafeMathUint256.sol";

/**
 * @title AutoCompounder
 * @notice This contract auto-compounds WETH rewards into LOOKS and reinvests them into the StakingRewards contract.
 * @author LooksRare protocol team (👀,💎)
 */
contract AutoCompounder is ERC4626, OwnableTwoSteps, Pausable {
    using UnsafeMathUint256 for uint256;

    /**
     * @notice ERC20 token given as reward
     */
    IERC20 public immutable rewardToken;

    /**
     * @notice LOOKS token.
     */
    address public immutable LOOKS;

    /**
     * @notice StakingRewards contract
     */
    IStakingRewards public immutable stakingRewards;

    /**
     * @notice Uniswap router contract for swapping reward tokens to asset tokens
     */
    ISwapRouter public immutable uniswapRouter;

    /**
     * @notice Uniswap V3 pool contract for swapping reward tokens to asset tokens
     */
    address public immutable uniswapV3Pool;

    /**
     * @notice Uniswap V3 pool fee
     */
    uint24 public immutable uniswapV3PoolFee;

    /**
     * @notice Transfer manager
     */
    ITransferManager public immutable transferManager;

    /**
     * @notice Deposit asset value must be at least this value
     */
    uint256 private constant MINIMUM_DEPOSIT_AMOUNT = 1 ether;

    /**
     * @notice Minimum slippage basis points when swapping reward tokens to asset tokens
     */
    uint256 private constant MIN_SLIPPAGE_BP = 10;

    /**
     * @notice Maximum slippage basis points when swapping reward tokens to asset tokens
     */
    uint256 private constant MAX_SLIPPAGE_BP = 10_000;

    /**
     * @notice 100% in basis points
     */
    uint256 private constant ONE_HUNDRED_PERCENT_IN_BASIS_POINTS = 10_000;

    /**
     * @notice Accepted slippage in basis points when swapping reward tokens to asset tokens
     */
    uint16 public slippageBp = 500;

    /**
     * @notice Minimum amount of reward tokens to swap to asset tokens
     */
    uint128 public minimumSwapAmount = 0.15 ether;

    error AutoCompounder__DepositAmountTooLow();
    error AutoCompounder__InvalidSlippageBp();
    error AutoCompounder__NotTransferrable();

    event MinimumSwapAmountUpdated(uint256 _minimumSwapAmount);
    event SlippageBpUpdated(uint256 _slippageBp);

    /**
     * @param _owner Owner of the contract
     * @param _stakingToken Token to be staked
     * @param _stakingRewards StakingRewards contract
     * @param _uniswapRouter Uniswap router contract for swapping reward tokens to asset tokens
     * @param _uniswapV3Pool Uniswap V3 pool contract for swapping reward tokens to asset tokens
     * @param _transferManager Transfer manager
     */
    constructor(
        address _owner,
        IERC20 _stakingToken,
        address _stakingRewards,
        address _uniswapRouter,
        address _uniswapV3Pool,
        address _transferManager
    ) ERC20("Compounding LOOKS", "cLOOKS") ERC4626(_stakingToken) OwnableTwoSteps(_owner) {
        IERC20 _rewardToken = IStakingRewards(_stakingRewards).rewardToken();
        rewardToken = _rewardToken;

        LOOKS = IWrappedLooksRareToken(address(_stakingToken)).LOOKS();

        stakingRewards = IStakingRewards(_stakingRewards);
        uniswapRouter = ISwapRouter(_uniswapRouter);
        uniswapV3Pool = _uniswapV3Pool;
        uniswapV3PoolFee = IUniswapV3Pool(_uniswapV3Pool).fee();

        _rewardToken.approve(_uniswapRouter, type(uint256).max);
        _stakingToken.approve(_stakingRewards, type(uint256).max);

        transferManager = ITransferManager(_transferManager);

        address[] memory operators = new address[](1);
        operators[0] = address(_stakingToken);
        transferManager.grantApprovals(operators);
    }

    /**
     * @notice Shares are not transferrable.
     */
    function transfer(address, uint256) public pure override(ERC20, IERC20) returns (bool) {
        revert AutoCompounder__NotTransferrable();
    }

    /**
     * @notice Shares are not transferrable.
     */
    function transferFrom(address, address, uint256) public pure override(ERC20, IERC20) returns (bool) {
        revert AutoCompounder__NotTransferrable();
    }

    /**
     * @notice Set accepted slippage in basis points when swapping reward tokens to asset tokens. Only callable by contract owner.
     * @param _slippageBp Accepted slippage in basis points
     */
    function setSlippage(uint256 _slippageBp) external onlyOwner {
        if (_slippageBp < MIN_SLIPPAGE_BP || _slippageBp > MAX_SLIPPAGE_BP) {
            revert AutoCompounder__InvalidSlippageBp();
        }
        slippageBp = uint16(_slippageBp);

        emit SlippageBpUpdated(_slippageBp);
    }

    /**
     * @notice Set minimum amount of reward tokens to swap to asset tokens. Only callable by contract owner.
     * @param _minimumSwapAmount Minimum amount of reward tokens to swap to asset tokens
     */
    function setMinimumSwapAmount(uint128 _minimumSwapAmount) external onlyOwner {
        minimumSwapAmount = _minimumSwapAmount;

        emit MinimumSwapAmountUpdated(_minimumSwapAmount);
    }

    /**
     * @notice Sell pending reward tokens for asset tokens and stake them
     */
    function compound() external {
        _sellRewardTokenForAssetIfAny();
        stakingRewards.stake(IERC20(asset()).balanceOf(address(this)));
    }

    /**
     * @notice Deposit assets into the contract and stake them
     * @param assets Amount of assets to deposit
     * @param receiver Receiver of the shares
     * @return shares Amount of shares minted
     */
    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256) {
        if (assets < MINIMUM_DEPOSIT_AMOUNT) {
            revert AutoCompounder__DepositAmountTooLow();
        }

        _sellRewardTokenForAssetIfAny();

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        stakingRewards.stake(IERC20(asset()).balanceOf(address(this)));

        return shares;
    }

    /**
     * @notice Mint shares and stake assets
     * @param shares Amount of shares to mint
     * @param receiver Receiver of the shares
     * @return assets Amount of assets deposited
     */
    function mint(uint256 shares, address receiver) public override whenNotPaused returns (uint256) {
        _sellRewardTokenForAssetIfAny();

        uint256 assets = previewMint(shares);

        if (assets < MINIMUM_DEPOSIT_AMOUNT) {
            revert AutoCompounder__DepositAmountTooLow();
        }

        _deposit(_msgSender(), receiver, assets, shares);

        stakingRewards.stake(IERC20(asset()).balanceOf(address(this)));

        return assets;
    }

    /**
     * @notice Withdraw assets from the contract and unstake them
     * @param assets Amount of assets to withdraw
     * @param receiver Receiver of the assets
     * @param owner Owner of the shares
     * @return shares Amount of shares burned
     */
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        stakingRewards.withdraw(assets);

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /**
     * @notice Burn shares and unstake assets
     * @param shares Amount of shares to burn
     * @param receiver Receiver of the assets
     * @param owner Owner of the shares
     * @return assets Amount of assets withdrawn
     */
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);

        stakingRewards.withdraw(assets);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @notice Compound, withdraw assets from the contract, and unstake them
     * @param assets Amount of assets to withdraw
     * @param receiver Receiver of the assets
     * @param owner Owner of the shares
     * @return shares Amount of shares burned
     */
    function compoundAndWithdraw(uint256 assets, address receiver, address owner) external returns (uint256) {
        _sellRewardTokenForAssetIfAny();

        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        _stakeOrWithdrawNetAmount(assets);

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /**
     * @notice Compound, burn shares, and unstake assets
     * @param shares Amount of shares to burn
     * @param receiver Receiver of the assets
     * @param owner Owner of the shares
     * @return assets Amount of assets withdrawn
     */
    function compoundAndRedeem(uint256 shares, address receiver, address owner) external returns (uint256) {
        _sellRewardTokenForAssetIfAny();

        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);

        _stakeOrWithdrawNetAmount(assets);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @notice Toggle paused state. Only callable by contract owner.
     */
    function togglePaused() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @notice Total assets is the sum of the balance of the asset plus the auto-compounder's balance at the staking rewards contract
     */
    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + stakingRewards.balanceOf(address(this));
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 6;
    }

    function _sellRewardTokenForAssetIfAny() internal {
        uint256 pendingReward = stakingRewards.earned(address(this));

        if (pendingReward > minimumSwapAmount) {
            stakingRewards.getReward();
            uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(rewardToken),
                tokenOut: LOOKS,
                fee: uniswapV3PoolFee,
                recipient: address(this),
                amountIn: rewardTokenBalance,
                amountOutMinimum: _sellRewardAmountOutMinimum(rewardTokenBalance),
                sqrtPriceLimitX96: 0
            });

            uniswapRouter.exactInputSingle(params);

            uint256 balance = IERC20(LOOKS).balanceOf(address(this));
            IERC20(LOOKS).approve(address(transferManager), balance);
            IWrappedLooksRareToken(asset()).wrap(balance);
        }
    }

    /**
     * @param amountIn Amount of reward tokens to sell
     */
    function _sellRewardAmountOutMinimum(uint256 amountIn) private view returns (uint256 amountOutMinimum) {
        (int24 arithmeticMeanTick, ) = OracleLibrary.consult({pool: uniswapV3Pool, secondsAgo: 600});
        uint256 quote = OracleLibrary.getQuoteAtTick({
            tick: arithmeticMeanTick,
            baseAmount: uint128(amountIn),
            baseToken: address(rewardToken),
            quoteToken: LOOKS
        });

        amountOutMinimum =
            (quote * (ONE_HUNDRED_PERCENT_IN_BASIS_POINTS - slippageBp)) /
            ONE_HUNDRED_PERCENT_IN_BASIS_POINTS;
    }

    /**
     * @param assets Amount of assets to withdraw
     */
    function _stakeOrWithdrawNetAmount(uint256 assets) internal {
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        if (balance > assets) {
            stakingRewards.stake(balance.unsafeSubtract(assets));
        } else if (balance < assets) {
            stakingRewards.withdraw(assets.unsafeSubtract(balance));
        }
    }
}
