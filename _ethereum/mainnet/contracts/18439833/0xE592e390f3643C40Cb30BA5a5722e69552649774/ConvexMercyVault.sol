// SPDX-License-Identifier: MercyDAO

/*
   ...     ..      ..                                                           ....                                  
  x*8888x.:*8888: -"888:                                       ..            .xH888888Hx.                              
 X   48888X `8888H  8888                 .u    .              @L           .H8888888888888:                       u.   
X8x.  8888X  8888X  !888>       .u     .d88B :@8c        .   9888i   .dL   888*"""?""*88888X         u      ...ue888b  
X8888 X8888  88888   "*8%-   ud8888.  ="8888f8888r  .udR88N  `Y888k:*888. 'f     d8x.   ^%88k     us888u.   888R Y888r 
'*888!X8888> X8888  xH8>   :888'8888.   4888>'88"  <888'888k   888E  888I '>    <88888X   '?8  .@88 "8888"  888R I888> 
  `?8 `8888  X888X X888>   d888 '88%"   4888> '    9888 'Y"    888E  888I  `:..:`888888>    8> 9888  9888   888R I888> 
  -^  '888"  X888  8888>   8888.+"      4888>      9888        888E  888I         `"*88     X  9888  9888   888R I888> 
   dx '88~x. !88~  8888>   8888L       .d888L .+   9888        888E  888I    .xHHhx.."      !  9888  9888  u8888cJ888  
 .8888Xf.888x:!    X888X.: '8888c. .+  ^"8888*"    ?8888u../  x888N><888'   X88888888hx. ..!   9888  9888   "*888*P"   
:""888":~"888"     `888*"   "88888%       "Y"       "8888P'    "88"  888   !   "*888888888"    "888*""888"    'Y"      
    "~'    "~        ""       "YP'                    "P'            88F          ^"***"`       ^Y"   ^Y'              
                                                                    98"                                                
                                                                  ./"                                                  
                                                                 ~`                                                    
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ICVXRewardPool.sol";
import "./ISwapInterfaces.sol";

/**
 * @title ConvexMercyVault
 * @author Drac
 * @dev A yield vault designed to provide liquidity to Convex Finance, disposing $CVX staking rewards for a specified token
 * When users deposit, collateral is locked for a 1 day epoch - rewards cannot be claimed until the epoch has passed
 */

struct CurveSwapParams {
    address[11] route;
    uint256[5][5] swapParams;
    address[5] pools;
    uint16 sellSlippage;
}

