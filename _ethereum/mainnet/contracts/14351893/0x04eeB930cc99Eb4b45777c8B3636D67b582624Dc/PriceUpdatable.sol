// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
 

abstract contract PriceUpdatable is Ownable {

    uint256 public price = 0.08 ether;

    // update price
    function updatePrice(uint256 _newPrice)
        external
        onlyOwner
    {
        require(
            _newPrice >= 0.01 ether,
            "Price too low"
        );

        require(
            _newPrice < 5 ether,
            "Price too high"
        );

        price = _newPrice;
    }
    

}
