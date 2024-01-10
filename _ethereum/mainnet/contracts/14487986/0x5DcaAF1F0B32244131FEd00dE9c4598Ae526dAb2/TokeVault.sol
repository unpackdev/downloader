pragma solidity ^0.8.0;

import "./ERC4626.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./ILiquidityPool.sol";
import "./IRewards.sol";
import "./UniswapV2Router02.sol";
import "./Ownable.sol";

/**
 * A Tokemak compatible ERC4626 vault that takes in a tAsset and auto compounds toke rewards
 * received from staking that tAsset in toke.
 */
contract TokeVault is ERC4626, Ownable {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    // required assets
    ERC20 public immutable toke;
    ERC20 public immutable tAsset;

    // tokemak contracts
    ILiquidityPool public immutable tokemakPool;
    IRewards public immutable rewards;

    // CONFIGURABLE PARAMS
    // keeper rewards: default of 1.5 Toke
    uint256 public keeperRewardAmount = 1500000000000000000;
    // max swap amount for uniswap trade. This amount can be swapped every swapCooldown hours
    uint256 public maxSwapTokens = 100000000000000000000;
    uint256 public swapCooldown = 12 hours;
    // address that gets 9% of generated yield
    address public feeReciever;

    // uniswap
    address public immutable swapRouter;
    address[] public tradePath;
    uint24 public swapPoolFee = 3000; // default 0.3%
    uint256 public lastSwapTime = 0;

    /**
     * @param _tAsset the tAsset that this vault handles
     */
    constructor(
        address _tAsset,
        address _rewards,
        address _swapRouter,
        address _feeReciever,
        address _toke,
        address[] memory _tradePath,
        string memory name,
        string memory symbol
    ) ERC4626(ERC20(_tAsset), name, symbol) {
        // erc20 representation of toke pool
        tAsset = ERC20(_tAsset);
        // pool representation of toke pool
        tokemakPool = ILiquidityPool(_tAsset);
        rewards = IRewards(_rewards);
        swapRouter = _swapRouter;
        feeReciever = _feeReciever;
        toke = ERC20(_toke);
        tradePath = _tradePath;
    }

    function beforeWithdraw(uint256 underlyingAmount, uint256) internal override {
        // no after withdraw
    }

    function afterDeposit(uint256 underlyingAmount, uint256) internal override {
        // no after deposit actions
    }

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets() public view override returns (uint256) {
        // Simply read tAsset balance. Ignore outstanding rewards
        return tAsset.balanceOf(address(this));
    }

    /**
     * @notice Claims rewards from toke
     * @dev the payload for claiming (recipient, v, r, s) must be formed off chain
     */
    function claim(
        IRewards.Recipient memory recipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // claim toke rewards
        rewards.claim(recipient, v, r, s);

        // reward the claimer for executing this claim - rewarded in reward tokens
        toke.safeTransfer(msg.sender, keeperRewardAmount);
    }

    /**
     * @notice harvests on hand rewards for the underlying asset and reinvests
     * @dev limits the amount of slippage that it is willing to accept.
     */
    function compound() public {
        // validate we can compound
        require(canCompound(), "not ready to compound");

        // find the asset the tokemak pool is settled in
        ERC20 underlying = ERC20(tokemakPool.underlyer());

        // cap at max toke swap amount
        uint256 tokeBal = toke.balanceOf(address(this));
        uint256 swapAmount = tokeBal >= maxSwapTokens ? maxSwapTokens : tokeBal;

        // sell toke rewards earned for underlying asset
        // dealing with slippage
        // option 2: have a max sale amount with a cooldown period?
        // note: slippage here will only ever be upward pressure on the tAsset but you still want to optimise this
        toke.safeApprove(swapRouter, swapAmount);

        // approve the router
        UniswapV2Router02 router = UniswapV2Router02(swapRouter);

        // swap from toke to underlying asset to deposit back into toke
        router.swapExactTokensForTokens(swapAmount, 1, tradePath, address(this), block.timestamp + 30 minutes);

        // deposit all of underlying back into toke and take service fee
        uint256 underlyingBal = underlying.balanceOf(address(this));
        // deposit 90% back into toke, take 1% keeper fee, take 9% service fee.
        // todo: This could be configurable in the future
        uint256 depositAmount = underlyingBal - (underlyingBal / 10); // 90%
        uint256 keeperFee = underlyingBal / 100;
        uint256 serviceFee = underlyingBal - depositAmount - keeperFee;

        // mark this as swap time
        lastSwapTime = block.timestamp;

        // transfer all the tokes
        underlying.safeApprove(address(tokemakPool), depositAmount);
        tokemakPool.deposit(depositAmount);
        underlying.safeTransfer(feeReciever, serviceFee);
        underlying.safeTransfer(msg.sender, keeperFee);
    }

    /**
     * @notice checks if the compound function can be called
     * @return can compound be called
     */
    function canCompound() public view returns (bool) {
        // has enough time passed?
        bool hasTimePassed = block.timestamp > lastSwapTime + swapCooldown;
        bool hasBalance = toke.balanceOf(address(this)) != 0;
        return hasTimePassed && hasBalance;
    }

    /**
     * @notice THIS SAFETY FUNCTION IS ONLY FOR TESTING IN PROD
     * @dev remove once contract is audited and verified. This allows the owner to
     * withdraw any asset to themself. USE WITH CAUTION
     */
    function withdrawAssets(address asset, uint256 amount) external onlyOwner {
        ERC20(asset).safeTransfer(owner(), amount);
    }

    /**
     * @notice allows the keeper reward to be modified
     */
    function setKeeperReward(uint256 newKeeperReward) external onlyOwner {
        keeperRewardAmount = newKeeperReward;
    }

    /**
     * @notice allows the max swap tokens to be modified
     */
    function setMaxSwapTokens(uint256 newMaxSwapTokens) external onlyOwner {
        maxSwapTokens = newMaxSwapTokens;
    }

    /**
     * @notice allows the max swap tokens to be modified
     */
    function setSwapCooldown(uint256 newSwapCooldown) external onlyOwner {
        swapCooldown = newSwapCooldown * 1 hours;
    }

    function setFeeReciever(address newFeeReciever) external onlyOwner {
        feeReciever = newFeeReciever;
    }
}
