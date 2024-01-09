// SPDX-License-Identifier: Unlicense
// Developed by EasyChain (easychain.tech)
//
pragma solidity ^0.8.4;

import "./Ownable.sol";

abstract contract ERC721Discounted is Ownable {

    mapping(uint256 => uint256) public discounts;

    function setDiscounts(
        uint256[] memory _amounts, 
        uint256[] memory _discounts
    ) public onlyOwner {
        require(_amounts.length == _discounts.length, "Length not match");

        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_discounts[i] > 0, "Zero discount");
            
            discounts[_amounts[i]] = _discounts[i];
        }
    }

    function getDiscountedPrice(uint256 _amount, uint256 _basePrice) public view returns (uint256) {
        uint256 discount = discounts[_amount];
        if (discount == 0) {
            discount = 100;
        }
        return _amount * _basePrice * discount / 100;
    }
}