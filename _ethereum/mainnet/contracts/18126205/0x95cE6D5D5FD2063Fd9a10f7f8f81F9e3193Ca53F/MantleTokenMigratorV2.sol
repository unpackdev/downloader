// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC20.sol";
import "./SafeTransferLib.sol";

/// @title Mantle Token Migrator V2
/// @author Derrick Johnson
/// @notice Token migration contract for the BIT to MNT token migration
contract MantleTokenMigratorV2 {
    using SafeTransferLib for ERC20;

    /* ========== STATE VARIABLES ========== */

    /// @dev The address of the BIT token contract
    address public immutable BIT_TOKEN_ADDRESS;

    /// @dev The address of the MNT token contract
    address public immutable MNT_TOKEN_ADDRESS;

    /// @dev The address of the treasury contract that receives defunded tokens
    address public treasury;

    /// @dev The address of the owner of the contract
    /// @notice The owner of the contract is initially the deployer of the contract but will be transferred
    ///         to a multisig wallet immediately after deployment
    address public owner;

    /// @dev A mapping of addresses with the ability to approve token migrations
    mapping(address => bool) public approvers;

    /// @dev A mapping of addresses with the ability blacklist addresses from migration
    mapping(address => bool) public blacklisters;

    /// @dev A mapping of addresses blacklisted from migration
    mapping(address => bool) public blacklistedAddresses;

    /// @dev Boolean indicating if this contract is halted
    bool public halted;

    /* ========== EVENTS ========== */

    // TokenSwap Events

    /// @dev Emitted when a user swaps BIT for MNT
    /// @param to The address of the user that swapped BIT for MNT
    /// @param amountSwapped The amount of BIT swapped and MNT received
    event TokensMigrated(address indexed to, uint256 amountSwapped);

    /// @dev Emitted when a user is approved for token migration
    /// @param approver The address of the caller that approved the user for token migration
    /// @param user The address of the user that was approved for token migration
    /// @param amount The amount of BIT tokens approved for token migration
    event TokenMigrationApproved(address indexed approver, address indexed user, uint256 amount);

    // Contract State Events

    /// @dev Emitted when the owner of the contract is changed
    /// @param previousOwner The address of the previous owner of this contract
    /// @param newOwner The address of the new owner of this contract
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Emitted when the contract is halted
    /// @param halter The address of the caller that halted this contract
    event ContractHalted(address indexed halter);

    /// @dev Emitted when the contract is unhalted
    /// @param halter The address of the caller that unhalted this contract
    event ContractUnhalted(address indexed halter);

    /// @dev Emitted when the treasury address is changed
    /// @param previousTreasury The address of the previous treasury
    /// @param newTreasury The address of the new treasury
    event TreasuryChanged(address indexed previousTreasury, address indexed newTreasury);

    // Admin Events

    /// @dev Emitted when non BIT/MNT tokens are swept from the contract by the owner to the recipient address
    /// @param token The address of the token contract that was swept
    /// @param recipient The address of the recipient of the swept tokens
    /// @param amount The amount of tokens swept
    event TokensSwept(address indexed token, address indexed recipient, uint256 amount);

    /// @dev Emitted when BIT/MNT tokens are defunded from the contract by the owner to the treasury
    /// @param defunder The address of the defunder
    /// @param token The address of the token contract that was defunded
    /// @param amount The amount of tokens defunded
    event ContractDefunded(address indexed defunder, address indexed token, uint256 amount);

    /// @dev Emitted when the Approver role is given to an address
    /// @param approver The address that was given the Approver role
    event ApproverRoleAssigned(address indexed approver);

    /// @dev Emitted when the Approver role is revoked from an address
    /// @param approver The address that had the Approver role revoked
    event ApproverRoleRevoked(address indexed approver);

    /// @dev Emitted when the Blacklister role is given to an address
    /// @param blacklister The address that was given the Blacklister role
    event BlacklisterRoleAssigned(address indexed blacklister);

    /// @dev Emitted when the Blacklister role is revoked from an address
    /// @param blacklister The address that had the Blacklister role revoked
    event BlacklisterRoleRevoked(address indexed blacklister);

    /// @dev Emitted when an address is blacklisted from migration
    /// @param blacklister The address of the caller that blacklisted the address
    /// @param blacklistedAddress The address that was blacklisted
    event BlacklistModified(
        address indexed blacklister, address indexed blacklistedAddress, bool indexed blacklistStatus
    );

    /// @dev Emitted when an address is removed from the blacklist
    /// @param blacklister The address of the caller that removed the address from the blacklist
    /// @param blacklistedAddress The address that was removed from the blacklist
    event AddressRemovedFromBlacklist(address indexed blacklister, address indexed blacklistedAddress);

    /* ========== ERRORS ========== */

    /// @notice Thrown when the caller is not the owner and the function being called uses the {onlyOwner} modifier
    /// @param caller The address of the caller
    error MantleTokenMigrator_OnlyOwner(address caller);

    /// @notice Thrown when the caller does not have the Approver role and the function being called uses the {onlyApprover} modifier
    /// @param caller The address of the caller
    error MantleTokenMigrator_OnlyApprover(address caller);

    /// @notice Thrown when the caller does not have the Blacklist role and the function being called uses the {onlyBlacklister} modifier
    /// @param caller The address of the caller
    error MantleTokenMigrator_OnlyBlacklister(address caller);

    /// @notice Thrown when the address being approved for token migration is blacklisted
    error MantleTokenMigrator_BlacklistModified(address tokenMigrator);

    /// @notice Thrown when the contract is halted and the function being called uses the {onlyWhenNotHalted} modifier
    error MantleTokenMigrator_OnlyWhenNotHalted();

    /// @notice Thrown when the input passed into the {_migrateTokens} function is zero
    error MantleTokenMigrator_ZeroSwap();

    /// @notice Thrown when at least one of the inputs passed into the constructor is a zero value
    error MantleTokenMigrator_ImproperlyInitialized();

    /// @notice Thrown when the {_tokenAddress} passed into the {sweepTokens} function is the BIT or MNT token address
    /// @param token The address of the token contract
    error MantleTokenMigrator_SweepNotAllowed(address token);

    /// @notice Thrown when the {_tokenAddress} passed into the {defundContract} function is NOT the BIT or MNT token address
    /// @param token The address of the token contract
    error MantleTokenMigrator_InvalidFundingToken(address token);

    /// @notice Thrown when the treasury is the zero address
    error MantleTokenMigrator_InvalidTreasury(address treasury);

    /* ========== MODIFIERS ========== */

    /// @notice Modifier that checks that the caller is the owner of the contract
    /// @dev Throws {MantleTokenMigrator_OnlyOwner} if the caller is not the owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert MantleTokenMigrator_OnlyOwner(msg.sender);
        _;
    }

    /// @notice Modifier that checks that the caller has the Approver role
    /// @dev Throws {MantleTokenMigrator_OnlyApprover} if the caller does not have the Approver role
    modifier onlyApprover() {
        if (!approvers[msg.sender]) revert MantleTokenMigrator_OnlyApprover(msg.sender);
        _;
    }

    /// @notice Modifier that checks that the contract is not halted
    /// @dev Throws {MantleTokenMigrator_OnlyWhenNotHalted} if the contract is halted
    modifier onlyWhenNotHalted() {
        if (halted) revert MantleTokenMigrator_OnlyWhenNotHalted();
        _;
    }

    /// @notice Modifier that checks that the caller has the Blacklist role
    /// @dev Throws {MantleTokenMigrator_OnlyBlacklister} if the caller does not have the Blacklist role
    modifier onlyBlacklister() {
        if (!blacklisters[msg.sender]) revert MantleTokenMigrator_OnlyBlacklister(msg.sender);
        _;
    }

    /// @notice Modifier that checks that the address being approved for token migration is not blacklisted
    /// @dev Throws {MantleTokenMigrator_BlacklistModified} if the address is blacklisted
    /// @param _address The address to check
    modifier onlyWhenNotBlacklisted(address _address) {
        if (blacklistedAddresses[_address]) revert MantleTokenMigrator_BlacklistModified(_address);
        _;
    }

    /// @notice Initializes the MantleTokenMigrator contract, setting the initial deployer as the contract owner
    /// @dev _bitTokenAddress, _mntTokenAddress, _tokenConversionNumerator, and _tokenConversionDenominator are immutable: they can only be set once during construction
    /// @dev the contract is initialized in a halted state
    /// @dev Requirements:
    ///     - all parameters must be non-zero
    ///     - _bitTokenAddress and _mntTokenAddress are assumed to have the same number of decimals
    /// @param _bitTokenAddress The address of the BIT token contract
    /// @param _mntTokenAddress The address of the MNT token contract
    /// @param _treasury The address of the treasury contract that receives defunded tokens
    constructor(address _bitTokenAddress, address _mntTokenAddress, address _treasury) {
        if (_bitTokenAddress == address(0) || _mntTokenAddress == address(0) || _treasury == address(0)) {
            revert MantleTokenMigrator_ImproperlyInitialized();
        }

        owner = msg.sender;
        halted = true;

        BIT_TOKEN_ADDRESS = _bitTokenAddress;
        MNT_TOKEN_ADDRESS = _mntTokenAddress;

        treasury = _treasury;
    }

    /* ========== TOKEN SWAPPING ========== */

    /// @notice Allows an approver to approve a user for token migration and performs the migration on their behalf
    /// @dev emits a {TokenMigrationApproved} and {TokensMigrated} event
    /// @dev Requirements:
    ///     - The contract must not be halted
    ///     - The caller must have the Approver role
    ///     - The address being approved for token migration must not be blacklisted
    function approveMigrationRequest(address _addressToMigrate, uint256 _amount)
        external
        onlyWhenNotHalted
        onlyApprover
        onlyWhenNotBlacklisted(_addressToMigrate)
    {
        emit TokenMigrationApproved(msg.sender, _addressToMigrate, _amount);
        _migrateTokens(_addressToMigrate, _amount);
    }

    /// @notice Internal function that swaps a specified amount of the caller's BIT tokens for MNT tokens
    /// @dev emits a {TokensMigrated} event
    /// @dev Requirements:
    ///     - The caller must have approved this contract to spend at least {_amount} of their BIT tokens
    ///     - The caller must have a balance of at least {_amount} of BIT tokens
    ///     - {_amount} must be non-zero
    /// @param _to The address of the user to swap tokens for
    /// @param _amount The amount of BIT tokens to swap
    function _migrateTokens(address _to, uint256 _amount) internal {
        if (_amount == 0) revert MantleTokenMigrator_ZeroSwap();

        // transfer user's BIT tokens to this contract
        ERC20(BIT_TOKEN_ADDRESS).safeTransferFrom(_to, address(this), _amount);

        // transfer MNT tokens to user, if there are insufficient tokens, in the contract this will revert
        ERC20(MNT_TOKEN_ADDRESS).safeTransfer(_to, _amount);

        emit TokensMigrated(_to, _amount);
    }

    /* ========== ADMIN UTILS ========== */

    // Ownership Functions

    /// @notice Transfers ownership of the contract to a new address
    /// @dev emits an {OwnershipTransferred} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    // Role Assignment Functions

    /// @notice Gives the Approver role to an address
    /// @dev emits an {ApproverRoleAssigned} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    /// @param _approver The address to give the Approver role to
    function giveApproverRole(address _approver) public onlyOwner {
        approvers[_approver] = true;

        emit ApproverRoleAssigned(_approver);
    }

    /// @notice Revokes the Approver role from an address
    /// @dev emits an {ApproverRoleRevoked} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    /// @param _approver The address to revoke the Approver role from
    function revokeApproverRole(address _approver) public onlyOwner {
        approvers[_approver] = false;

        emit ApproverRoleRevoked(_approver);
    }

    /// @notice Gives the Blacklister role to an address
    /// @dev emits an {BlacklisterRoleAssigned} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    /// @param _blacklister The address to give the Blacklister role to
    function giveBlacklisterRole(address _blacklister) public onlyOwner {
        blacklisters[_blacklister] = true;

        emit BlacklisterRoleAssigned(_blacklister);
    }

    /// @notice Revokes the Blacklister role from an address
    /// @dev emits an {BlacklisterRoleRevoked} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    /// @param _blacklister The address to revoke the Blacklist role from
    function revokeBlacklisterRole(address _blacklister) public onlyOwner {
        blacklisters[_blacklister] = false;

        emit BlacklisterRoleRevoked(_blacklister);
    }

    // Contract State Functions

    /// @notice Blacklists an address from token migration
    /// @dev emits an {BlacklistModified} event
    /// @dev Requirements:
    ///     - The caller must have the Blacklister role
    /// @param _address The address to blacklist
    function blacklistAddress(address _address) public onlyBlacklister {
        blacklistedAddresses[_address] = true;

        emit BlacklistModified(msg.sender, _address, true);
    }

    /// @notice Removes an address from the blacklist
    /// @dev emits an {BlacklistModified} event
    /// @dev Requirements:
    ///     - The caller must have the Blacklister role
    /// @param _address The address to remove from the blacklist
    function removeAddressFromBlacklist(address _address) public onlyBlacklister {
        blacklistedAddresses[_address] = false;

        emit BlacklistModified(msg.sender, _address, false);
    }

    /// @notice Halts the contract, preventing token migrations
    /// @dev emits a {ContractHalted} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    function haltContract() public onlyOwner {
        halted = true;

        emit ContractHalted(msg.sender);
    }

    /// @notice Unhalts the contract, allowing token migrations
    /// @dev emits a {ContractUnhalted} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    function unhaltContract() public onlyOwner {
        halted = false;

        emit ContractUnhalted(msg.sender);
    }

    /// @notice Sets the treasury address
    /// @dev emits a {TreasuryChanged} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    function setTreasury(address _treasury) public onlyOwner {
        if (_treasury == address(0)) {
            revert MantleTokenMigrator_InvalidTreasury(_treasury);
        }

        emit TreasuryChanged(treasury, _treasury);

        treasury = _treasury;
    }

    // Token Management Functions

    /// @notice Defunds the contract by transferring a specified amount of BIT or MNT tokens to the treasury address
    /// @dev emits a {ContractDefunded} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    ///     - {_tokenAddress} must be either the BIT or the MNT token address
    ///     - The contract must have a balance of at least {_amount} of {_tokenAddress} tokens
    /// @param _tokenAddress The address of the token to defund
    /// @param _amount The amount of tokens to defund
    function defundContract(address _tokenAddress, uint256 _amount) public onlyOwner {
        if (_tokenAddress != BIT_TOKEN_ADDRESS && _tokenAddress != MNT_TOKEN_ADDRESS) {
            revert MantleTokenMigrator_InvalidFundingToken(_tokenAddress);
        }

        // we can only defund BIT or MNT into the predefined treasury address
        ERC20(_tokenAddress).safeTransfer(treasury, _amount);

        emit ContractDefunded(treasury, _tokenAddress, _amount);
    }

    /// @notice Sweeps a specified amount of tokens to an arbitrary address in case of accidental token transfers
    /// @dev emits a {TokensSwept} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    ///     - {_tokenAddress} must not the BIT or the MNT token address
    ///     - The contract must have a balance of at least {_amount} of {_tokenAddress} tokens
    /// @param _tokenAddress The address of the token to sweep
    /// @param _recipient The address to sweep the tokens to
    /// @param _amount The amount of tokens to sweep
    function sweepTokens(address _tokenAddress, address _recipient, uint256 _amount) public onlyOwner {
        // we can only sweep tokens that are not BIT or MNT to an arbitrary addres
        if ((_tokenAddress == BIT_TOKEN_ADDRESS) || (_tokenAddress == MNT_TOKEN_ADDRESS)) {
            revert MantleTokenMigrator_SweepNotAllowed(_tokenAddress);
        }
        ERC20(_tokenAddress).safeTransfer(_recipient, _amount);

        emit TokensSwept(_tokenAddress, _recipient, _amount);
    }
}