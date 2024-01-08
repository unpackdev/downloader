//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Boo.sol";

import "./console.sol";

contract BooFactory is Ownable {
    event BooCreated(address BooAddress, string name);

    function create(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _mintPrice,
        uint256 _itemLimit,
        uint256 _salesStartTime,
        uint256 _numItemsOfOwner
    ) external onlyOwner {
        Boo newBoo = new Boo(
            _name,
            _symbol,
            _baseURI,
            _mintPrice,
            _itemLimit,
            _salesStartTime,
            msg.sender,
            _numItemsOfOwner
        );

        emit BooCreated(address(newBoo), _name);
    }
}
