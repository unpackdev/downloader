// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract MadDogsNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string _baseTokenURI;
    // Price and Supply
    uint256 private MAX_MINT = 20;
    uint256 private MAX_WHITELIST_MINT = 1;
    uint256 private RESERVED_TOKENS = 200;
    uint256 public MINT_FEE_PER_TOKEN = 0.02 ether;
    uint public constant MAX_SUPPLY = 10000;
    bool public paused = true;
    bool public whitelistPaused = true;

    mapping(address => bool) public whitelist;

    uint internal nonce = 0;
    uint [MAX_SUPPLY] internal indices;

    constructor(string memory baseURI) ERC721("Mad Dogs NFT", "MADDOGS")  {
        setBaseURI(baseURI);
    }

    function addToWhitelist(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!whitelist[entry], "DUPLICATE_ENTRY");
            whitelist[entry] = true;
        }   
    }

    function removeFromWhitelist(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            whitelist[entry] = false;
        }
    }

    function randomIndex() internal returns (uint256) {
        uint256 totalSize = MAX_SUPPLY - totalSupply();
        uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint256 value = 0;
    if (indices[index] != 0) {
        value = indices[index];
    } else {
        value = index;
    }
    if (indices[totalSize - 1] == 0) {
        indices[index] = totalSize - 1;
    } else {
        indices[index] = indices[totalSize - 1];
    }
    nonce++;
    return value.add(1);
    }

    function _mintWithRandomTokenId(address _to) private {
        uint _tokenID = randomIndex();
        _safeMint(_to, _tokenID);
    }

    function mintDog(uint256 num) public payable {
        uint256 supply = totalSupply();
        if(msg.sender != owner()) {
        require(!paused,                                     "Sale paused" );
        require(num < (MAX_MINT + 1),                        "Above mint limit" );
        require(supply + num < MAX_SUPPLY - RESERVED_TOKENS, "Not enough dogs" );
        require(msg.value >= MINT_FEE_PER_TOKEN * num,       "Check ether value" );
        }
        for(uint256 i; i < num; i++){
            _mintWithRandomTokenId(msg.sender);
        }
    }

    function mintWhitelistDog(uint256 num) public payable {
        uint256 supply = totalSupply();
        if(msg.sender != owner()) {
        require(!whitelistPaused,                            "Whitelist paused" );
        require(num < (MAX_WHITELIST_MINT + 1),              "Above mint limit" );
        require(supply + num < MAX_SUPPLY - RESERVED_TOKENS, "Not enough dogs" );
        require(msg.value >= MINT_FEE_PER_TOKEN * num,       "Check ether value" );
        }
        for(uint256 i; i < num; i++){
            _mintWithRandomTokenId(msg.sender);
        }
    }

    function giveawayDog(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= RESERVED_TOKENS, "Above reserved qty" );
        for(uint256 i; i < _amount; i++){
            _mintWithRandomTokenId(_to);
        }
        RESERVED_TOKENS -= _amount;
    }

    function getPrice() public view returns (uint256){
        return MINT_FEE_PER_TOKEN;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        MINT_FEE_PER_TOKEN = _newPrice;
    }

    function getMaxMint() public view returns (uint256){
        return MAX_MINT;
    }

    function setMaxMint(uint256 _newMaxMint) public onlyOwner() {
        MAX_MINT = _newMaxMint;
    }

    function setMaxWhitelistMint(uint256 _newMaxWhitelistMint) public onlyOwner() {
        MAX_WHITELIST_MINT = _newMaxWhitelistMint;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function pause(bool val) public onlyOwner {
        paused = val;
    }

    function pauseWhitelist(bool val) public onlyOwner {
        whitelistPaused = val;
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}