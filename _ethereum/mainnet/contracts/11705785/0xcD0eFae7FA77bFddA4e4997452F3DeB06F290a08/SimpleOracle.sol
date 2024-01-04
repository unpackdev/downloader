// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";

import "./ISimpleOracle.sol";

contract SimpleOracle is Ownable, ISimpleOracle {
    using SafeMath for uint256;

    uint256 public price = 1e18;
    string public name;

    constructor(string memory _name, uint256 _price) public {
        name = _name;

        // Set the initial price to 1.
        price = _price;
    }

    function setPrice(uint256 _price) public onlyOwner {
        require(_price >= 0, 'Oracle: price cannot be < 0');

        price = _price;
    }

    function getPrice() public view override returns (uint256) {
        return price;
    }

    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);
}
