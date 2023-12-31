// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./CashOptionsVault.sol";

// interfaces
import "./IMarginEngine.sol";
import "./IPhysicalReturnProcessor.sol";

// libraries
import "./StructureLib.sol";

import "./constants.sol";
import "./errors.sol";
import "./types.sol";

abstract contract PhysicalOptionsVault is CashOptionsVault {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event ExerciseWindowSet(uint256 exerciseWindow, uint256 newExerciseWindow);

    event Exercised(address[] accounts, uint256[] shares);

    /*///////////////////////////////////////////////////////////////
                        Storage V1
    //////////////////////////////////////////////////////////////*/
    /// @notice Window to exercise long options
    uint256 public exerciseWindow;

    /// @notice **Deprecated**
    address public _returnProcessor;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[23] private __gap;

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _registrar is the address of the registrar contract
     * @param _share is the erc1155 contract that issues shares
     * @param _marginEngine is the margin engine used for physical options
     */
    constructor(address _registrar, address _share, address _marginEngine) CashOptionsVault(_registrar, _share, _marginEngine) {}

    function __PhysicalOptionsVault_init(
        InitParams calldata _initParams,
        address _auction,
        uint256 _exerciseWindow,
        Collateral calldata _premium
    ) internal onlyInitializing {
        __OptionsVault_init(_initParams, _auction, _premium);

        if (_exerciseWindow == 0) revert POV_BadExerciseWindow();

        exerciseWindow = _exerciseWindow;
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/
    function setExerciseWindow(uint256 _exerciseWindow) external {
        _setExerciseWindow(_exerciseWindow);
    }

    function requestWithdrawFor(address _subAccount, uint256 _numShares) external virtual override nonReentrant {
        _onlyRegistrar();

        if (expiry[vaultState.round] + exerciseWindow > block.timestamp) revert POV_OptionNotExpired();

        (Position[] memory shorts,,) = marginEngine.marginAccounts(address(this));

        if (_isExercised(shorts)) revert POV_CannotRequestWithdraw();

        _requestWithdraw(_subAccount, _numShares);
    }

    /**
     * @notice transfers asset from the margin account to depositors based on their shares and burns the shares
     * @dev called when vault gets put into the money
     *      only supports single asset structures
     *      assumes all depositors passed in have ownership in vault
     * @param _processor contract to perform airdrop
     * @param _accounts array of accounts to receive the exercised asset
     */
    function returnOnExercise(address _processor, address[] calldata _accounts, uint256[] calldata _shares) external virtual {
        // _onlyManager();

        // marginEngine.setAccountAccess(_processor, type(uint256).max);

        // IPhysicalReturnProcessor(_processor).returnOnExercise(_accounts, _shares);

        // marginEngine.setAccountAccess(_processor, 0);

        // emit Exercised(_accounts, _shares);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal function overrides
    //////////////////////////////////////////////////////////////*/

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
            (Position[] memory shorts,, Balance[] memory collats) = marginEngine.marginAccounts(address(this));

            if (collats.length == 0) revert OV_NoCollateral();

            if (shorts.length > 0) {
                if (_isExercised(shorts)) revert POV_VaultExercised();
                else StructureLib.settleOptions(marginEngine, false);
            }
        }
    }

    function _isExercised(Position[] memory _shorts) internal view returns (bool) {
        uint256 shortsLen = _shorts.length;

        for (uint256 i; i < shortsLen;) {
            (,, uint80 totalPaid) = marginEngine.tokenTracker(_shorts[i].tokenId);

            if (totalPaid > 0) return true;

            unchecked {
                ++i;
            }
        }

        return false;
    }

    function _setExerciseWindow(uint256 _exerciseWindow) internal virtual {
        _onlyOwner();

        if (_exerciseWindow == 0 || _exerciseWindow > type(uint64).max) revert POV_BadExerciseWindow();

        if (expiry[vaultState.round] + exerciseWindow > block.timestamp) revert POV_OptionNotExpired();

        emit ExerciseWindowSet(exerciseWindow, _exerciseWindow);

        exerciseWindow = _exerciseWindow;
    }
}
