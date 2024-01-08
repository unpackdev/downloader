// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *
 *                                                     
 *.    .        .               .    .--.     .        
 *|\  /|       _|_   o          |   :    :    |        
 *| \/ |.  ..--.|    .  .-..-.  |   |    |.--.|.-. .--.
 *|    ||  |`--.|    | (  (   ) |   :    ;|   |   )`--.
 *'    '`--|`--'`-'-' `-`-'`-'`-`-   `--' '   '`-' `--'
 *         ;                                           
 *      `-'                                            
 * Brought to you by yourfriend.eth
 *
 * Many thanks to @developer_dao, @_buildspace, @loomnetwork, and @marcelc63 for learning resources and
 * shout out to Adam Bomb Squad, Chain Runners, and CoolCats!
 */

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract MysticalOrbs is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _price = 0.05 ether;
    bool public _paused = true;

    address t1 = 0x8657d00B72C062276e9Db6c6456d6CF0Ff0F24bA;

    constructor(string memory baseURI) ERC721("Mystical Orbs", "ORB")  {
        setBaseURI(baseURI);
        _safeMint( t1, 1);
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 21,                              "You can mint a maximum of 20 Orb NFTs" );
        require( supply + num < 10001,                  "Exceeds maximum NFT supply" );
        require( msg.value >= _price * num,             "Insufficient ether sent." );

        for(uint256 i = 0; i < num; i++){
            _safeMint( msg.sender, supply + i + 1);
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

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance;
        require(payable(t1).send(_each));
    }
}