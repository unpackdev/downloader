// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./FixedPointMathLib.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20.sol";

import "./VaultLib.sol";
import "./FeeLib.sol";

import "./IHNT20.sol";
import "./IPositionPauser.sol";
import "./IVaultShare.sol";
import "./IWhitelistManager.sol";

import "./constants.sol";
import "./enums.sol";
import "./errors.sol";
import "./types.sol";

contract BaseVault is ERC1155TokenReceiver, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IHNT20;

    /*///////////////////////////////////////////////////////////////
                        Non Upgradeable Storage
    //////////////////////////////////////////////////////////////*/

    /// @dev the contract responsible to client interactions
    address public immutable registrar;

    // the erc1155 contract that issues vault shares
    IVaultShare public immutable share;

    /// @notice **Deprecated**
    mapping(address => DepositReceipt) public _depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an hnVault token is stored
    /// This is used to determine the number of shares to be given to a user with
    /// their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public pricePerShare;

    /// @notice deposit asset amounts; round => collateralBalances[]
    /// @dev    used in determining deposit ratios and NAV calculations
    ///         should not be used as a reference to collateral used in the round
    ///         because it does not account for assets that were queued for withdrawal
    mapping(uint256 => uint256[]) public startingBalances;

    /// @notice deposit asset prices; round => CollateralPrices[]
    mapping(uint256 => uint256[]) public collateralPrices;

    /// @notice expiry of each round
    mapping(uint256 => uint256) public expiry;

    /// @notice Assets deposited into vault
    //          collaterals[0] is the primary asset, other assets are relative to the primary
    Collateral[] public collaterals;

    /// @notice Vault's round state
    VaultState public vaultState;

    /// @notice Vault's round configuration
    RoundConfig public roundConfig;

    // Oracle address to calculate Net Asset Value (for round share price)
    address public oracle;

    /// @notice Vault Pauser Contract for the vault
    address public pauser;

    /// @notice Whitelist contract, checks permissions and sanctions
    address public whitelist;

    /// @notice Fee recipient for the management and performance fees
    address public feeRecipient;

    /// @notice Role in charge of round operations
    address public manager;

    /// @notice Management fee charged on entire AUM at closeRound.
    uint256 public managementFee;

    /// @notice Performance fee charged on premiums earned in closeRound. Only charged when round takes a profit.
    uint256 public performanceFee;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Deposited(address indexed account, uint256[] amounts, uint256 round);

    event QuickWithdrew(address indexed account, uint256[] amounts, uint256 round);

    event RequestedWithdraw(address indexed account, uint256 shares, uint256 round);

    event Withdrew(address indexed account, uint256[] amounts, uint256 shares);

    event Redeem(address indexed account, uint256 share, uint256 round);

    event AddressSet(uint256 addressType, address origAddress, address newAddress);

    event FeesSet(uint256 managementFee, uint256 newManagementFee, uint256 performanceFee, uint256 newPerformanceFee);

    event RoundConfigSet(
        uint32 duration, uint8 dayOfWeek, uint8 hourOfDay, uint32 newDuration, uint8 newDayOfWeek, uint8 newHourOfDay
    );

    event CollectedFees(uint256[] vaultFee, uint256 round, address indexed feeRecipient);

    /*///////////////////////////////////////////////////////////////
                        Constructor & Initializer
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     */
    constructor(address _registrar, address _share) {
        if (_registrar == address(0)) revert BadAddress();
        if (_share == address(0)) revert BadAddress();

        registrar = _registrar;
        share = IVaultShare(_share);
    }

    /**
     * @notice Initializes the Vault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     */
    function __BaseVault_init(InitParams calldata _initParams) internal onlyInitializing {
        if (_initParams._owner == address(0)) revert VL_BadOwnerAddress();
        if (_initParams._manager == address(0)) revert VL_BadManagerAddress();
        if (_initParams._feeRecipient == address(0)) revert VL_BadFeeAddress();
        if (_initParams._oracle == address(0)) revert VL_BadOracleAddress();
        if (_initParams._pauser == address(0)) revert VL_BadPauserAddress();
        if (_initParams._performanceFee > 100 * PERCENT_MULTIPLIER || _initParams._managementFee > 100 * PERCENT_MULTIPLIER) {
            revert VL_BadFee();
        }
        if (_initParams._collaterals.length == 0) revert VL_BadCollateral();
        if (
            _initParams._roundConfig.duration == 0 || _initParams._roundConfig.dayOfWeek > 8
                || _initParams._roundConfig.hourOfDay > 23
        ) revert VL_BadDuration();

        _transferOwnership(_initParams._owner);
        __ReentrancyGuard_init_unchained();

        manager = _initParams._manager;
        oracle = _initParams._oracle;
        whitelist = _initParams._whitelist;
        feeRecipient = _initParams._feeRecipient;
        performanceFee = _initParams._performanceFee;
        managementFee = _initParams._managementFee;
        pauser = _initParams._pauser;
        roundConfig = _initParams._roundConfig;

        if (_initParams._collateralRatios.length > 0) {
            if (_initParams._collateralRatios.length != _initParams._collaterals.length) revert BV_BadRatios();

            // set the initial ratios on the first round
            startingBalances[1] = _initParams._collateralRatios;
            // set init price per share and expiry to placeholder values (1)
            pricePerShare[1] = PLACEHOLDER_UINT;
            expiry[1] = PLACEHOLDER_UINT;
        }

        for (uint256 i; i < _initParams._collaterals.length;) {
            if (_initParams._collaterals[i].addr == address(0)) revert VL_BadCollateralAddress();

            collaterals.push(_initParams._collaterals[i]);

            IHNT20(_initParams._collaterals[i].addr).approve(registrar, type(uint256).max);

            unchecked {
                ++i;
            }
        }

        vaultState.round = 1;
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _onlyOwner();
    }

    /*///////////////////////////////////////////////////////////////
                    State changing functions to override
    //////////////////////////////////////////////////////////////*/
    function _beforeCloseRound() internal virtual {}
    function _afterCloseRound() internal virtual {}

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets addresses for different settings
     * @dev Address Types:
     *      0 - Manager
     *      1 - FeeRecipient
     *      2 - Pauser
     *      3 - Whitelist
     * @param _type of address
     * @param _address is the new address
     */
    function setAddresses(uint256 _type, address _address) external virtual {
        _onlyOwner();

        if (_address == address(0)) revert BadAddress();

        _setAddress(_type, _address);
    }

    /**
     * @notice Sets fees for the vault
     * @param _managementFee is the management fee (18 decimals). ex: 2 * 10 ** 18 = 2%
     * @param _performanceFee is the performance fee (18 decimals). ex: 20 * 10 ** 18 = 20%
     */
    function setFees(uint256 _managementFee, uint256 _performanceFee) external {
        _onlyOwner();

        if (_managementFee > 100 * PERCENT_MULTIPLIER) revert BV_BadFee();
        if (_performanceFee > 100 * PERCENT_MULTIPLIER) revert BV_BadFee();

        emit FeesSet(managementFee, _managementFee, performanceFee, _performanceFee);

        managementFee = _managementFee;
        performanceFee = _performanceFee;
    }

    /**
     * @notice Sets new round Config
     * @dev this changes the expiry of options
     * @param _duration  the duration of the option
     * @param _dayOfWeek day of the week the option should expire. 0-8, 0 is sunday, 7 is sunday, 8 is wild
     * @param _hourOfDay hour of the day the option should expire. 0 is midnight
     */
    function setRoundConfig(uint32 _duration, uint8 _dayOfWeek, uint8 _hourOfDay) external {
        _onlyOwner();

        if (_duration == 0 || _dayOfWeek > 8 || _hourOfDay > 23) revert BV_BadRoundConfig();

        emit RoundConfigSet(roundConfig.duration, roundConfig.dayOfWeek, roundConfig.hourOfDay, _duration, _dayOfWeek, _hourOfDay);

        roundConfig = RoundConfig(_duration, _dayOfWeek, _hourOfDay);
    }

    /**
     * @notice Sets allowances for the registrar
     * @dev this is callable by owner,
     * @param _max is the max allowance
     */
    function setRegistrarAllowances(bool _max) external {
        _onlyOwner();

        Collateral[] memory collat = collaterals;

        for (uint256 i; i < collat.length;) {
            IHNT20(collat[i].addr).approve(registrar, _max ? type(uint256).max : 0);

            unchecked {
                ++i;
            }
        }

        share.setApprovalForAll(registrar, _max);
    }

    /*///////////////////////////////////////////////////////////////
                            Deposit & Withdraws
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits the `asset` from address added to `_subAccount`'s deposit
     * @dev this function will only work for single asset collaterals
     * @param _amount is the amount of primary asset to deposit
     */
    function deposit(uint256 _amount) external {
        _onlyRegistrar();

        vaultState.totalPending += _toUint96(_amount);
    }

    /**
     * @notice Withdraws the assets from the vault
     * @dev only pending funds can be withdrawn using this method
     * @param _amount is the pending amount of primary asset to be withdrawn
     */
    function quickWithdraw(uint256 _amount) external nonReentrant {
        _onlyRegistrar();

        vaultState.totalPending -= _toUint96(_amount);
    }

    /**
     * @notice requests a withdraw that can be processed once the round closes
     * @param _subAccount is the address of the sub account
     * @param _numShares is the number of shares to withdraw
     */
    function requestWithdrawFor(address _subAccount, uint256 _numShares) external virtual nonReentrant {
        _onlyRegistrar();

        _requestWithdraw(_subAccount, _numShares);
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Performs most administrative tasks associated with a round closing
     */
    function closeRound() external nonReentrant {
        _onlyManager();

        _beforeCloseRound();

        uint32 currentRound = vaultState.round;
        uint256 currentExpiry = expiry[currentRound];
        bool expirationExceeded = currentExpiry < block.timestamp;
        uint256[] memory balances = _getCurrentBalances();

        // only take fees after expiration exceeded, returns balances san fees
        if (expirationExceeded && currentRound > 1) balances = _processFees(balances, currentRound);

        // sets new pricePerShare, shares to mint, and asset prices for new funds being added
        _rollInFunds(balances, currentRound, currentExpiry);

        uint32 nextRound = currentRound + 1;

        // setting the balances at the start of the new round
        startingBalances[nextRound] = balances;

        // including all pending deposits into vault
        vaultState.lastLockedAmount = vaultState.lockedAmount;
        vaultState.totalPending = 0;
        vaultState.round = nextRound;

        uint256 lockedAmount = balances[0];

        // only withdraw, otherwise
        if (expirationExceeded && currentRound > 1) lockedAmount -= _completeWithdraw();

        vaultState.lockedAmount = _toUint96(lockedAmount);

        _afterCloseRound();
    }

    /**
     * @notice Helper function to save gas for writing values into storage maps.
     *         Writing 1's into maps makes subsequent writes warm, reducing the gas significantly.
     * @param _numRounds is the number of rounds to initialize in the maps
     * @param _startFromRound is the round number from which to start initializing the maps
     */
    function initRounds(uint256 _numRounds, uint32 _startFromRound) external {
        unchecked {
            uint256 i;
            uint256[] memory placeholderArray = new uint256[](collaterals.length);

            for (i; i < collaterals.length; ++i) {
                placeholderArray[i] = PLACEHOLDER_UINT;
            }

            for (i = 0; i < _numRounds; ++i) {
                uint256 index = _startFromRound;

                index += i;

                if (pricePerShare[index] > 0) revert BV_BadPPS();
                if (expiry[index] > 0) revert BV_BadExpiry();
                if (startingBalances[index].length > 0) revert BV_BadSB();
                if (collateralPrices[index].length > 0) revert BV_BadCP();

                pricePerShare[index] = PLACEHOLDER_UINT;
                expiry[index] = PLACEHOLDER_UINT;

                startingBalances[index] = placeholderArray;
                collateralPrices[index] = placeholderArray;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    function getCollaterals() external view returns (Collateral[] memory) {
        return collaterals;
    }

    function getStartingBalances(uint256 _round) external view returns (uint256[] memory) {
        return startingBalances[_round];
    }

    function getCollateralPrices(uint256 _round) external view returns (uint256[] memory) {
        return collateralPrices[_round];
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets addresses for different settings
     * @param _type of address:
     *              0 - Manager
     *              1 - FeeRecipient
     *              2 - Pauser
     *              3 - Whitelist
     * @param _address is the new address
     */
    function _setAddress(uint256 _type, address _address) internal virtual {
        AddressType addressType = AddressType(_type);

        if (AddressType.Manager == addressType) {
            emit AddressSet(_type, manager, _address);
            manager = _address;
        } else if (AddressType.FeeRecipient == addressType) {
            emit AddressSet(_type, feeRecipient, _address);
            feeRecipient = _address;
        } else if (AddressType.Pauser == addressType) {
            emit AddressSet(_type, pauser, _address);
            pauser = _address;
        } else if (AddressType.Whitelist == addressType) {
            emit AddressSet(_type, whitelist, _address);
            whitelist = _address;
        }
    }

    function _requestWithdraw(address _subAccount, uint256 _numShares) internal {
        vaultState.queuedWithdrawShares += _toUint128(_numShares);

        // storing shares in pauser for future asset(s) withdraw
        IPositionPauser(pauser).pausePosition(_subAccount, _numShares);
    }

    /**
     * @notice Process fees after expiry
     * @param _balances current balances
     * @param _currentRound current round
     */
    function _processFees(uint256[] memory _balances, uint256 _currentRound)
        internal
        virtual
        returns (uint256[] memory balances)
    {
        uint256[] memory totalFees;

        VaultDetails memory vaultDetails =
            VaultDetails(collaterals, startingBalances[_currentRound], _balances, vaultState.totalPending);

        (totalFees, balances) = FeeLib.processFees(vaultDetails, managementFee, performanceFee);

        for (uint256 i; i < totalFees.length;) {
            if (totalFees[i] > 0) {
                IHNT20(collaterals[i].addr).safeTransfer(feeRecipient, totalFees[i]);
            }

            unchecked {
                ++i;
            }
        }

        emit CollectedFees(totalFees, _currentRound, feeRecipient);
    }

    /**
     * @notice Activates pending deposits
     * @dev calculates net asset values and mints new shares at new price per share
     * @param _balances current balances
     * @param _currentRound current round
     * @param _expiry round expiry
     */
    function _rollInFunds(uint256[] memory _balances, uint256 _currentRound, uint256 _expiry) internal virtual {
        (uint256 totalNAV, uint256 pendingNAV, uint256[] memory prices) = _getNAVs(_balances, _currentRound, _expiry);

        uint256 pps = FeeLib.pricePerShare(share.totalSupply(address(this)), totalNAV, pendingNAV);

        uint256 mintShares = FeeLib.navToShares(pendingNAV, pps);

        // mints shares for all deposits, accounts can redeem at any time
        share.mint(address(this), mintShares);

        // Finalize the pricePerShare at the end of the round
        pricePerShare[_currentRound] = pps;

        // Prices at expiry, if before expiry then spot
        collateralPrices[_currentRound] = prices;
    }

    /**
     * @notice Gets net asset values
     * @dev calculates net asset values based on collaterals
     * @param _balances current balances
     * @param _round the round
     * @param _expiry round expiry
     */
    function _getNAVs(uint256[] memory _balances, uint256 _round, uint256 _expiry)
        internal
        view
        virtual
        returns (uint256 totalNAV, uint256 pendingNAV, uint256[] memory prices)
    {
        NAVDetails memory navDetails =
            NAVDetails(collaterals, startingBalances[_round], _balances, oracle, _expiry, vaultState.totalPending);

        (totalNAV, pendingNAV, prices) = FeeLib.calculateNAVs(navDetails);
    }

    /**
     * @notice Completes withdraws from a past round
     * @dev transfers assets to pauser to exclude from vault balances
     */
    function _completeWithdraw() internal virtual returns (uint256) {
        uint256 withdrawShares = uint256(vaultState.queuedWithdrawShares);

        uint256[] memory withdrawAmounts = new uint256[](1);

        if (withdrawShares != 0) {
            vaultState.queuedWithdrawShares = 0;

            // total assets transferred to pauser
            withdrawAmounts = VaultLib.withdrawWithShares(collaterals, share.totalSupply(address(this)), withdrawShares, pauser);
            // recording deposits with pauser for past round
            IPositionPauser(pauser).processVaultWithdraw(withdrawAmounts);

            // burns shares that were transferred to vault during requestWithdraw
            share.burn(address(this), withdrawShares);

            emit Withdrew(msg.sender, withdrawAmounts, withdrawShares);
        }

        return withdrawAmounts[0];
    }

    /**
     * @notice Queries total balance(s) of collateral
     * @dev used in processFees
     */
    function _getCurrentBalances() internal view virtual returns (uint256[] memory balances) {
        Collateral[] memory collats = collaterals;

        balances = new uint256[](collats.length);

        for (uint256 i; i < collats.length;) {
            balances[i] = IHNT20(collats[i].addr).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }
    }

    function _onlyManager() internal view {
        if (msg.sender != manager) revert Unauthorized();
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _onlyRegistrar() internal view {
        if (msg.sender != registrar) revert Unauthorized();
    }

    function _hasAccess(address _subAccount) internal view {
        if (msg.sender != _subAccount && msg.sender != manager) revert Unauthorized();
    }

    function _toUint96(uint256 _num) internal pure returns (uint96) {
        if (_num > type(uint96).max) revert Overflow();
        return uint96(_num);
    }

    function _toUint128(uint256 _num) internal pure returns (uint128) {
        if (_num > type(uint128).max) revert Overflow();
        return uint128(_num);
    }
}
