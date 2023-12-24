// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";

contract DMXAllowlist is OwnableUpgradeable {
    
    struct AllowGroup {
        bytes32 merkleRoot;
        mapping(address => bool) claimed;
    }
    //mapping(string => AllowGroup) public allowgroups;
    uint allowgroup_count;
    mapping(string => AllowGroup) public allowgroups;
    MintPhase public mintPhase;
    bytes32 public allowlistMerkleRoot;
    bytes32 public invitelistMerkleRoot;
    address public hero;
    mapping(address => bool) public allowlist_claimed;
    mapping(address => bool) public invitelist_claimed;
    uint public invitationlistMax;
    uint public allowlistMax;
    //enum HeroType{ CUSTOM, GENESIS, COMMON }
    enum MintPhase{OFF, INVITATIONLIST, ALLOWLIST, PUBLIC}

    function initialize()  public initializer {
        allowgroup_count = 0;
        mintPhase = MintPhase.OFF;
        invitationlistMax = 1;
        allowlistMax = 1;
        __Ownable_init();
    }
   function setHero(address HeroContract) public onlyOwner {
        hero = HeroContract;
    }
    
    function setMintPhase(MintPhase mint_phase) public onlyOwner {
        mintPhase = mint_phase;
    }
    function setAllowlistMax(uint AllowListMax) public onlyOwner {
        allowlistMax = AllowListMax;
    }
    function setInvitationlistMax(uint InvitationListMax) public onlyOwner {
        invitationlistMax = InvitationListMax;
    }
  function validateAndMintOnAllowgroup(address MinterCandidate, bytes32[] calldata _merkleProof, string calldata GroupName) public {
        bytes32 leaf = keccak256(abi.encodePacked(MinterCandidate));
        require(msg.sender == hero, "only the hero contract can call this function");
        require(mintPhase == MintPhase.INVITATIONLIST, "not in invitationlist mode");
        require(!allowgroups[GroupName].claimed[MinterCandidate], "slot already claimed");
        require(MerkleProof.verify(_merkleProof, allowgroups[GroupName].merkleRoot, leaf), "ag merkle proof failed");
        allowgroups[GroupName].claimed[MinterCandidate] = true;
       
    }

    function validateAndMintOnAllowlist(address MinterCandidate, bytes32[] calldata _merkleProof, MintPhase Phase) public {
        bytes32 leaf = keccak256(abi.encodePacked(MinterCandidate));
        require(msg.sender == hero, "only the hero contract can call this function");
        require(mintPhase == Phase, "not in invitationlist mode");
        if(Phase == MintPhase.INVITATIONLIST) {
            require(!invitelist_claimed[MinterCandidate], "slot already claimed");
            require(MerkleProof.verify(_merkleProof, invitelistMerkleRoot, leaf), "il merkle proof failed");
            invitelist_claimed[MinterCandidate] = true;
        }
        else if(Phase == MintPhase.ALLOWLIST) {
            require(!allowlist_claimed[MinterCandidate], "slot already claimed");
            require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf), "al merkle proof failed");
            allowlist_claimed[MinterCandidate] = true;
        }
    }
    function canAddressMintInvitationPhase(address MintingAddress, bytes32[] calldata _merkleProof)
    public view returns (bool can_mint) {
        bytes32 leaf = keccak256(abi.encodePacked(MintingAddress));
        if(!invitelist_claimed[MintingAddress] && MerkleProof.verify(_merkleProof, invitelistMerkleRoot, leaf)) {
            return true;
        }
        return false;
    }

    function canAddressMintAllowlistPhase(address MintingAddress, bytes32[] calldata _merkleProof)
    public view returns (bool can_mint) {
        bytes32 leaf = keccak256(abi.encodePacked(MintingAddress));
        if(!allowlist_claimed[MintingAddress] && MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf)) {
            return true;
        }
        return false;
        
    }
    
    function canAddressMintAllowgroup(address MintingAddress, bytes32[] calldata _merkleProof, string calldata GroupName)
    public view returns (bool can_mint) {
        bytes32 leaf = keccak256(abi.encodePacked(MintingAddress));
        if(!allowgroups[GroupName].claimed[MintingAddress] && MerkleProof.verify(_merkleProof, allowgroups[GroupName].merkleRoot, leaf)) {
            return true;
        }
        return false;
        
    }
    function setAllowlistMerkleRoot(bytes32 root) public onlyOwner {
        allowlistMerkleRoot = root;
    }

    function setInvitelistMerkleRoot(bytes32 root) public onlyOwner {
        invitelistMerkleRoot = root;
    }

    function resetAllowlistClaimed(address to_reset) public onlyOwner {
        allowlist_claimed [to_reset] = false;
    }

    function addNewAllowGroup(string calldata AllowgroupName, bytes32 root) public onlyOwner {
        AllowGroup storage newAllowGroup = allowgroups[AllowgroupName];
        newAllowGroup.merkleRoot = root;
    }
}