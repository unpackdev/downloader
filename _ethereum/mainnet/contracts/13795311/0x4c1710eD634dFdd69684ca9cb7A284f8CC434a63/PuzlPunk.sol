// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract PuzlPunk is ERC721URIStorage, Ownable {
     using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    
    uint256 public constant MAX_NFT = 100000;
    uint256 public constant MAX_BY_MINT = 20;
    uint256 public constant PRICE = 1 * 10**17;

    address public creatorAddress = msg.sender;

    
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function mintPunk(address recipient, string memory tokenURI)  external returns (uint256) {
        _tokenIdTracker.increment();

        uint256 newItemId = _tokenIdTracker.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;

    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    
    constructor() ERC721("PuzlPunks", "PUZLPUNKS") Ownable() {}
}