pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";

contract WolfGang is ERC721, Ownable {
    using SafeMath for uint;
    
    uint public constant MAX_WOLFS = 10000;

    uint public price;
    bool public hasSaleStarted = false;

    address firstAccountAddress;
    address secondAccountAddress;
    
    event WolfMinted(uint tokenId, address owner);
    
    constructor(string memory baseURI, address _firstAccountAddress, address _secondAccountAddress) ERC721("The WolfGang", "WOLF") {
        setBaseURI(baseURI);
        price = 0.03 ether;
        firstAccountAddress = _firstAccountAddress;
        secondAccountAddress = _secondAccountAddress;
    }
    
    function mint(uint quantity) public payable {
        mint(quantity, msg.sender);
    }
    
    function mint(uint quantity, address receiver) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= MAX_WOLFS, "sold out");
        require(msg.value >= price.mul(quantity) || msg.sender == owner(), "ether value sent is below the price");
        
        payable(firstAccountAddress).transfer(msg.value.mul(40).div(100));
        payable(secondAccountAddress).transfer(msg.value.mul(60).div(100));
        
        for (uint i = 0; i < quantity; i++) {
            uint mintIndex = totalSupply();
            _safeMint(receiver, mintIndex);
            emit WolfMinted(mintIndex, receiver);
        }
    }
    
    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
}