//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./ITermRepoLocker.sol";
import "./ITermRepoLockerErrors.sol";
import "./ITermEventEmitter.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Versionable.sol";

/// @author TermLabs
/// @title Term Repo Locker
/// @notice This is the contract in which Term Servicer locks collateral and purchase tokens
/// @dev This contract belongs to the Term Servicer group of contracts and is specific to a Term Repo deployment
contract TermRepoLocker is
    ITermRepoLocker,
    ITermRepoLockerErrors,
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    Versionable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ========================================================================
    // = Access Roles =========================================================
    // ========================================================================
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DEVOPS_ROLE = keccak256("DEVOPS_ROLE");
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");
    bytes32 public constant SERVICER_ROLE = keccak256("SERVICER_ROLE");

    // ========================================================================
    // = State Variables ======================================================
    // ========================================================================
    bytes32 public termRepoId;
    bool public transfersPaused;
    // Boolean indicating if term contracts paired
    bool internal termContractPaired;
    ITermEventEmitter internal emitter;

    // ========================================================================
    // = Modifiers  ===========================================================
    // ========================================================================

    modifier whileTransfersNotPaused() {
        if (transfersPaused) {
            revert TermRepoLockerTransfersPaused();
        }
        _;
    }

    modifier notTermContractPaired() {
        if (termContractPaired) {
            revert AlreadyTermContractPaired();
        }
        termContractPaired = true;
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata termRepoId_,
        address termInitializer_
    ) external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();

        termRepoId = keccak256(abi.encodePacked(termRepoId_));

        transfersPaused = false;

        _grantRole(INITIALIZER_ROLE, termInitializer_);
    }

    function pairTermContracts(
        address termRepoCollateralManager_,
        address termRepoServicer_,
        ITermEventEmitter emitter_,
        address devopsMultisig_,
        address adminWallet_
    ) external onlyRole(INITIALIZER_ROLE) notTermContractPaired {
        emitter = emitter_;

        _grantRole(SERVICER_ROLE, termRepoCollateralManager_);
        _grantRole(SERVICER_ROLE, termRepoServicer_);
        _grantRole(DEVOPS_ROLE, devopsMultisig_);
        _grantRole(ADMIN_ROLE, adminWallet_);

        emitter.emitTermRepoLockerInitialized(termRepoId, address(this));
    }

    /// @notice Locks tokens from origin wallet
    /// @notice Reverts if caller doesn't have SERVICER_ROLE
    /// @param originWallet The wallet from which to transfer tokens
    /// @param token The address of token being transferred
    /// @param amount The amount of tokens to transfer
    function transferTokenFromWallet(
        address originWallet,
        address token,
        uint256 amount
    ) external override whileTransfersNotPaused onlyRole(SERVICER_ROLE) {
        IERC20Upgradeable tokenInstance = IERC20Upgradeable(token);

        // slither-disable-start arbitrary-send-erc20
        /// @dev This function is permissioned to be only callable by other term contracts. The entry points of calls that end up utilizing this function all use Authenticator to
        /// authenticate that the caller is the owner of the token whose approved this contract to spend the tokens. Therefore there is no risk of another wallet using this function
        /// to transfer somebody else's tokens.
        tokenInstance.safeTransferFrom(originWallet, address(this), amount);
        // slither-disable-end arbitrary-send-erc20
    }

    /// @notice Unlocks tokens to destination wallet
    /// @dev Reverts if caller doesn't have SERVICER_ROLE
    /// @param destinationWallet The wallet to unlock tokens into
    /// @param token The address of token being unlocked
    /// @param amount The amount of tokens to unlock
    function transferTokenToWallet(
        address destinationWallet,
        address token,
        uint256 amount
    ) external override whileTransfersNotPaused onlyRole(SERVICER_ROLE) {
        IERC20Upgradeable tokenInstance = IERC20Upgradeable(token);

        tokenInstance.safeTransfer(destinationWallet, amount);
    }

    // ========================================================================
    // = Pause Functions ======================================================
    // ========================================================================

    function pauseTransfers() external onlyRole(ADMIN_ROLE) {
        transfersPaused = true;
        emitter.emitTermRepoLockerTransfersPaused(termRepoId);
    }

    function unpauseTransfers() external onlyRole(ADMIN_ROLE) {
        transfersPaused = false;
        emitter.emitTermRepoLockerTransfersUnpaused(termRepoId);
    }

    ///@dev required override by the OpenZeppelin UUPS module
    ///@param impl new impl address for proxy upgrade
    function _authorizeUpgrade(
        address impl
    ) internal override onlyRole(DEVOPS_ROLE) {
        emitter.emitTermContractUpgraded(address(this), impl);
    }
}
