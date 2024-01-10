// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

/**
 * @title Rabbit
 * Rabbit - a contract for my non-fungible raging rabbits.
 */
contract Rabbit is ERC721Tradable {

    using Counters for Counters.Counter;

    string baseTokenUri;

    uint256 public maxMintAmount = 11111;
    uint256 public cost = 0.055 ether;
    uint256 public whiteListCost = 0.033 ether;

    bool public paused = true;
    bool public onlyWhitelisted = true;

    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) public freeMintsRemaining;

    constructor(address _proxyRegistryAddress, string memory _baseTokenUri, bytes32 _whitelistMerkleRoot,
     address[] memory freeMintAddresses, uint256[] memory freeMintValues)
        ERC721Tradable("RagingRabbits", "RR", _proxyRegistryAddress)
    {
        baseTokenUri = _baseTokenUri;
        whitelistMerkleRoot = _whitelistMerkleRoot;

        for (uint256 i = 0; i < freeMintAddresses.length; i++) {  
            freeMintsRemaining[freeMintAddresses[i]] = freeMintValues[i];
        }

    }

    function baseTokenURI() override view public returns (string memory) {
        return baseTokenUri;
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.ragingrabbits.co/";
    }

    function mint(uint256 _quantity) public payable {

        require(msg.value >= cost * _quantity, "insufficient funds");
        require(!paused, "contract is paused");
        require(onlyWhitelisted == false, "public sale not open yet");
       
        mintCommon(_quantity);
        
    }

    function whitelistMint(uint256 _quantity, bytes32[] calldata _merkleProof) public payable {

        require(msg.value >= whiteListCost * _quantity, "insufficient funds");
        require(!paused, "contract is paused");
        require(isWhitelisted(msg.sender, _merkleProof), "user is not whitelisted");

        mintCommon(_quantity);
    
    }

    function freeMint(uint256 _quantity) public {

        require(!paused, "contract is paused");
        require(freeMintsRemaining[msg.sender] >= _quantity, "not enough free mints");

        freeMintsRemaining[msg.sender] -= _quantity;

        mintCommon(_quantity);
    
    }

    function mintCommon(uint256 _quantity) private {

        require(_nextTokenId.current() + _quantity <= maxMintAmount + 1, "not enough tokens available");

         for (uint256 i = 0; i < _quantity; i++) {
         
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msg.sender, currentTokenId);

        }

    }

    function isWhitelisted(address _userAddress, bytes32[] calldata _merkleProof) public view returns (bool) {
       
        bytes32 leaf = keccak256(abi.encodePacked(_userAddress));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);

    }

    function setBaseTokenUri(string memory _baseTokenUri) public onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    } 

    function setWhitelistCost(uint256 _newWlCost) public onlyOwner {
        whiteListCost = _newWlCost;
    } 

    function setWhitelistMerkleRoot(bytes32 _whiteListMerkleRoot) public onlyOwner {
        whitelistMerkleRoot = _whiteListMerkleRoot;
    }

    function setFreeMints(address _userAddress, uint256 _freeMints) public onlyOwner {
        freeMintsRemaining[_userAddress] = _freeMints;
    }

    function withdraw() public onlyOwner {

        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
  }

}
