// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "./IERC165.sol";

/**
 * @dev 
 */
interface IAllowlist is IERC165 {

    /**
     * @dev address was not found on any allowlists
     */
    error AddressNotFound(address);

    /**
     * @dev allowlist does not exist
     */
    error AllowlistNotFound();

    /**
     * @dev proof array contains duplicate proofs
     */
    error DuplicateProofs();

    /**
     * @dev no allowlists exist in the contract
     */
    error NoAllowlistsFound();

    /**
     * @dev contract address is not an ERC721 or ERC1155 contract
     */
    error TypeAddressInvalid(bytes32);

    event AllowlistCreated(uint256);
    event AllowlistUpdated(uint256);

    /**
    * @dev 
    */
    enum Type {
        Merkle,
        ERC721,
        ERC1155
    }

    /**
    * @dev 
    */
    struct Allowlist {
        Type type_;
        bool isActive;
        string name;
        string source;
        string ipfsMetadataHash;
        uint256[] tokenTypeIds;
        bytes32 typedata;
        bool hasArbitraryAllocation;
    }

    /**
    * @dev 
    */
    function createAllowlist(Allowlist memory _allowlist) external;

    /**
    * @dev 
    */
    function updateAllowlist(uint256 _allowlistId, Allowlist memory _allowlist) external;

    /**
    * @dev get an individual allowlist by id
    */
    function getAllowlist(uint256 _allowlistId) external view returns (Allowlist memory);

    /**
    * @dev get all allowlists
    */
    function getAllowlists() external view returns (Allowlist[] memory);

    /**
    * @dev verifies that address is present on at least one allowlist
    */
    function isAllowed(address _address, bytes32[][] memory _proofs) external view returns (bool);

    /**
    * @dev verifies that address is present on at least one allowlist with arbitrary allocation via merkle tree | @bitcoinski
    */
    function isAllowedArbitrary(address _address, bytes32[] memory _proof, IAllowlist.Allowlist memory _allowlist, uint256 _quantity) external view returns (bool);

    /**
    * @dev verifies that address is present on all allowlists 
    */
    function isAllowedAll(address _address, bytes32[][] memory _proofs) external view returns (bool);

    /**
    * @dev verifies that address is present on at least specific number of allowlists 
    */
    function isAllowedAtLeast(address _address, bytes32[][] memory _proofs, uint256 _quantity) external view returns (bool);

    /**
    * @dev verifies that address is present on a specific allowlist 
    */
    function isAllowedOn(uint256 _allowlistId, address _address, bytes32[][] memory _proofs) external view returns (bool);

}
