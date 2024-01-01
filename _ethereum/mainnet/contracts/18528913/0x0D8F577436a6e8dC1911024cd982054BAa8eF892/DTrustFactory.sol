// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTrustV1.sol";

/// @title DTRUSTFactory
/// @notice Factory contract for creating new DTrust contracts
/// @dev This contract deploys new instances of DTrust and tracks them
contract DTRUSTFactory {
    /// Public variable with the address of the bank wallet
    address public bankWallet;

    /// Fee percentage for the bank; scaled by 100 (e.g., 10 represents 0.10%, 100 represents 1%, 1000 represents 10%)
    uint256 public bankFee = 10;

    /// Dynamic array of all deployed DTrust contracts
    address[] public allDTrusts;

    /// Mapping from user addresses to their respective DTrust contracts
    mapping(address => address[]) public dTrustsByUser;

    /// Mapping to check if a user has been added to a DTrust contract to prevent duplicates
    mapping(address => mapping(address => bool)) public isUserAddedToDTrust;

    /// Event emitted when a new DTrust contract is created
    event DTrustCreated(address indexed settlor, address trustAddress);

    /// Event emitted when a user is added to a DTrust contract
    event UserAddedToDTrust(address indexed user, address trustAddress);

    /// @notice Constructs the DTRUSTFactory and sets the bank wallet address
    /// @param _bankWallet The address of the bank wallet where fees are collected
    constructor(address _bankWallet) {
        bankWallet = _bankWallet;
    }

    /// @notice Creates a new DTRUST contract and registers the involved parties
    /// @param _name Name of the dtrust
    /// @param _settlor Address of the settlor creating the dtrust
    /// @param _trustees Array of addresses designated as trustees
    /// @param _beneficiaries Array of addresses designated as beneficiaries
    /// @param _canRevokeAddresses Array of addresses with permission to revoke the dtrust
    function createDTRUST(
        string calldata _name,
        address _settlor,
        address[] calldata _trustees,
        address[] calldata _beneficiaries,
        address[] calldata _canRevokeAddresses
    ) external {
        DTRUST newDTRUST = new DTRUST(
            _name,
            _settlor,
            address(this),
            _trustees,
            _beneficiaries,
            _canRevokeAddresses
        );
        allDTrusts.push(address(newDTRUST));
        addUniqueUser(_settlor, newDTRUST);
        addUniqueUsers(_trustees, newDTRUST);
        addUniqueUsers(_beneficiaries, newDTRUST);
        emit DTrustCreated(_settlor, address(newDTRUST));
    }

    /// @dev Adds an array of unique users to the internal tracking for a given DTRUST
    /// @param _users Array of user addresses to be added
    /// @param newDTRUST Address of the DTRUST contract to which users are added
    function addUniqueUsers(address[] calldata _users, DTRUST newDTRUST) internal {
        for (uint i = 0; i < _users.length; i++) {
            addUniqueUser(_users[i], newDTRUST);
        }
    }

    /// @dev Adds a single unique user to the internal tracking for a given DTRUST
    /// @param _user Address of the user to be added
    /// @param newDTRUST Address of the DTRUST contract to which the user is added
    function addUniqueUser(address _user, DTRUST newDTRUST) internal {
        if (!isUserAddedToDTrust[_user][address(newDTRUST)]) {
            dTrustsByUser[_user].push(address(newDTRUST));
            isUserAddedToDTrust[_user][address(newDTRUST)] = true;
            emit UserAddedToDTrust(_user, address(newDTRUST));
        }
    }

    /// @notice Retrieves the DTRUST contracts associated with a given user
    /// @param _user The address of the user
    /// @return An array of addresses of DTRUST contracts linked to the user
    function getDTrustsByUser(address _user) external view returns (address[] memory) {
        return dTrustsByUser[_user];
    }

    /// @notice Collects the annual fee for a specified DTRUST contract
    /// @param dtrustAddress The payable address of the DTRUST contract from which to collect the fee
    function collectAnnualFeeForTrust(address payable dtrustAddress) external {
        DTRUST(dtrustAddress).takeAnnualFee(bankWallet, bankFee);
    }

    /// @notice Returns the total number of DTRUST contracts created by the factory
    /// @return The count of all DTRUST contracts
    function getAllDTrustsCount() external view returns (uint256) {
        return allDTrusts.length;
    }
}