contract ConvexMercyVault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using SafeERC20 for IERC20;

    CurveSwapParams curveSwap;

    bool private swapParamsSet;
    bool private coreAddressesSet;

    address private feeReceiver;
    address private wrappedNative;
    address private uniswapRouter;
    address private curveRouter;
    address private immutable supplyToken;
    address private immutable disposeToken;
    address private immutable accrualToken;
    address private immutable targetStakingPool;

    bool public vaultActive;
    bool public harvestPaused;
    bool public emergencyWithdraw;
    uint8 private immutable _decimals;
    uint16 private buySlippage;
    uint16 private vaultFee = 1000;
    uint16 private callerFee = 100;
    uint16 private constant DENOMINATOR = 10_000;
    uint256 private constant MAX_INT = 2 ** 256 - 1;
    uint256 public constant duration = 1 days;

    uint256 public finishAt;
    uint256 public updatedAt;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public entryTime;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    /// @dev emits when owner adds additional rewards to the staking pool

    event BoostRewards(address indexed from, uint256 indexed amount);

    /// @dev emits when owner sets core addresses for swapping function

    event Deposit(address indexed from, uint256 indexed amount);

    /// @dev emits when a user triggers an emergency withdrawal only after admin has triggered emergency withdrawals

    event EmergencyWithdraw(address indexed to, uint256 indexed amount);

    /// @dev emits when the harvest function is paused due to unforseen issues in the swap

    event HarvestPaused(uint256 indexed timestamp);

    /// @dev emits when a new vault fee reciever address is set

    event NewRewardPeriod(uint256 indexed finishes, uint256 indexed rewardAmount, uint256 indexed rewardRate);

    /// @dev emits when vault fees are altered by the owner

    event NewVaultFeesSet(uint16 indexed newVaultFee, uint16 indexed newCallerFee);

    /// @dev emits when a user deposits and mints shares of the vault

    event SharesMinted(address indexed to, uint256 indexed amount);

    /// @dev emits when a user withdraws liquidity from the vault, burning their shares of the vault

    event SharesBurned(address indexed from, uint256 indexed amount);

    /// @dev emits when owner sets swap params for the curve trade route

    event SwapParamsSet(address[11] curveDisposalRoute, uint256[5][5] curveDisposalSwapParams, uint16 curveDisposalSellSlippage, uint16 uniswapBuySlippage);

    /// @dev emits when a user claims rewards

    event RewardsClaimed(address indexed to, uint256 indexed amount);

    /// @dev emits when the _executeSwap function is executed, harvesting rewards for the next reward period

    event RewardsAccrued(uint256 indexed rewardsAccrued);

    /// @dev emits when a user withdraws liquidity from the vault

    event Withdrawal(address indexed to, uint256 indexed amount);

    error CoreAddressesNotYetSet();
    error CoreAddressesCannotBeZeroAddress();
    error InsufficientBalance();
    error MinimumTenureNotMet();
    error UnauthorisedAssetTransfer();
    error SwapParamsNotYetSet();
    error ValueExceedsMaximum();
    error VaultNotActive();

    constructor(
        string memory _vaultTokenName,
        string memory _vaultSymbol,
        address _userSuppliesThisToken,
        address _targetStakingPoolAddressToDepositTheSupplyToken,
        address _vaultEarnsAndDisposesThisToken,
        address _vaultBuysThisTokenAndDistributesAsReward
    ) ERC20(_vaultTokenName, _vaultSymbol) {
        supplyToken = _userSuppliesThisToken;
        disposeToken = _vaultEarnsAndDisposesThisToken;
        accrualToken = _vaultBuysThisTokenAndDistributesAsReward;
        targetStakingPool = _targetStakingPoolAddressToDepositTheSupplyToken;
        _decimals = ERC20(supplyToken).decimals();
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }

        if (finishAt < block.timestamp && !harvestPaused) {
            uint256 proceedsLessFee = _executeSwap();
            _notifyRewardAmount(proceedsLessFee);
        }

        _;
    }

    /**
     * @dev This function allows the admin to withdraw from the staking pool in an emergency.
     * It is only callable by the owner of the contract.
     * The function will withdraw staked liquidity tokens to the contract
     * The emergencyWithdraw variable is set to true, userEmergencyWithdraw() function now callable
     * vaultActive is set to false to prevent further deposits once emergency withdraw has been called
     * Emits an AdminEmergencyWithdraw event upon successful withdrawal.
     */

    function adminEmergencyWithdraw() external onlyOwner {
        ICVXRewardPool(targetStakingPool).withdrawAll(true);
        emergencyWithdraw = true;
        vaultActive = false;
    }

    /**
     * @dev Boosts the rewards by transferring a specified amount of the accrual token to the vault.
     * @param amount The amount of the accrual token to be transferred and used for boosting the rewards.
     * Emits the BoostRewards event to notify listeners about the boosted rewards.
     */

    function boostRewards(uint256 amount) external onlyOwner {
        IERC20(accrualToken).safeTransferFrom(msg.sender, address(this), amount);
        _notifyRewardAmount(amount);
        emit BoostRewards(msg.sender, amount);
    }

    /** @dev this function claims pending rewards from the vault for the depositor
     * It is non-reentrant for safety against re-entrancy attacks.
     * Rewards may only be claimed once a minimum duration has passed from the time of deposit.
     * Emits an RewardsClaimed event upon successful claim
     */

    function claim() external nonReentrant updateReward(msg.sender) {
        if (entryTime[msg.sender] + duration > block.timestamp) {
            revert MinimumTenureNotMet();
        }

        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20(accrualToken).safeTransfer(msg.sender, reward);
            emit RewardsClaimed(msg.sender, reward);
        }
    }

    /**
     * @dev This function allows users to deposit tokens into the vault.
     * @param shares The amount of the supply token to deposit to the vault
     * To be issued as shares in the vault
     * It is non-reentrant for safety against re-entrancy attacks.
     * Emits a Deposit event upon successful deposit.
     */

    function deposit(uint256 shares) external nonReentrant {
        if (!vaultActive) {
            revert VaultNotActive();
        }

        if (totalSupply() == 0) {
            finishAt = block.timestamp + duration;
        } else {
            update();
        }

        IERC20(supplyToken).safeTransferFrom(msg.sender, address(this), shares);

        emit Deposit(msg.sender, shares);

        ICVXRewardPool(targetStakingPool).stake(shares);
        entryTime[msg.sender] = block.timestamp;

        _mint(msg.sender, shares);
        emit SharesMinted(msg.sender, shares);
    }

    /**
     * @dev Recovers ERC20 tokens sent to this contract, excluding supplyToken.
     * @param tokenAddress The address of the ERC20 token to recover.
     * @param tokenAmount The amount of tokens to recover.
     * Emits a Recover event upon successful recovery of ERC20s
     */

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        if (tokenAddress == address(targetStakingPool)) {
            revert UnauthorisedAssetTransfer();
        }

        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

    /**
     * @dev This function allows the owner to alter the vault state
     * It is only callable by the owner of the contract.
     * reverts will trigger in the event swapParams or coreAddresses have not been set
     * deposits will be enabled when vaultActive == true
     * deposits will be disabled when vaultActive == false
     * @param state takes a boolean to set either of the above states
     */

    function initialiseVault(bool state) external onlyOwner {
        if (!swapParamsSet) {
            revert SwapParamsNotYetSet();
        }

        if (!coreAddressesSet) {
            revert CoreAddressesNotYetSet();
        }

        vaultActive = state;
    }

    /**
     * @dev Pauses or unpauses the harvest functionality.
     * @param state The new state of the harvest functionality (true for paused, false for unpaused).
     * Emits the HarvestPaused event to notify listeners about the change in harvest pause state.
     */

    function pauseHarvest(bool state) external onlyOwner {
        harvestPaused = state;
        emit HarvestPaused(block.timestamp);
    }

    /**
     * @dev sets addresses for interface interactions during the _executeSwap function
     * Can be updated in future if addresses or liquidity is migrated
     * @param _wrappedNative  the wrapped native gas token for the network the vault is deployed on
     * @param _curveRouter the curve router address for the network the vault is deployed on
     * @param _uniswapRouter  the uniswap router address for the network the vault is deployed on
     * @param _feeReceiver the address for fees from the vault to be sent to
     * Emits the CoreAddressesSet event to notify listeners the core addresses have been set
     */

    function setCoreAddresses(address _wrappedNative, address _curveRouter, address _uniswapRouter, address _feeReceiver) external onlyOwner {
        if (_wrappedNative == address(0) || _curveRouter == address(0) || _uniswapRouter == address(0) || _feeReceiver == address(0)) {
            revert CoreAddressesCannotBeZeroAddress();
        }

        wrappedNative = _wrappedNative;
        curveRouter = _curveRouter;
        uniswapRouter = _uniswapRouter;
        feeReceiver = _feeReceiver;
        coreAddressesSet = true;
        _batchInitialApprovals();
    }

    /**
     * @dev Sets the vault fees for the harvest functionality.
     * @param newVaultFee The new vault fee percentage to be set.
     * @param newCallerFee The new caller fee percentage to be set.
     * if the combined values exceed the DENOMINATOR, the call is reverted to safeguard against misconfiguration
     * Emits the NewVaultFeesSet event to notify listeners about the updated vault fees.
     */

    function setFees(uint16 newVaultFee, uint16 newCallerFee) external onlyOwner {
        if (newVaultFee + newCallerFee > DENOMINATOR) {
            revert ValueExceedsMaximum();
        }
        vaultFee = newVaultFee;
        callerFee = newCallerFee;
        emit NewVaultFeesSet(newVaultFee, newCallerFee);
    }

    /**
     * @dev Sets the address of the fee receiver.
     * @param newFeeReceiver The new address to be set as the fee receiver.
     * Emits the NewFeeReceiverSet event to notify listeners about the updated fee receiver address.
     */

    function setFeeReciever(address newFeeReceiver) external onlyOwner {
        feeReceiver = newFeeReceiver;
    }

    /**
     * @dev Sets the swap parameters for the curve disposal and Uniswap buy operations.
     * @param curveDisposalRoute The array of addresses representing the swap route for the curve disposal.
     * @param curveDisposalSwapParams The array of arrays representing the swap parameters for the curve disposal.
     * @param curveDisposalPools The array of addresses representing the pools for the curve disposal.
     * @param curveDisposalSellSlippage The sell slippage percentage for the curve disposal.
     * @param uniswapBuySlippage The buy slippage percentage for the Uniswap buy operation.
     * It is only callable by the owner of the contract.
     * Emits the SwapParamsSet event to notify listeners about the updated swap parameters.
     */

    function setSwapParams(
        address[11] calldata curveDisposalRoute,
        uint256[5][5] calldata curveDisposalSwapParams,
        address[5] calldata curveDisposalPools,
        uint16 curveDisposalSellSlippage,
        uint16 uniswapBuySlippage
    ) external onlyOwner {
        curveSwap.route = curveDisposalRoute;
        curveSwap.swapParams = curveDisposalSwapParams;
        curveSwap.pools = curveDisposalPools;
        curveSwap.sellSlippage = curveDisposalSellSlippage;
        buySlippage = uniswapBuySlippage;
        swapParamsSet = true;
        emit SwapParamsSet(curveDisposalRoute, curveDisposalSwapParams, curveDisposalSellSlippage, uniswapBuySlippage);
    }

    /**
     * @dev This function allows users to withdraw their tokens from the vault.
     * @param shares The amount of shares to withdraw from the vault.
     * It is non-reentrant for safety against re-entrancy attacks.
     * Rewards may only be claimed once a minimum duration has passed from the time of deposit.
     * maxRedemption() function checks to ensure withdrawal amount is able to be withdrawn from liquidity pool
     * If withdrawal amount exceeds cap, only the cap is withdrawn
     * Emits a Withdrawal event upon successful withdrawal.
     */

    function withdraw(uint256 shares) external nonReentrant updateReward(msg.sender) {
        if (shares > balanceOf(msg.sender)) revert InsufficientBalance();
        if (emergencyWithdraw) {
            _userEmergencyWithdraw();
            return;
        }
        if (entryTime[msg.sender] + duration > block.timestamp) revert MinimumTenureNotMet();

        _burn(msg.sender, shares);
        emit SharesBurned(msg.sender, shares);

        ICVXRewardPool(targetStakingPool).withdraw(shares, false);

        IERC20(supplyToken).safeTransfer(msg.sender, shares);

        emit Withdrawal(msg.sender, shares);
    }

    /**
     * @dev see ERC20-decimals()
     * Function overrides default ERC20 decimals function hardcoded value of 18 to return declared decimal value
     */

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Updates the reward for the caller and performs necessary calculations.
     * This function is meant to be called by the participants to update their rewards.
     * Emits the RewardUpdated event to notify listeners about the updated reward.
     */

    function update() internal updateReward(msg.sender) {}

    function earned(address account) public view returns (uint) {
        return ((balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalSupply();
    }

    function _disposeRewardsViaCurve() internal {
        uint256 inAmount = IERC20(disposeToken).balanceOf(address(this));
        uint256 amountOut = ICurveRouterV1(curveRouter).get_dy(curveSwap.route, curveSwap.swapParams, inAmount, curveSwap.pools);
        uint256 amountOutMin = (amountOut * (DENOMINATOR - curveSwap.sellSlippage)) / DENOMINATOR;
        ICurveRouterV1(curveRouter).exchange(curveSwap.route, curveSwap.swapParams, inAmount, amountOutMin, curveSwap.pools, address(this));
    }

    function _batchInitialApprovals() internal {
        IERC20(supplyToken).safeApprove(targetStakingPool, MAX_INT);
        IERC20(disposeToken).safeApprove(curveRouter, MAX_INT);
        IERC20(wrappedNative).safeApprove(uniswapRouter, MAX_INT);
    }

    function _buyViaUniswap(uint256 inAmount) internal returns (uint256 proceeds) {
        address[] memory swapPath = new address[](2);
        swapPath[0] = wrappedNative;
        swapPath[1] = accrualToken;
        uint256[] memory amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(inAmount, swapPath);
        uint256 amountOutMin = (amountOut[0] * (DENOMINATOR - buySlippage)) / DENOMINATOR;
        uint256[] memory outputAmounts = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(inAmount, amountOutMin, swapPath, address(this), (block.timestamp + 120));
        return (outputAmounts[swapPath.length - 1]);
    }

    function _executeSwap() internal returns (uint256 accruedRewards) {
        _harvestRewards();
        _disposeRewardsViaCurve();
        uint256 proceedsLessFee = _takeVaultFee(tx.origin);
        accruedRewards = _buyViaUniswap(proceedsLessFee);
        emit RewardsAccrued(accruedRewards);
        return (accruedRewards);
    }

    function _harvestRewards() internal returns (uint256 accruedRewards) {
        ICVXRewardPool(targetStakingPool).getReward(address(this), true, false);
        return (accruedRewards = IERC20(disposeToken).balanceOf(address(this)));
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    function _notifyRewardAmount(uint256 amount) internal {
        if (block.timestamp > finishAt) {
            rewardRate = amount / duration;
        } else {
            uint256 remainingTime = finishAt - block.timestamp;
            uint256 leftoverTokens = remainingTime * rewardRate;
            rewardRate = (amount + leftoverTokens) / duration;
        }

        updatedAt = block.timestamp;
        finishAt = block.timestamp + duration;
        emit NewRewardPeriod((block.timestamp + duration), amount, rewardRate);
    }

    function _takeVaultFee(address caller) internal returns (uint256 proceedsLessFee) {
        uint256 proceedsBalance;
        proceedsBalance = IERC20(wrappedNative).balanceOf(address(this));
        uint256 vaultFeePayable = (proceedsBalance * vaultFee) / DENOMINATOR;
        IERC20(wrappedNative).safeTransfer(feeReceiver, vaultFeePayable);
        proceedsBalance = IERC20(wrappedNative).balanceOf(address(this));
        uint256 callerFeePayable = (proceedsBalance * callerFee) / DENOMINATOR;
        IERC20(wrappedNative).safeTransfer(caller, callerFeePayable);
        proceedsLessFee = IERC20(wrappedNative).balanceOf(address(this));
        return (proceedsLessFee);
    }

    function _userEmergencyWithdraw() internal {
        uint256 shares = balanceOf(msg.sender);
        _burn(msg.sender, shares);

        ERC20(supplyToken).safeTransfer(msg.sender, shares);

        emit EmergencyWithdraw(msg.sender, shares);
    }
}
