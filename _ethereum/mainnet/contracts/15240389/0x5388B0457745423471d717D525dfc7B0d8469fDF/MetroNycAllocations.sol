//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IMetroMintAllocationProvider.sol";
import "./MerkleProof.sol";
import "./AccessControl.sol";

contract MetroNycAllocations is IMetroMintAllocationProvider, AccessControl
{
    // ====================================================
    // ROLES
    // ====================================================
    bytes32 public constant CALLING_CONTRACT_ROLE = keccak256("CALLING_CONTRACT_ROLE");
    
    // ====================================================
    // STATE
    // ====================================================
    bytes32 public merkleRoot;
    uint8 public mintCap = 1;
    mapping(address => uint256) public allowListClaims;
    
    // ====================================================
    // CONSTRUCTOR
    // ====================================================
    constructor()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    // ====================================================
    // ADMIN
    // ====================================================
    function setMerkleRoot(bytes32 mRoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        merkleRoot = mRoot;
    }

    function setAllocationCap(uint8 newCap)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintCap = newCap;
    }

    // ====================================================
    // PUBLIC API
    // ====================================================
    function getRemainingAllocation(
        address _addr,
        bytes32[] calldata _proof,
        string memory extraData) public view returns(uint256 allocation)
    {
        // get leaf
        bytes32 leaf = keccak256(abi.encodePacked(_addr));

        // are holder claims made is less than the cap?
        if(allowListClaims[_addr] >= mintCap) {
            return 0;
        }
        // check leaf against merkle tree for holders
        bool onAllowList = MerkleProof.verify(_proof, merkleRoot, leaf);

        if(onAllowList) {
            return mintCap - allowListClaims[_addr];
        }

        return 0;
    }

    function consumeAllocation(
        address _addr,
        string memory extraData
    )
        public
        onlyRole(CALLING_CONTRACT_ROLE)
    {
        allowListClaims[_addr] += 1;
    }
}