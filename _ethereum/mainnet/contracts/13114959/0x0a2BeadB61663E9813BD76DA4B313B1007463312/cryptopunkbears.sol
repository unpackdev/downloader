// SPDX-License-Identifier: MIT
//  _____________________________ 
//  \_   ___ \______   \______   \
//  /    \  \/|     ___/|    |  _/
//  \     \___|    |    |    |   \
//   \______  /____|    |______  /
//          \/                 \/ 
// dev : https://twitter.com/mememaniac_eth
// artist : https://twitter.com/thatartsybrown1
// let's save the bears from neffy

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CryptoPunkBears is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _maxMint = 20;
    uint256 private _price = 2 * 10**16; //0.02 ETH;
    bool public _paused = true;
    uint public constant MAX_ENTRIES = 3900;

    constructor(string memory baseURI) ERC721("Crypto Punk Bears", "CryptoPunkBears")  {
        setBaseURI(baseURI);

        // first 25 bears for team and giveaways
        mint(msg.sender, 50);
    }

    function mint(address _to, uint256 num) public payable {
        uint256 supply = totalSupply();

        if(msg.sender != owner()) {
          require(!_paused, "Sale Paused");
          require( num < (_maxMint+1),"You can adopt a maximum of _maxMint Bears" );
          require( msg.value >= _price * num,"Ether sent is not correct" );
        }

        require( supply + num < MAX_ENTRIES,            "Exceeds maximum supply" );

        for(uint256 i; i < num; i++){
          _safeMint( _to, supply + i );
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

    function getPrice() public view returns (uint256){
        if(msg.sender == owner()) {
            return 0;
        }
        return _price;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function getMaxMint() public view returns (uint256){
        return _maxMint;
    }

    function setMaxMint(uint256 _newMaxMint) public onlyOwner() {
        _maxMint = _newMaxMint;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}