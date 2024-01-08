// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title MethodicalMooseTradable
 * MethodicalMooseTradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract MethodicalMooseTradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 public constant SUPPLY = 7777;
    uint256 public constant MAX_PER_PURCHASE = 20;
    uint constant startingIndex = 0; 
    uint256 public nextMooseForSale;
    uint256 public price = 30000000000000000;  // 0.03 ETH for one moose
    

    constructor(){
        nextMooseForSale = startingIndex;
    }

    function mintMoose(uint256 mooseToBuy) public payable {
        uint256 totalSupply = totalSupply();

        require(mooseToBuy > 0 && mooseToBuy < MAX_PER_PURCHASE + 1, "Improper amount of moose to purchase");
        require(totalSupply + mooseToBuy < SUPPLY + 1, "Not enough moose left for sale");
        require(msg.value >= price.mul(mooseToBuy), "Insufficient funds sent.");
        
        for(uint256 i = 0; i < mooseToBuy; i++){
            _safeMint(msg.sender, totalSupply + i);
        }

        nextMooseForSale += mooseToBuy;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function baseTokenURI() virtual public pure returns (string memory);

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId),".json"));
    }
}