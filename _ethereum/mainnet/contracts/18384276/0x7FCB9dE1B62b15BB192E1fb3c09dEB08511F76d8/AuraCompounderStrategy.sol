// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IAuraRouter.sol";
import "./IStrategy.sol";
import "./IAuraLocker.sol";
import "./IDelegateRegistry.sol";
import "./ITokenSwapper.sol";
import "./IRewardDistributor.sol";
import "./IWeth.sol";
import "./Errors.sol";
import "./FixedPointMathLib.sol";
import "./IAuraBribe.sol";

contract AuraCompounderStrategy is IStrategy, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using FixedPointMathLib for uint256;

    event OnBribeNotify(address[] rewardTokens, uint256[] rewardAmounts);
    event Relock(uint256 amount);

    struct IncentiveSettings {
        address jAURAVoter;
        address jonesTreasury;
        address auraTreasury;
        address withdrawRecipient;
        address jAuraLPAddress;
        uint64 jonesTreasuryPercent; // denominator 10000
        uint64 auraTreasuryPercent; // denominator 10000
        uint64 withdrawPercent; // denominator 10000
        uint64 bribesPercent; // denominator 10000
    }

    IAuraRouter public router;
    IAuraBribe public constant auraBribe = IAuraBribe(0x642c59937A62cf7dc92F70Fd78A13cEe0aa2Bd9c);
    address private constant gov = 0x2a88a454A7b0C29d36D5A121b7Cf582db01bfCEC;
    address public vault;
    address public keeper;
    IncentiveSettings public incentiveSettings;

    uint256 private lsdBalance;

    bool private isClaimingBribes;
    bool private shouldRelock;

    mapping(address => mapping(address => ITokenSwapper)) public swappers; // tokenIn => tokenOut => swapper

    // constant variables
    IERC20Upgradeable public constant WETH = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable public constant AURA = IERC20Upgradeable(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20Upgradeable public constant AURABAL = IERC20Upgradeable(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);
    IAuraLocker public constant LOCKER = IAuraLocker(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);
    IDelegateRegistry public constant SNAPSHOT = IDelegateRegistry(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);
    uint256 public constant DENOMINATOR = 10000;
    ITokenSwapper public constant inchSwapper = ITokenSwapper(0x1111111254fb6c44bAC0beD2854e76F90643097d);

    ITokenSwapper public defaultSwapper;

    IAuraBribe public newAuraBribe;

    // Fallback function to receive ETH and wrap it into WETH.
    receive() external payable {
        address WETH_ADDRESS = address(WETH);

        assembly {
            // ---------------------------------------------------
            // 0. The value of the call
            // ---------------------------------------------------
            // callvalue = msg.value
            let _amount := callvalue()

            // ---------------------------------------------------
            // 1. The Function Selector
            // ---------------------------------------------------
            // 0x2e1a7d4d (first 4 bytes of the keccak-256 hash of the string "deposit()")
            let functionSelector := 0x2e1a7d4d

            // ---------------------------------------------------
            // 2. The Memory Layout
            // ---------------------------------------------------
            // Memory is divided into slots, and each slot is 32 bytes (256 bits).
            // The free memory pointer always points to the next available slot in memory.
            // mload(0x40) retrieves the current free memory pointer.
            let ptr := mload(0x40)

            // ptr now points here (let's call this position A):
            // A: [            ???            ]
            // As you can see, it's uninitialized memory, indicated by ???.

            // ---------------------------------------------------
            // 3. Creating Calldata
            // ---------------------------------------------------
            // Calldata for our call needs to be the function selector.
            // We store it at the position ptr (position A).
            mstore(ptr, functionSelector)

            // Memory now looks like this:
            // A: [     functionSelector     ]

            // But, Ethereum is big-endian, which means the most significant byte is stored at the smallest address.
            // So, our memory looks like this in a more detailed view:
            // A: [  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            //      00 00 00 00 00 00 00 00 00 00 00 00 2e 1a 7d 4d  ]

            // ---------------------------------------------------
            // 4. Making the External Call
            // ---------------------------------------------------
            // We are now ready to make the external call to the WETH contract.
            // call(gas, to, value, inOffset, inSize, outOffset, outSize) is the structure.

            // gas() - Remaining gas for the transaction.
            // WETH_ADDRESS - The address of the WETH contract.
            // _amount - The ether value we're sending with the call.
            // add(functionSelector, 0x20) - Where our calldata starts in memory.
            // 0x04 - Size of our calldata (4 bytes for the function selector).
            // 0 - We don't expect any return data, so outOffset is 0.
            // 0 - We don't expect any return data, so outSize is 0.
            let result := call(gas(), WETH_ADDRESS, _amount, add(ptr, 0x20), 0x04, 0, 0)

            // Check if the call was successful, if not revert.
            switch iszero(result)
            case 1 {
                // Store the error message in memory.
                let err := "WETH: FAIL"

                mstore(ptr, err)

                // Revert with our custom error message.
                revert(ptr, 10) // "WETH: FAIL" has 10 characters.
            }
        }
    }

    function initialize(address _router, address _vault, address _keeper, IncentiveSettings memory _incentiveSettings)
        external
        initializer
    {
        if (msg.sender != gov) {
            revert Errors.notOwner();
        }

        __Ownable_init();
        __ReentrancyGuard_init();

        router = IAuraRouter(_router);
        vault = _vault;
        keeper = _keeper;
        incentiveSettings = _incentiveSettings;
        AURA.safeApprove(address(LOCKER), type(uint256).max);
        shouldRelock = true;
    }

    /**
     * @notice Gets the total amount of locked and unlocked AURA assets.
     * @return The total amount of locked and unlocked AURA assets.
     */
    function totalAssets() external view override returns (uint256) {
        IAuraLocker.Balances memory balances = LOCKER.balances(address(this));
        unchecked {
            return balances.locked + AURA.balanceOf(address(this));
        }
    }

    /**
     * @notice Returns the total assets of LSD Vault`.
     */
    function totalAssetsLSD() external view returns (uint256) {
        return lsdBalance;
    }

    /**
     * @notice Returns the total assets of no tokenized Vault`.
     */
    function totalNoTokenizedAssets() external view returns (uint256) {
        (uint256 noTokenzedBalance,) = vaultsPosition();
        return noTokenzedBalance;
    }

    /**
     * @notice Returns the recipient and percent values from `incentiveSettings`.
     * @return recipient Address of the incentive receiver
     * @return percent Retention percentage
     */
    function withdrawRetention() external view returns (address recipient, uint64 percent) {
        return (incentiveSettings.withdrawRecipient, incentiveSettings.withdrawPercent);
    }

    /**
     * @notice Return Vaults balances
     * @return No tokenized Vault Balance
     * @return LSD Vault balance
     */
    function vaultsPosition() public view returns (uint256, uint256) {
        IAuraLocker.Balances memory balances = LOCKER.balances(address(this));
        unchecked {
            uint256 auraBalance = balances.locked + AURA.balanceOf(address(this));

            return (auraBalance - lsdBalance, lsdBalance);
        }
    }

    /**
     * @notice Return Current Vaults portion in Strategy
     * @return No tokenized Vault Portion
     * @return LSD Vault Portion
     */
    function vaultsCurrentPosition() public view returns (uint256, uint256) {
        uint256 strategyBalance = AURA.balanceOf(address(this));

        (uint256 ntBalance, uint256 tBalance) = vaultsPosition();

        uint256 noTokenizedPortion = (ntBalance * strategyBalance) / (ntBalance + tBalance);
        unchecked {
            uint256 tokenizedPortion = strategyBalance > 0 ? strategyBalance - noTokenizedPortion : 0;

            return (noTokenizedPortion, tokenizedPortion);
        }
    }

    /**
     * @notice Allows the vaults to relock AURA in the contract.
     */
    function deposit(uint256 auraAmount, bool tokenized) external nonReentrant {
        _onlyRouter();

        if (tokenized) {
            lsdBalance = lsdBalance + auraAmount;
        }
    }

    function withdraw(address user, uint256 amount, bool tokenized) external nonReentrant returns (uint256) {
        _onlyRouter();

        // Get current AURA balance
        uint256 balNow = AURA.balanceOf(address(this));

        // If we dont have enough AURA
        if (balNow < amount) {
            // Check how much we can get by process unlocks
            (, uint256 unlockable,,) = LOCKER.lockedBalances(address(this));

            // If still not enough, revert
            if (unlockable + balNow < amount) revert Errors.InsufficientWithdraw();

            LOCKER.processExpiredLocks(false);
        }

        if (tokenized) {
            unchecked {
                lsdBalance = lsdBalance > amount ? lsdBalance - amount : 0;
            }
        }

        if (incentiveSettings.withdrawPercent > 0 && incentiveSettings.withdrawRecipient != address(0)) {
            uint256 withdrawalRetention = (amount * incentiveSettings.withdrawPercent) / DENOMINATOR;

            uint256 jonesRetention = (withdrawalRetention * 2) / 3;

            AURA.safeTransfer(incentiveSettings.withdrawRecipient, jonesRetention);

            unchecked {
                //`withdrawalRetention` is always less than `amount` so it should never overflow
                amount -= withdrawalRetention;
            }
        }

        AURA.safeTransfer(user, amount);

        return amount;
    }

    function afterRehyphotecate(uint256 _auraAmount, bool _tokenized) external {
        _onlyRouter();

        if (!_tokenized) {
            lsdBalance = lsdBalance + _auraAmount;
        }
    }

    /**
     * @notice Allows the keeper address to harvest auraBAL reward from AuraLocker.
     * @param autoCompoundAll If true, the rewards will be automatically compounded into AURA.
     * @param minAmountOut keeper calculates both assets price and amounts and inputs the desired value.
     */
    function harvest(bool autoCompoundAll, uint256 minAmountOut) external {
        _onlyKeeper();

        uint256 balanceBefore = AURABAL.balanceOf(address(this));
        // Claim auraBAL from AuraLocker
        LOCKER.getReward(address(this));

        // Calculate how much was harvested in rewards, revert if no new rewards
        unchecked {
            uint256 amountEarned = AURABAL.balanceOf(address(this)) - balanceBefore;
            if (amountEarned == 0) {
                revert Errors.NoReward();
            }

            if (autoCompoundAll) {
                // Swap auraBAL to AURA
                processEarned(address(AURABAL), amountEarned, address(AURA), minAmountOut, "");
            }
        }
    }

    function relockExpiredLocks(bool _shouldRelock) external {
        _onlyKeeper();

        LOCKER.processExpiredLocks(_shouldRelock);
    }

    /**
     * @notice Allows the keeper address to claim rewards from the hiddenHandDistributor contract and process them accordingly. OnBribeNotify is emitted with the claimed reward tokens and amounts.
     * @param hiddenHandDistributor The contract that will be used to claim rewards.
     * @param _claims An array of claims to be made with the hiddenHandDistributor contract.
     */
    function claimHiddenHand(IRewardDistributor hiddenHandDistributor, IRewardDistributor.Claim[] calldata _claims)
        external
        nonReentrant
    {
        _onlyKeeper();

        uint256 numClaims = _claims.length;

        // Track token balances before bribes claim
        uint256[] memory beforeBalance = new uint256[](numClaims);
        address[] memory rewardTokens = new address[](numClaims);
        uint256 i;
        for (; i < numClaims;) {
            (rewardTokens[i],,,) = hiddenHandDistributor.rewards(_claims[i].identifier);
            beforeBalance[i] = IERC20Upgradeable(rewardTokens[i]).balanceOf(address(this));
            //++i should never overflow since it will always be less than the length of the _claims array
            unchecked {
                ++i;
            }
        }

        (uint256 ntBalance, uint256 tBalance) = vaultsPosition();

        // Claim bribes
        isClaimingBribes = true;
        hiddenHandDistributor.claim(_claims);
        // Update bribe field for token receive lock
        delete isClaimingBribes;
        i = 0;

        uint256[] memory rewardAmounts = new uint256[](numClaims);
        for (; i < numClaims;) {
            rewardAmounts[i] = IERC20Upgradeable(rewardTokens[i]).balanceOf(address(this)) - beforeBalance[i];

            // Check if AURA earned
            if (rewardTokens[i] == address(AURA) && rewardAmounts[i] > 0) {
                _processAuraEarned(rewardAmounts[i], ntBalance, tBalance);
            }

            unchecked {
                //++j should never overflow since it will always be less than the length of the _claims array
                ++i;
            }
        }

        emit OnBribeNotify(rewardTokens, rewardAmounts);
    }

    /**
     * @notice Processes an earned token amount and swaps it for `tokenOut` token.
     * @param tokenIn The address of the input token contract.
     * @param amountIn The amount of the input token to be transferred.
     * @param tokenOut The address of the output token contract.
     * @param minAmountOut The minimum amount of the output token to be received.
     * @param externalData External data that can be used by token swapper contracts.
     */
    function processEarned(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        bytes memory externalData // this external data can be used in token swappers to get some off-chain data (e.g. 1Inch)
    ) public nonReentrant {
        _onlyKeeper();

        if (tokenIn == address(AURA)) {
            revert Errors.InvalidTokenIn(tokenIn, address(AURA));
        }

        if (amountIn == 0 || amountIn > IERC20Upgradeable(tokenIn).balanceOf(address(this))) {
            revert Errors.InvalidAmountIn(amountIn, IERC20Upgradeable(tokenIn).balanceOf(address(this)));
        }

        ITokenSwapper tokenSwapper = getSwapper(tokenIn, tokenOut);
        if (address(tokenSwapper) == address(0)) {
            revert Errors.NoSwapper();
        }

        (uint256 ntBalance, uint256 tBalance) = vaultsPosition();

        if (tokenIn != address(AURABAL)) {
            IERC20Upgradeable(tokenIn).safeTransfer(address(tokenSwapper), amountIn);
        }

        uint256 amountOut = tokenSwapper.swap(tokenIn, amountIn, tokenOut, minAmountOut, externalData);

        if (tokenOut == address(AURA)) {
            _processAuraEarned(amountOut, ntBalance, tBalance);
        }
    }

    /**
     * @notice Processes AURA "bribes" to various recipients based on the amount of AURA earned.
     * @param auraEarned The amount of AURA earned.
     */
    function _processAuraEarned(uint256 auraEarned, uint256 ntBalance, uint256 tBalance) private {
        unchecked {
            uint256 remaining = auraEarned;
            // transfer bribe incentive to jones treasury
            if (incentiveSettings.jonesTreasury != address(0)) {
                uint256 amount = (auraEarned * incentiveSettings.jonesTreasuryPercent) / DENOMINATOR;
                if (amount > 0) {
                    AURA.safeTransfer(incentiveSettings.jonesTreasury, amount);
                    remaining -= amount;
                }
            }

            // transfer bribe to aura treasury
            if (incentiveSettings.auraTreasury != address(0)) {
                uint256 amount = (auraEarned * incentiveSettings.auraTreasuryPercent) / DENOMINATOR;
                if (amount > 0) {
                    AURA.safeTransfer(incentiveSettings.auraTreasury, amount);
                    remaining -= amount;
                }
            }

            // Update Vault Balances
            uint256 lsdEarned = (tBalance * remaining) / (tBalance + ntBalance);

            lsdBalance = lsdBalance + lsdEarned;

            // transfer bribe to jAURA/AURA pool voter
            if (incentiveSettings.jAURAVoter != address(0) && incentiveSettings.jAuraLPAddress != address(0)) {
                uint256 amount = (
                    (
                        lsdEarned * IERC20Upgradeable(vault).balanceOf(incentiveSettings.jAuraLPAddress)
                            * incentiveSettings.bribesPercent
                    ) / IERC20Upgradeable(vault).totalSupply()
                ) / DENOMINATOR;
                if (amount > 0) {
                    AURA.safeTransfer(incentiveSettings.jAURAVoter, amount);
                    lsdBalance = lsdBalance - amount;
                }
            }
        }
    }

    /**
     * @notice Allows the keeper address to claim rewards from the hiddenHandDistributor contract on L2s and not go through the usual flow.
     * @param hiddenHandDistributor The contract that will be used to claim rewards.
     * @param _claims An array of claims to be made with the hiddenHandDistributor contract.
     */
    function L2sClaimHiddenHand(
        IRewardDistributor hiddenHandDistributor,
        IRewardDistributor.Claim[] calldata _claims,
        address rewardBridge
    ) external nonReentrant {
        _onlyKeeper();

        uint256 numClaims = _claims.length;

        // Hidden hand uses BRIBE_VAULT address as a substitute for ETH
        address hhBribeVault = hiddenHandDistributor.BRIBE_VAULT();

        // Track token balances before bribes claim
        address[] memory rewardTokens = new address[](numClaims);
        uint256 i;
        for (; i < numClaims;) {
            (rewardTokens[i],,,) = hiddenHandDistributor.rewards(_claims[i].identifier);
            //++i should never overflow since it will always be less than the length of the _claims array
            unchecked {
                ++i;
            }
        }

        // Claim bribes
        hiddenHandDistributor.claim(_claims);

        i = 0;

        // send rewards to bridge contract

        for (; i < numClaims;) {
            if (rewardTokens[i] == hhBribeVault) {
                uint256 rewards = address(this).balance;
                if (rewards > 0) {
                    IWeth(address(WETH)).deposit{value: rewards}();
                    WETH.transfer(rewardBridge, rewards);
                }
            } else {
                uint256 rewards = IERC20Upgradeable(rewardTokens[i]).balanceOf(address(this));
                if (rewards > 0) {
                    IERC20Upgradeable(rewardTokens[i]).transfer(rewardBridge, rewards);
                }
            }

            unchecked {
                //++j should never overflow since it will always be less than the length of the _claims array
                ++i;
            }
        }
    }

    /**
     * @notice Allows the strategy to relock AURA in the contract.
     */
    function relock() external nonReentrant {
        _onlyKeeper();

        _relock();
    }

    /**
     * @notice Internal processer of AURA relock.
     */
    function _relock() internal {
        if (shouldRelock) {
            uint256 currentBalance = AURA.balanceOf(address(this));
            uint256 withdrawRequests = router.totalWithdrawRequests();
            unchecked {
                if (currentBalance > withdrawRequests) {
                    uint256 relockAmount = currentBalance - withdrawRequests;
                    // relock
                    LOCKER.lock(address(this), relockAmount);

                    emit Relock(relockAmount);
                }
            }
        }
    }

    /// ----- Ownable Functions ------
    /**
     * @notice Sets the `router` contract.
     * @param _router The new `router` address.
     * @dev This function can only be called by the contract owner.
     */
    function setRouter(address _router) external onlyOwner {
        router = IAuraRouter(_router);
    }

    /**
     * @notice Sets the `vault` address.
     * @param _vault The new `_vault` address.
     * @dev This function can only be called by the contract owner.
     */
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /**
     * @notice Sets the `keeper` address.
     * @param _keeper The new `keeper` address.
     * @dev This function can only be called by the contract owner.
     */
    function setKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;
    }

    /**
     * @notice Sets the `IncentiveSettings` values.
     * @param _incentiveSettings The new `incentiveSettings` values.
     * @dev This function can only be called by the contract owner.
     */
    function setFeeSettings(IncentiveSettings memory _incentiveSettings) external onlyOwner {
        incentiveSettings = _incentiveSettings;
    }

    /**
     * @notice Sets the token swapper contract for the given token pair.
     * @param tokenIn The address of the input token contract.
     * @param tokenOut The address of the output token contract.
     * @param tokenSwapper The address of the token swapper contract.
     * @param allowance The allowance for the token swapper contract to transfer the input token.
     * @dev This function can only be called by the contract owner.
     */
    function setTokenSwapper(address tokenIn, address tokenOut, address tokenSwapper, uint256 allowance)
        external
        onlyOwner
    {
        swappers[tokenIn][tokenOut] = ITokenSwapper(tokenSwapper);

        IERC20Upgradeable(tokenIn).safeApprove(tokenSwapper, allowance);
    }

    /**
     * @notice Sets the custom allowance for the given token and token swapper contract.
     * @param token The address of the token contract.
     * @param tokenSwapper The address of the token swapper contract.
     * @param allowance The new allowance for the token swapper contract to transfer the token.
     * @dev This function can only be called by the contract owner.
     */
    function setCustomAllowance(address token, address tokenSwapper, uint256 allowance) external onlyOwner {
        IERC20Upgradeable(token).safeApprove(tokenSwapper, 0);
        if (allowance > 0) {
            IERC20Upgradeable(token).safeApprove(tokenSwapper, allowance);
        }
    }

    /// ------ Delegation ------
    /**
     * @notice Sets the delegate for the Aura Locker contract.
     * @param delegate The new delegate address.
     * @dev This function can only be called by the contract owner.
     */
    function setAuraLockerDelegate(address delegate) external onlyOwner {
        // Set delegate is enough as it will clear previous delegate automatically
        LOCKER.delegate(delegate);
    }

    /**
     * @notice Sets the delegate for the Snapshot contract with the given ID.
     * @param id The ID of the Snapshot contract.
     * @param delegate The new delegate address.
     * @dev This function can only be called by the contract owner. This cannot be used to remove delegation.
     */
    function setSnapshotDelegate(bytes32 id, address delegate) external onlyOwner {
        // Set delegate is enough as it will clear previous delegate automatically
        SNAPSHOT.setDelegate(id, delegate);
    }

    /**
     * @notice Set the address able to claim Hidden Hand rewards.
     * @param delegate The new delegate address.
     * @dev This function can only be called by the contract owner.
     */
    function forwardHiddenHandRewards(address delegate) external onlyOwner {
        // Set delegate is enough as it will clear previous delegate automatically
        auraBribe.setRewardForwarding(delegate);
    }

    /**
     * @notice Clears the snapshot delegate associated with the given snapshot ID.
     * @param id The ID of the snapshot to clear the delegate for.
     * @dev This function can only be called by the contract owner.
     */
    function clearSnapshotDelegate(bytes32 id) external onlyOwner {
        SNAPSHOT.clearDelegate(id);
    }

    function updateShouldRelock(bool _status) external onlyOwner {
        shouldRelock = _status;
    }

    function updateDefaultSwapper(ITokenSwapper _defaultSwapper) external onlyOwner {
        defaultSwapper = _defaultSwapper;
    }

    function updateNewAuraBribe(IAuraBribe _newAuraBribe) external onlyOwner {
        newAuraBribe = _newAuraBribe;
    }

    function rescueStuckEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //// ------ Access ------

    /// @notice Checks if msg.sender is router.
    /// @dev Reverts if sender != router.
    function _onlyRouter() private view {
        if (msg.sender != address(router)) {
            revert Errors.Unauthorized();
        }
    }

    /// @notice Checks if msg.sender is keeper.
    /// @dev Reverts if sender != keeper.
    function _onlyKeeper() private view {
        if (msg.sender != keeper) {
            revert Errors.Unauthorized();
        }
    }

    function _isWhitelisted(address _token) private view returns (bool) {
        return newAuraBribe.isWhitelistedToken(_token);
    }

    function getSwapper(address _tokenIn, address _tokenOut) public view returns (ITokenSwapper) {
        ITokenSwapper swapper = swappers[_tokenIn][_tokenOut];

        if (address(swapper) != address(0)) {
            return swapper;
        } else if (_isWhitelisted(_tokenIn) && address(swapper) == address(0)) {
            return defaultSwapper;
        } else {
            revert Errors.InvalidToken();
        }
    }
}
