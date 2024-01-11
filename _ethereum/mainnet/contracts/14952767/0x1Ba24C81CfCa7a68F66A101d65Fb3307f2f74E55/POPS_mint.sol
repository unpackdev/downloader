// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";

interface POPS_nft{
    function mint(address to, uint256 tokenId) external;
}

contract POPS_mint is Ownable {

    ///// EVENTS /////
    event mintingInitialized(address _POPScontract, uint256 _start_time);


    ///// CONTRACT VARIABLES /////

    bool public restrictedToWhitelist = true;
    uint256 constant private reservedPerTeamMember = 5;                                                   // Number of POPs reserved per team member
    uint256 public mintStart;                                                                             // Unix timestamp
    uint256 private nextId;                                                                               // Next mintable ID
    uint256 private nextReservedId;                                                                       // Next reserved ID redeemable by the team
    uint256 private numTeamMembers;                                                                       // Number of team members
    address public POPS_address;                                                                          // POPS NFT contract
    mapping(address => bool) public isTeamMember;                                                         // Is a team member?
    mapping(address => bool) public claimed;                                                              // Tracks whitelist addresses that have already claimed
    bytes32 public whitelist_merkleRoot;                                                                  // MerkleRoot of the whitelist


    ///// CONSTRUCTOR /////

    constructor() Ownable(){}


    ///// FUNCTIONS - BEFORE SALE /////

    // [Tx][Public][Owner] Add team member to the reserved list
    function addTeamMember(address _address) public onlyOwner{
        require(!isTeamMember[_address], "Already a team member");
        isTeamMember[_address] = true;
        numTeamMembers++;
    }

    // [Tx][Public][Owner] Remove team member from the list
    function removeTeamMember(address _address) public onlyOwner{
        require(isTeamMember[_address], "Not a team member");
        delete isTeamMember[_address];
        numTeamMembers--;
    }

    // Put some POPs aside for the team
    function reserveToTeam() public onlyOwner {
        require(nextId == 0 && block.timestamp < mintStart, "Team reserve amount locked");
        nextId=numTeamMembers*reservedPerTeamMember;
    }

    // [Tx][Public][Owner] Setup the minting
    function setupMinting(address _POPScontract, bytes32 _whitelist_merkleRoot) public onlyOwner{
        require(mintStart == 0, "Minting already initialized");
        require(_POPScontract != address(0) && _whitelist_merkleRoot != bytes32(0), "Input error");
        whitelist_merkleRoot = _whitelist_merkleRoot;
        POPS_address = _POPScontract;
    }

    // [Tx][Public][Owner] Initialize the minting
    function initializeMinting(uint256 _start_time) public onlyOwner{
        require(mintStart == 0, "Minting already initialized");
        require(POPS_address != address(0) && whitelist_merkleRoot != bytes32(0), "Sale not configured");
        require(_start_time > block.timestamp, "Start time cannot be in the past");
        mintStart = _start_time;
        emit mintingInitialized(POPS_address, _start_time);
    }


    ///// FUNCTIONS - DURING SALE /////

    // [View][Public] Get available POPS
    function availableToMint() view public returns(uint256){
        return 10000 - nextId;
    }

    // [View][Public] Check if in whitelist
    function whitelistClaimable(address _account, bytes32[] calldata _merkleProof) view public returns(bool){
        if(claimed[_account]) return false;
        else return MerkleProof.verify(_merkleProof, whitelist_merkleRoot, keccak256(abi.encode(_account)));
    }

    // [Tx][Public] Main mint function
    function mintPOP(bytes32[] calldata _whitelist_merkleProof) public {
        require(block.timestamp > mintStart, "Minting hasn't started");
        require(nextId<10000, "All available POPs have been minted");
        if (restrictedToWhitelist) require(whitelistClaimable(msg.sender, _whitelist_merkleProof), "Address not in whitelist");
        else require(!claimed[msg.sender], "Already minted");
        claimed[msg.sender] = true;
        POPS_nft(POPS_address).mint(msg.sender, nextId);
        nextId++;
    }

    // [Tx][Public] Mint function for team members
    function teamMemberClaim() public {
        require(block.timestamp > mintStart, "Minting hasn't started");
        require(isTeamMember[msg.sender] && !claimed[msg.sender], "Not entitled to claim");
        claimed[msg.sender] = true;
        for(uint256 i; i<reservedPerTeamMember; i++) {
            POPS_nft(POPS_address).mint(msg.sender, nextReservedId);
            nextReservedId++;
        }
    }

    // [Tx][Public][Owner] Open minting to non-whitelisted addresses
    function allowAnyoneToMint() public onlyOwner {
        restrictedToWhitelist = false;
    }

}