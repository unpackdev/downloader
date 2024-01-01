// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeCast.sol";

// inheriting contracts
import "./BaseEngine.sol";
import "./AccountCashEngine.sol";

// interfaces
import "./IMarginEngine.sol";
import "./IOracle.sol";
import "./IWhitelist.sol";

// libraries
import "./BalanceUtil.sol";
import "./ProductIdUtil.sol";
import "./TokenIdUtil.sol";
import "./UintArrayLib.sol";

// Cross margin libraries
import "./AccountUtil.sol";
import "./CrossMarginCashMath.sol";
import "./CrossMarginCashLib.sol";

// Cross margin types
import "./types.sol";
import "./errors.sol";

// global constants and types
import "./types.sol";
import "./enums.sol";
import "./constants.sol";
import "./errors.sol";

/**
 * @title   CrossMarginCashEngine
 * @author  @dsshap, @antoncoding
 * @notice  Fully collateralized margin engine
 *             Users can deposit collateral into Cross Margin and mint optionTokens (debt) out of it.
 *             Interacts with CashOptionToken to mint / burn
 *             Interacts with grappa to fetch registered asset info
 */
contract CrossMarginCashEngine is
    AccountCashEngine,
    IMarginEngine,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using AccountUtil for Position[];
    using BalanceUtil for Balance[];
    using CrossMarginCashLib for CrossMarginAccount;
    using ProductIdUtil for uint40;
    using SafeCast for uint256;
    using SafeCast for int256;
    using TokenIdUtil for uint256;

    /*///////////////////////////////////////////////////////////////
                            Immutables
    //////////////////////////////////////////////////////////////*/

    /// @dev initial chain id used in domain separator
    uint256 public immutable initialChainId;

    /// @dev oracle to handle partial margining
    IOracle public immutable oracle;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    ///@dev subAccount => CrossMarginAccount structure.
    ///     subAccount can be an address similar to the primary account, but has the last 8 bits different.
    ///     this give every account access to 256 sub-accounts
    mapping(address => CrossMarginAccount) internal accounts;

    ///@dev contract that verifies permissions
    ///     if not set allows anyone to transact
    ///     checks msg.sender on execute & batchExecute
    ///     checks recipient on payCashValue
    IWhitelist public whitelist;

    /*///////////////////////////////////////////////////////////////
                         State Variables V2
    //////////////////////////////////////////////////////////////*/

    /// @dev A bitmap of asset that are marginable
    ///      assetId => assetId masks
    mapping(uint256 => uint256) private collateralizable;

    /*///////////////////////////////////////////////////////////////
                         State Variables V3
    //////////////////////////////////////////////////////////////*/

    /// @dev initial cached domain separator
    bytes32 public initialDomainSeparator;

    /// @dev nonce for signed messages to prevent replay attacks
    ///      address => nonce
    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event CollateralizableSet(address asset0, address asset1, bool value);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(address _grappa, address _optionToken, address _oracle) BaseEngine(_grappa, _optionToken) initializer {
        // solhint-disable-next-line reason-string
        if (_oracle == address(0)) revert();

        initialChainId = block.chainid;
        oracle = IOracle(_oracle);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        // solhint-disable-next-line reason-string
        if (_owner == address(0)) revert();

        _transferOwnership(_owner);
        __ReentrancyGuard_init_unchained();

        initialDomainSeparator = _computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    function setDomainSeperator() external {
        if (initialDomainSeparator != bytes32(0)) revert();

        initialDomainSeparator = _computeDomainSeparator();
    }

    /**
     * @notice Sets the whitelist contract
     * @param _whitelist is the address of the new whitelist
     */
    function setWhitelist(address _whitelist) external {
        _checkOwner();

        whitelist = IWhitelist(_whitelist);
    }

    /**
     * @notice  sets the Collateralizable Mask for a pair of assets
     * @param _asset0 the address of the asset 0
     * @param _asset1 the address of the asset 1
     * @param _value is margin-able
     */
    function setCollateralizable(address _asset0, address _asset1, bool _value) external {
        _checkOwner();

        uint256 collateralId = grappa.assetIds(_asset0);
        uint256 mask = 1 << grappa.assetIds(_asset1);

        if (_value) collateralizable[collateralId] |= mask;
        else collateralizable[collateralId] &= ~mask;

        emit CollateralizableSet(_asset0, _asset1, _value);
    }

    /**
     * @dev check if a pair of assets are collateralizable
     */
    function isCollateralizable(address _asset0, address _asset1) external view returns (bool) {
        return _isCollateralizable(grappa.assetIds(_asset0), grappa.assetIds(_asset1));
    }

    /**
     * @dev check if a pair of assets are collateralizable
     */
    function isCollateralizable(uint8 _asset0, uint8 _asset1) external view returns (bool) {
        return _isCollateralizable(_asset0, _asset1);
    }

    /**
     * @notice batch execute on multiple subAccounts
     * @dev    check margin after all subAccounts are updated
     *         because we support actions like `TransferCollateral` that moves collateral between subAccounts
     */
    function batchExecute(BatchExecute[] calldata batchActions) external nonReentrant {
        _checkPermissioned(msg.sender);

        uint256 i;
        for (i; i < batchActions.length;) {
            address subAccount = batchActions[i].subAccount;
            ActionArgs[] calldata actions = batchActions[i].actions;

            _execute(subAccount, actions);

            // increase i without checking overflow
            unchecked {
                ++i;
            }
        }

        for (i = 0; i < batchActions.length;) {
            if (!_isAccountAboveWater(batchActions[i].subAccount)) revert BM_AccountUnderwater();

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice execute multiple actions on one subAccounts
     * @dev    check margin all actions are applied
     */
    function execute(address _subAccount, ActionArgs[] calldata actions) external override nonReentrant {
        _checkPermissioned(msg.sender);

        _execute(_subAccount, actions);

        if (!_isAccountAboveWater(_subAccount)) revert BM_AccountUnderwater();
    }

    /**
     * @notice payout to user on settlement.
     * @dev this can only triggered by Grappa, would only be called on settlement.
     * @param _asset asset to transfer
     * @param _recipient receiver
     * @param _amount amount
     */
    function payCashValue(address _asset, address _recipient, uint256 _amount) public override(BaseEngine, IMarginEngine) {
        if (_recipient == address(this)) return;

        _checkPermissioned(_recipient);

        BaseEngine.payCashValue(_asset, _recipient, _amount);
    }

    /**
     * @notice get minimum collateral needed for a margin account
     * @param _subAccount account id.
     * @return balances array of collaterals and amount (signed)
     */
    function getMinCollateral(address _subAccount) external view returns (Balance[] memory) {
        CrossMarginAccount memory account = accounts[_subAccount];
        return _getMinCollateral(account);
    }

    /**
     * @notice  move an account to someone else
     * @dev     expected to be call by account owner
     * @param _subAccount the id of subaccount to transfer
     * @param _newSubAccount the id of receiving account
     */
    function transferAccount(address _subAccount, address _newSubAccount) external {
        if (!_isPrimaryAccountFor(msg.sender, _subAccount)) revert NoAccess();

        if (!accounts[_newSubAccount].isEmpty()) revert CM_AccountIsNotEmpty();
        accounts[_newSubAccount] = accounts[_subAccount];

        delete accounts[_subAccount];
    }

    /**
     * @dev view function to get all shorts, longs and collaterals
     */
    function marginAccounts(address _subAccount)
        external
        view
        returns (Position[] memory shorts, Position[] memory longs, Balance[] memory collaterals)
    {
        CrossMarginAccount memory account = accounts[_subAccount];

        return (account.shorts, account.longs, account.collaterals);
    }

    /**
     * @notice get minimum collateral needed for a margin account
     * @param shorts positions.
     * @param longs positions.
     * @return balances array of collaterals and amount
     */
    function previewMinCollateral(Position[] memory shorts, Position[] memory longs) external view returns (Balance[] memory) {
        CrossMarginAccount memory account;

        account.shorts = shorts;
        account.longs = longs;

        return _getMinCollateral(account);
    }

    /**
     * @notice get collateral amount available after margin requirements
     * @param shorts positions.
     * @param longs positions.
     * @param collaterals balances.
     * @return addresses array of collateral
     * @return amounts array of collateral
     * @return isUnderWater boolean if NOT enough collateral (underwater)
     */
    function previewCollateralAvailable(Position[] memory shorts, Position[] memory longs, Balance[] memory collaterals)
        external
        view
        returns (address[] memory, uint256[] memory, bool)
    {
        CrossMarginAccount memory account;

        account.shorts = shorts;
        account.longs = longs;
        account.collaterals = collaterals;

        return _getCollateralAvailable(account);
    }

    /**
     * @notice  grant or revoke an account access to all your sub-accounts based on a signed message
     * @dev     expected to have a valid signature signed with account private key
     * @param   _subAccount account which grants the access
     * @param   _actor account which is granted the access
     * @param   _allowedExecutions how many times the account is authorized to update your accounts.
     *          set to max(uint256) to allow permanent access
     * @param   _v signature v
     * @param   _r signature r
     * @param   _s signature s
     */
    function permitAccountAccess(
        address _subAccount,
        address _actor,
        uint256 _allowedExecutions,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "PermitAccountAccess(address subAccount,address actor,uint256 allowedExecutions,uint256 nonce)"
                                ),
                                _subAccount,
                                _actor,
                                _allowedExecutions,
                                nonces[_subAccount]++
                            )
                        )
                    )
                ),
                _v,
                _r,
                _s
            );

            if (recoveredAddress == address(0) || recoveredAddress != _subAccount) revert CM_InvalidSignature();
        }

        uint160 maskedId = uint160(_subAccount) | 0xFF;
        allowedExecutionLeft[maskedId][_actor] = _allowedExecutions;

        emit AccountAuthorizationUpdate(maskedId, _actor, _allowedExecutions);
    }

    /*///////////////////////////////////////////////////////////////
                                Public Functions
    //////////////////////////////////////////////////////////////*/

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == initialChainId ? initialDomainSeparator : _computeDomainSeparator();
    }

    /**
     * ========================================================= **
     *             Override Internal Functions For Each Action
     * ========================================================= *
     */

    /**
     * @notice  settle the margin account at expiry
     * @dev     override this function from BaseEngine
     *          because we get the payout while updating the storage during settlement
     * @dev     this update the account storage
     */
    function _settle(address _subAccount) internal override {
        // update the account in state
        (, Balance[] memory shortPayouts) = accounts[_subAccount].settleAtExpiry(grappa);
        emit AccountSettled(_subAccount, shortPayouts);
    }

    /**
     * ========================================================= **
     *               Override Sate changing functions             *
     * ========================================================= *
     */

    function _addCollateralToAccount(address _subAccount, uint8 collateralId, uint80 amount) internal override {
        accounts[_subAccount].addCollateral(collateralId, amount);
    }

    function _removeCollateralFromAccount(address _subAccount, uint8 collateralId, uint80 amount) internal override {
        accounts[_subAccount].removeCollateral(collateralId, amount);
    }

    function _increaseShortInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].mintOption(tokenId, amount);
    }

    function _decreaseShortInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].burnOption(tokenId, amount);
    }

    function _increaseLongInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].addOption(tokenId, amount);
    }

    function _decreaseLongInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].removeOption(tokenId, amount);
    }

    /**
     * ========================================================= **
     *          Override view functions for BaseEngine
     * ========================================================= *
     */

    /**
     * @dev because we override _settle(), this function is not used
     */
    // solhint-disable-next-line no-empty-blocks
    function _getAccountPayout(address) internal view override returns (uint8, int80) {}

    /**
     * @dev return whether if an account is healthy.
     * @param _subAccount subaccount id
     * @return isHealthy true if account is in good condition, false if it's underwater (liquidatable)
     */
    function _isAccountAboveWater(address _subAccount) internal view override returns (bool) {
        CrossMarginAccount memory account = accounts[_subAccount];

        // skip margin requirements check if no shorts
        if (account.shorts.length == 0) return true;

        (,, bool isUnderWater) = _getCollateralAvailable(account);
        return !isUnderWater;
    }

    /**
     * @notice returns the amount collateral being used and if account is underwater.
     * @param account to check
     */
    function _getCollateralAvailable(CrossMarginAccount memory account)
        internal
        view
        returns (address[] memory addresses, uint256[] memory amounts, bool isUnderWater)
    {
        Balance[] memory collaterals = account.collaterals;
        Balance[] memory requirements = _getMinCollateral(account);

        uint256 collatCount = collaterals.length;

        uint256[] memory masks;
        amounts = new uint256[](collatCount);
        addresses = new address[](collatCount);

        unchecked {
            for (uint256 x; x < requirements.length; ++x) {
                uint8 reqCollatId = requirements[x].collateralId;
                (address reqCollatAddr,) = grappa.assets(reqCollatId);
                uint256 reqAmount = requirements[x].amount;

                masks = new uint256[](collatCount);
                uint256 y;

                for (y; y < collatCount; ++y) {
                    uint8 collatId = collaterals[y].collateralId;

                    // only setting amount and address on first pass
                    // dont need to repeat each inner loop
                    if (x == 0) {
                        amounts[y] = collaterals[y].amount;

                        (address addr,) = grappa.assets(collatId);
                        addresses[y] = addr;
                    }

                    if (reqCollatId == collatId) {
                        masks[y] = 1 * UNIT;
                    } else {
                        // setting mask to price if reqCollateralId is collateralId
                        if (_isCollateralizable(reqCollatId, collatId)) {
                            masks[y] = oracle.getSpotPrice(addresses[y], reqCollatAddr);
                        }
                    }
                }

                uint256 marginValue = UintArrayLib.dot(amounts, masks) / UNIT;

                // not enough collateral posted
                if (marginValue < reqAmount) isUnderWater = true;

                // reserving collateral to prevent double counting
                for (y = 0; y < collatCount; ++y) {
                    if (masks[y] == 0) continue;

                    marginValue = amounts[y] * masks[y] / UNIT;

                    if (reqAmount >= marginValue) {
                        reqAmount = reqAmount - marginValue;
                        amounts[y] = 0;

                        if (reqAmount == 0) break;
                    } else {
                        amounts[y] = amounts[y] - (amounts[y] * reqAmount / marginValue);
                        // reqAmount would now be set to zero,
                        // no longer need to reserve, so breaking
                        break;
                    }
                }
            }
        }
    }

    /**
     * @dev reverts if the account cannot add this token into the margin account.
     * @param tokenId tokenId
     */
    function _verifyLongTokenIdToAdd(uint256 tokenId) internal view override {
        (TokenType optionType,, uint64 expiry,,) = tokenId.parseTokenId();

        // engine only supports calls and puts
        if (optionType != TokenType.CALL && optionType != TokenType.PUT) revert CM_UnsupportedTokenType();

        if (block.timestamp > expiry) revert CM_Token_Expired();

        uint8 engineId = tokenId.parseEngineId();

        // in the future reference a whitelist of engines
        if (engineId != grappa.engineIds(address(this))) revert CM_Not_Authorized_Engine();
    }

    /**
     * ========================================================= **
     *                         Internal Functions
     * ========================================================= *
     */

    /**
     * @notice gets access status of an address
     * @dev if whitelist address is not set, it ignores this
     * @param _address address
     */
    function _checkPermissioned(address _address) internal view {
        if (address(whitelist) != address(0) && !whitelist.isAllowed(_address)) revert NoAccess();
    }

    /**
     * @notice execute multiple actions on one subAccounts
     * @dev    also check access of msg.sender
     */
    function _execute(address _subAccount, ActionArgs[] calldata actions) internal {
        _assertCallerHasAccess(_subAccount);

        // update the account storage and do external calls on the flight
        for (uint256 i; i < actions.length;) {
            if (actions[i].action == ActionType.AddCollateral) {
                _addCollateral(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.RemoveCollateral) {
                _removeCollateral(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.MintShort) {
                _mintOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.MintShortIntoAccount) {
                _mintOptionIntoAccount(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.BurnShort) {
                _burnOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.BurnShortInAccount) {
                _burnOptionFromAccount(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.TransferLong) {
                _transferLong(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.TransferShort) {
                _transferShort(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.TransferCollateral) {
                _transferCollateral(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.AddLong) {
                _addOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.RemoveLong) {
                _removeOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.SettleAccount) {
                _settle(_subAccount);
            } else {
                revert CM_UnsupportedAction();
            }

            // increase i without checking overflow
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev get minimum collateral requirement for an account
     */
    function _getMinCollateral(CrossMarginAccount memory account) internal view returns (Balance[] memory) {
        return CrossMarginCashMath.getMinCollateralForPositions(grappa, account.shorts, account.longs);
    }

    /**
     * @dev check if a pair of assetIds are collateralizable
     */
    function _isCollateralizable(uint8 _assetId0, uint8 _assetId1) internal view returns (bool) {
        if (_assetId0 == _assetId1) return true;

        uint256 mask = 1 << _assetId1;
        return collateralizable[_assetId0] & mask != 0;
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Cross Margin Cash Engine"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}
