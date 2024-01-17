//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";
import "./ERC721Enumerable.sol";

contract CandidCowsClub is ERC721A, Ownable { 
    using SafeMath for uint256;

    uint public constant MAX_SUPPLY = 10000; 
    uint public constant PRICE = 0.008 ether; 
    uint public constant MAX_PER_MINT = 5; 
    uint public constant MAX_FREE_MINTS = 1;
    mapping(address => uint256) public candidCowsOwned;
    mapping(address => uint256) public whiteCandidCowsOwned;

    bool public preMintPhase = true;
    bool public isMintLive = false; 
    string private baseTokenURI;
    string private whitelistProof;

    constructor(string memory baseURI) ERC721A("CandidCowsClub", "CCC") payable {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setWhitelistProof(string memory _whitelistProof) public onlyOwner {
        whitelistProof = _whitelistProof;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function toggleSalesPhase() public onlyOwner {
        preMintPhase = !preMintPhase;
    }

    function toggleMintGoLive() public onlyOwner {
        isMintLive = !isMintLive;
    }

    
    function mintNFTs(uint _count) public payable {
        uint256 totalSupply = totalSupply(); 
        require(isMintLive, "Mint is not live yet!");
        require(!preMintPhase, "Public phase not started yet");
        require((totalSupply + _count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && (candidCowsOwned[msg.sender] + _count) <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        if((candidCowsOwned[msg.sender] + whiteCandidCowsOwned[msg.sender]) < MAX_FREE_MINTS){
            require(msg.value >= PRICE.mul(_count-1), "Not enough ether to purchase NFTs.");
             _safeMint(msg.sender, _count);
        } else {
            require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");
             _safeMint(msg.sender, _count);
        } 
        candidCowsOwned[msg.sender] += _count;    
    }

    function preMintNFTs(uint _count, string memory _proof) public payable {
        uint256 totalSupply = totalSupply(); 
        require(isMintLive, "Mint is not live yet!");
        require(preMintPhase, "Public phase already started");
        require((totalSupply + _count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && (whiteCandidCowsOwned[msg.sender] + _count) <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(keccak256(bytes(whitelistProof)) == keccak256(bytes(_proof)), "Proof not eligible.");
        if((candidCowsOwned[msg.sender] + whiteCandidCowsOwned[msg.sender]) < MAX_FREE_MINTS){
            require(msg.value >= PRICE.mul(_count-1), "Not enough ether to purchase NFTs.");
             _safeMint(msg.sender, _count);
        } else {
            require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");
             _safeMint(msg.sender, _count);
        } 
        whiteCandidCowsOwned[msg.sender] += _count;     
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }  
}