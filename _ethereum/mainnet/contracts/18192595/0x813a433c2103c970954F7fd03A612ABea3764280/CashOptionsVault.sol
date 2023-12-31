// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./BaseVault.sol";

// interfaces
import "./IERC20.sol";
import "./IOracle.sol";
import "./IAuctionVault.sol";
import "./IPositionPauser.sol";
import "./IMarginEngine.sol";

// libraries
import "./FeeLib.sol";
import "./StructureLib.sol";
import "./VaultLib.sol";
import "./SafeERC20.sol";

import "./errors.sol";
import "./constants.sol";
import "./types.sol";

enum AddressType {
    Manager,
    FeeRecipient,
    Pauser,
    Whitelist,
    Auction
}

abstract contract CashOptionsVault is BaseVault, IAuctionVault {
    using SafeERC20 for IERC20;
    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    /// @notice marginAccount is the options protocol collateral pool
    IMarginEngine public immutable marginEngine;

    /*///////////////////////////////////////////////////////////////
                        Storage V1
    //////////////////////////////////////////////////////////////*/
    /// @notice the address of the auction settlement contract
    address public auction;

    /*///////////////////////////////////////////////////////////////
                        Storage V2
    //////////////////////////////////////////////////////////////*/
    /// @notice the address of the auction settlement contract
    Collateral public premium;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[23] private __gap;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event AuctionSet(address auction, address newAuction);

    event PremiumSet(uint8 id, address addr, uint8 decimals, uint8 newId, address newAddr, uint8 newDecimals);

    event MarginAccountAccessSet(address auction, uint256 allowedExecutions);

    event StagedAuction(uint256 indexed expiry, uint32 round);

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _registrar is the address of the registrar contract
     * @param _share is the erc1155 contract that issues shares
     * @param _marginEngine is the margin engine used for cash options
     */
    constructor(address _registrar, address _share, address _marginEngine) BaseVault(_registrar, _share) {
        if (_marginEngine == address(0)) revert BadAddress();

        marginEngine = IMarginEngine(_marginEngine);
    }

    function __OptionsVault_init(InitParams calldata _initParams, address _auction, Collateral calldata _premium)
        internal
        onlyInitializing
    {
        __BaseVault_init(_initParams);

        // verifies that initial collaterals are present
        StructureLib.verifyInitialCollaterals(_initParams._collaterals);

        if (_auction == address(0)) revert BadAddress();

        auction = _auction;
        premium = _premium;

        marginEngine.setAccountAccess(_auction, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                                Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the auction allowable executions on the margin account
     * @param _allowedExecutions how many times the account is authorized to update vault account.
     *        set to max(uint256) to allow unlimited access
     */
    function setAuctionMarginAccountAccess(uint256 _allowedExecutions) external {
        // _onlyManager();

        // emit MarginAccountAccessSet(auction, _allowedExecutions);

        // marginEngine.setAccountAccess(auction, _allowedExecutions);
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the amount of collateral to use in the next auction
     * @dev performing asset requirements off-chain to save gas fees
     */
    function stageAuction() external {
        // _onlyManager();

        // _setRoundExpiry();
    }

    function setPremium(uint8 _id, address _addr, uint8 _decimals) external {
        // _onlyOwner();

        // if (_id != 0 || _addr != address(0)) {
        //     if (_id == 0) revert OV_BadPremium();
        //     if (_addr == address(0)) revert OV_BadPremium();
        // }

        // emit PremiumSet(premium.id, premium.addr, premium.decimals, _id, _addr, _decimals);

        // premium = Collateral(_id, _addr, _decimals);
    }

    function recoverToken(uint8 _collateralId, uint256 _amount, address _recipient) external {
        _onlyManager();

        if (_collateralId == collaterals[0].id) revert OV_BadCollateral();

        Collateral[] memory collat = new Collateral[](1);
        collat[0] = Collateral(_collateralId, address(0), 0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        StructureLib.withdrawCollaterals(marginEngine, collat, amounts, _recipient);

        uint256 balance = IERC20(collaterals[0].addr).balanceOf(address(this));
        IERC20(collaterals[0].addr).safeTransfer(_recipient, balance);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets addresses for different settings
     * @dev Address Types:
     *      0 - Manager
     *      1 - FeeRecipient
     *      2 - Pauser
     *      3 - Whitelist
     *      4 - Auction
     * @param _type of address
     * @param _address is the new address
     */
    // function _setAddress(uint256 _type, address _address) internal override {
    //     if (_type < 4) {
    //         super._setAddress(_type, _address);
    //     } else {
    //         AddressType addressType = AddressType(_type);

    //         if (AddressType.Auction == addressType) {
    //             emit AddressSet(_type, auction, _address);
    //             auction = _address;

    //             marginEngine.setAccountAccess(_address, type(uint256).max);
    //         } else {
    //             revert BadAddress();
    //         }
    //     }
    // }

    /**
     * @notice Settles the existing option(s)
     */
    function _beforeCloseRound() internal virtual override {
        VaultState memory vState = vaultState;

        if (vState.round == 1) return;

        uint256 currentExpiry = expiry[vState.round];

        if (currentExpiry > block.timestamp) {
            if (vState.totalPending == 0) revert OV_NoCollateralPending();
        } else {
            (Position[] memory shorts, Position[] memory longs, Balance[] memory collats) =
                marginEngine.marginAccounts(address(this));

            if (collats.length == 0) revert OV_NoCollateral();

            if (shorts.length == 0 && longs.length == 0) revert OV_RoundClosed();

            StructureLib.settleOptions(marginEngine, true);
        }
    }

    /**
     * @notice Sets next expiry
     */
    function _afterCloseRound() internal virtual override {
        _setRoundExpiry();
    }

    /**
     * @notice Sets the next options expiry
     */
    function _setRoundExpiry() internal virtual {
        uint256 currentRound = vaultState.round;

        if (currentRound == 1) revert OV_BadRound();

        uint256 currentExpiry = expiry[currentRound];
        uint256 newExpiry = VaultLib.getNextExpiry(roundConfig);

        if (PLACEHOLDER_UINT < currentExpiry && currentExpiry < newExpiry) {
            (Position[] memory shorts, Position[] memory longs,) = marginEngine.marginAccounts(address(this));

            if (shorts.length > 0 || longs.length > 0) revert OV_ActiveRound();
        }

        expiry[currentRound] = newExpiry;

        emit StagedAuction(newExpiry, vaultState.round);
    }

    function _processFees(uint256[] memory _balances, uint256 _currentRound)
        internal
        virtual
        override
        returns (uint256[] memory balances)
    {
        uint256[] memory totalFees;

        VaultDetails memory vaultDetails =
            VaultDetails(collaterals, startingBalances[_currentRound], _balances, vaultState.totalPending);

        (totalFees, balances) = FeeLib.processFees(vaultDetails, managementFee, performanceFee);

        StructureLib.withdrawCollaterals(marginEngine, collaterals, totalFees, feeRecipient);

        emit CollectedFees(totalFees, _currentRound, feeRecipient);
    }

    function _rollInFunds(uint256[] memory _balances, uint256 _currentRound, uint256 _expiry) internal virtual override {
        super._rollInFunds(_balances, _currentRound, _expiry);

        StructureLib.depositCollateral(marginEngine, collaterals);
    }

    /**
     * @notice Gets net asset values
     * @dev Includes premium balance if premium is set
     * @param _balances current balances
     * @param _currentRound current round
     * @param _expiry round expiry
     */
    function _getNAVs(uint256[] memory _balances, uint256 _currentRound, uint256 _expiry)
        internal
        view
        virtual
        override
        returns (uint256 totalNAV, uint256 pendingNAV, uint256[] memory prices)
    {
        (totalNAV, pendingNAV, prices) = super._getNAVs(_balances, _currentRound, _expiry);

        // premium not set, returning early
        if (premium.id == 0) return (totalNAV, pendingNAV, prices);

        uint256 premiumBalance = IERC20(premium.addr).balanceOf(address(this));

        (,, Balance[] memory marginCollaterals) = marginEngine.marginAccounts(address(this));

        for (uint256 i; i < marginCollaterals.length;) {
            if (marginCollaterals[i].collateralId == premium.id) {
                premiumBalance += marginCollaterals[i].amount;
                break;
            }
            unchecked {
                ++i;
            }
        }

        if (premiumBalance == 0) return (totalNAV, pendingNAV, prices);

        IOracle oracle_ = IOracle(oracle);

        uint256 price;
        if (_expiry <= PLACEHOLDER_UINT) price = oracle_.getSpotPrice(premium.addr, collaterals[0].addr);
        else (price,) = oracle_.getPriceAtExpiry(premium.addr, collaterals[0].addr, _expiry);

        totalNAV += premiumBalance * price / (10 ** premium.decimals);
    }

    /**
     * @notice Completes withdraws from a past round
     * @dev transfers assets to pauser to exclude from vault balances
     */
    function _completeWithdraw() internal virtual override returns (uint256) {
        uint256 withdrawShares = uint256(vaultState.queuedWithdrawShares);

        uint256[] memory withdrawAmounts = new uint256[](1);

        if (withdrawShares > 0) {
            vaultState.queuedWithdrawShares = 0;

            withdrawAmounts =
                StructureLib.withdrawWithShares(marginEngine, share.totalSupply(address(this)), withdrawShares, pauser);

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
     * @dev used in _processFees, _rollInFunds and lockedAmount (in a rolling close)
     */
    function _getCurrentBalances() internal view virtual override returns (uint256[] memory balances) {
        (,, Balance[] memory marginCollaterals) = marginEngine.marginAccounts(address(this));

        Collateral[] memory collats = collaterals;

        balances = new uint256[](collats.length);
        uint256 i;

        for (i; i < collats.length;) {
            balances[i] = IERC20(collats[i].addr).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }

        // ensuring that the balances are updated for the marginCollaterals in the correct position
        for (i = 0; i < marginCollaterals.length;) {
            (bool found, uint256 index) = VaultLib.indexOfId(collats, marginCollaterals[i].collateralId);

            if (found) balances[index] += marginCollaterals[i].amount;

            unchecked {
                ++i;
            }
        }
    }
}
