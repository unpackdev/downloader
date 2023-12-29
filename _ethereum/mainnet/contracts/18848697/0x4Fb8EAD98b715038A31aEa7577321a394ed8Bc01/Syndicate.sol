// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";

import "./ECDSA.sol";
import "./MessageHashUtils.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./ISyndicate.sol";

contract Syndicate is ISyndicate, ReentrancyGuardUpgradeable, AccessControlUpgradeable {

    using ECDSA for bytes32;

    bytes32 public constant SYNDICATE_ADMIN_ROLE = keccak256("SYNDICATE_ADMIN_ROLE");

    IERC20 public usdc;
    address public destinationWallet;

    uint256 public transferStart;
    uint256 public transferEnd;

    mapping(address => uint256) public lastTransfer;

    address private signerAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // initializer
    function initialize( address usdcAddress, address _destinationWallet, address _signerAddress ) initializer public {

        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SYNDICATE_ADMIN_ROLE, msg.sender);

        usdc = IERC20(usdcAddress);

        destinationWallet = _destinationWallet;
        signerAddress = _signerAddress;

    }

    modifier transferEnabled() {
        if( block.timestamp < transferStart || block.timestamp > transferEnd ) revert TransferDisabled();
        _;
    }

    // @dev checks if trading is enabled or not
    function isTransferEnabled() external view returns(bool) {
        return ( block.timestamp >= transferStart && block.timestamp <= transferEnd );
    }

    // @dev checks if wallet is a syndicate admin or not
    function isSyndicateAdmin(address wallet) external view returns(bool) {
        return hasRole(SYNDICATE_ADMIN_ROLE, wallet);
    }

    // @dev checks if wallet already transferred for current timeframe
    function alreadyTransferredForTimeframe(address wallet) external view returns(bool) {
        uint256 _lastTransfer = lastTransfer[wallet];
        return ( transferStart > 0 && _lastTransfer >= transferStart && _lastTransfer <= transferEnd );
    }

    // @dev adds the syndicate admin role to the given wallet
    function addSyndicateAdmin(address wallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(SYNDICATE_ADMIN_ROLE, wallet);
        emit SyndicateAdminAdded(wallet);
    }

    // @dev removes the syndicate admin role from the given wallet
    function removeSyndicateAdmin(address wallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(SYNDICATE_ADMIN_ROLE, wallet);
        emit SyndicateAdminRemoved(wallet);
    }

    // @dev changes the usdc contract
    function setUsdcContract(address usdcAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdc = IERC20(usdcAddress);
        emit UsdcContractChanged(usdcAddress);
    }

    // @dev changes the destination wallet
    function setDestinationWallet(address wallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        destinationWallet = wallet;
        emit DestinationWalletChanged(wallet);
    }

    // @dev changes the signer address
    function setSigner(address wallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signerAddress = wallet;
        emit SignerAddressChanged(wallet);
    }

    // @dev sets the transfer timeframe
    function setTransferTimeframe(uint256 _transferStart, uint256 _transferEnd) external onlyRole(SYNDICATE_ADMIN_ROLE) {
        transferStart = _transferStart;
        transferEnd = _transferEnd;
        emit TimeframeChanged(_transferStart, _transferEnd);
    }

    // @dev transfers erc20 amount to the destination wallet
    function transfer(uint256 amount, uint256 minTransfer, uint256 maxTransfer, uint256 timestamp, bytes calldata signature) external nonReentrant transferEnabled {

        // Signature verification
        if(!_verifySig(msg.sender, minTransfer, maxTransfer, timestamp, signature)) revert InvalidSignature();

        uint256 _lastTransfer = lastTransfer[msg.sender];

        // Validation checks
        if( _lastTransfer >= transferStart && _lastTransfer <= transferEnd ) revert AlreadyTransferredInTimeframe();
        if( amount < minTransfer ) revert BelowMinimumAmount(amount, minTransfer);
        if( amount > maxTransfer ) revert MaximumAmountExceeded(amount, maxTransfer);

        // Convert amount
        uint256 amountToSend = amount * 1e6;

        // Set last transfer timestamp
        lastTransfer[msg.sender] = timestamp;

        // Transfer amount
        usdc.transferFrom(msg.sender, destinationWallet, amountToSend);

        emit Transfer(msg.sender, amountToSend);
    }

    function _verifySig(address sender, uint256 minTransfer, uint256 maxTransfer, uint256 timestamp, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, minTransfer, maxTransfer, timestamp));
        return signerAddress == MessageHashUtils.toEthSignedMessageHash(messageHash).recover(signature);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}