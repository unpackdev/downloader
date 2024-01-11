// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";

interface NFT {
    function buy() external payable;

    function buy(uint256 _quantity) external payable;
}

/**
 * @title AllowListSale Contract
  Contract for allowlist sales on multiple contracts
 */
contract AllowListSale is Ownable {
    mapping(address => bytes32) public merkleRoots;
    mapping(address => uint256) private _requireAllowlist;

    // Constructor
    // @param _merkleRoot root of merkle tree
    constructor(address _contractAddress, bytes32 _merkleRoot) {
        merkleRoots[_contractAddress] = _merkleRoot;
        _requireAllowlist[_contractAddress] = 1;
    }

    // @notice Is a given address allowlisted based on proof provided
    // @param _proof Merkle proof
    // @param _claimer address to check
    // @param _contract NFT contract address
    // @return Is allowlisted
    function isOnAllowlist(
        bytes32[] memory _proof,
        address _claimer,
        address _contract
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_claimer));
        return MerkleProof.verify(_proof, merkleRoots[_contract], leaf);
    }

    function setMerkleRoot(address _contract, bytes32 _merkleRoot)
        external
        onlyOwner
    {
        merkleRoots[_contract] = _merkleRoot;
    }

    function allowlistMint(
        address _contract,
        bytes32[] memory _proof,
        uint256 _quantity
    ) external payable {
        require(
            (_requireAllowlist[_contract] == 1 &&
                isOnAllowlist(_proof, _msgSender(), _contract)) ||
                _requireAllowlist[_contract] == 0,
            "Unable to mint if not on the allowlist"
        );
        if (_quantity == 0) {
            NFT(_contract).buy{value: msg.value}();
        } else {
            NFT(_contract).buy{value: msg.value}(_quantity);
        }
    }

    function publicMint(address _contract, uint256 _quantity) external payable {
        require(
            _requireAllowlist[_contract] == 0,
            "Public mint is not live yet"
        );
        if (_quantity == 0) {
            NFT(_contract).buy{value: msg.value}();
        } else {
            NFT(_contract).buy{value: msg.value}(_quantity);
        }
    }

    function toggleAllowlistRequired(address _contract, uint256 _enabled)
        public
        onlyOwner
    {
        _requireAllowlist[_contract] = _enabled;
    }

    function batchSetContracts(
        address[] memory _contracts,
        uint256 _requireAllowList
    ) external onlyOwner {
        for (uint256 c = 0; c < _contracts.length; c += 1) {
            _requireAllowlist[_contracts[c]] = _requireAllowList;
        }
    }
}
