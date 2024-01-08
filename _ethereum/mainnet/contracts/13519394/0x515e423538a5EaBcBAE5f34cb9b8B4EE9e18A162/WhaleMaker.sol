// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./ERC721Enumerable.sol";


contract WhaleMaker is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string public _baseTokenURI;
  
    /* mint price */
    uint256 private _price = 0.45 ether;
    bool public _paused = false;

    uint256 public maxMintAmount = 2;

    uint256 public endOfWhiteListMint;


    modifier afterClosed() {
        require(block.timestamp >= endOfWhiteListMint, "Distribution is off.");
        _;
    }
    constructor(string memory baseURI) ERC721("Whale Maker", "WHALE")  {
        setBaseURI(baseURI);
    }

    function mintWhale(uint256 num) public payable {
        uint256 supply = totalSupply();
        uint256[] memory arrTokens = walletOfOwner(msg.sender);
        uint256 countOfMinted = arrTokens.length;
        require( !_paused,                              "Sale paused" );
        require( countOfMinted + num <= maxMintAmount ,               "You can mint a maximum of 2 whalesharks per wallet." );
        require( supply + num < 1000,      "Exceeds maximum Whales supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function setMaxMintAmont(uint256 _newAmount) public onlyOwner() {
        maxMintAmount = _newAmount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setEndOfWhiteListMint(uint256 _endOfMint) public onlyOwner {
        endOfWhiteListMint = _endOfMint;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    
    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner afterClosed {
        uint256 _amount = address(this).balance;
        require(payable(_msgSender()).send(_amount));
    }
}