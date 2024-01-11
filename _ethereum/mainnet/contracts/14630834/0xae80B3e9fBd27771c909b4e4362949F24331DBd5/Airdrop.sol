//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "SafeMath.sol";
import "AccessControl.sol";
import "Pausable.sol";
import { MerkleProof } from "MerkleProof.sol";
import "IVesting.sol";

contract Airdrop is AccessControl, Pausable {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public JAN_5_2025 = 1736086440;

    bytes32 public merkleRoot;
    IVesting public vesting;
    mapping(address => bool) public claimed;

    event Claimed(address grantee, uint256 amount);

    constructor(address daoMultiSig, IVesting _vesting) {
        require(address(_vesting) != address(0), "Invalid address");

        vesting = _vesting;

        _grantRole(DEFAULT_ADMIN_ROLE, daoMultiSig);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function setRoot(bytes32 _merkleRoot)
        external
        onlyRole(ADMIN_ROLE)
    {
        merkleRoot = _merkleRoot;
    }

    function claim(address to, uint256 amount, bytes32[] memory proof)
        external
    {
        require(!claimed[msg.sender], "Already claimed");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));

        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        require(isValidLeaf, "Invalid leaf");

        claimed[msg.sender] = true;

        vesting.vest(msg.sender, amount, 365 days, JAN_5_2025);
        vesting.mintFor(msg.sender);
        
        emit Claimed(msg.sender, amount);
    }

    /// @notice Pause contract 
    function pause()
        public
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        _pause();
    }

    /// @notice Unpause contract
    function unpause()
        public
        onlyRole(ADMIN_ROLE)
        whenPaused
    {
        _unpause();
    }
}