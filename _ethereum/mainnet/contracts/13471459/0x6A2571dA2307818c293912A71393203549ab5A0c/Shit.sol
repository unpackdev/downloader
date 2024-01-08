// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Shit
 * Shit - a contract for my non-fungible pieces of shit.
 */
contract Shit is ERC721Tradable {
    
    mapping (uint256 => uint256) public _hashCodes;
    
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("23 Pieces of Shit", "SHIT", _proxyRegistryAddress)
    {}

    function maxSupply() public view virtual returns (uint256) {
        return 100 ;
    }
    
    function baseTokenURI() public pure returns (string memory) {
        return "https://www.the23.wtf/metadata/";
    }
    
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_hashCodes[_tokenId]), ".json")) ;
    }

    function mint(uint256 _hash) public payable {
        require(msg.value >= 0.04 ether, "Price is 0.04 ETH.") ;
        require(totalSupply() < maxSupply(), "Reached max supply.") ;
        uint256 newTokenId = super._mintTo(msg.sender) ;
        _hashCodes[newTokenId] = _hash ;
    }

    function widthdraw(address payable _recipient, uint _amount) public onlyOwner {
        _recipient.transfer(_amount);
    }

}
