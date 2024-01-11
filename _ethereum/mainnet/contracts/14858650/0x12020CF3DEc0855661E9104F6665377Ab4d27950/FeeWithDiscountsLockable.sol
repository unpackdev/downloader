// SPDX-License-Identifier: UNLICENSED
/// @title FeeWithDiscountsLockable
/// @notice Adds discounts to FeeLockable
/// @author CyberPnk <cyberpnk@cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./FeeLockable.sol";

abstract contract FeeWithDiscountsLockable is Ownable, FeeLockable {
    bool public isChangeDiscountsDisabled = false;
    mapping (address => uint16) public addressToDiscount;

    // Irreversible.
    function disableChangeDiscounts() public onlyOwner {
        isChangeDiscountsDisabled = true;
    }

    // discount from 0 to 10000, meaning from 0% to 100% (100% = discount it all, = free)
    function setDiscount(address discountReceiver, uint16 discount) public onlyOwner {
        require(!isChangeDiscountsDisabled, "Disabled");
        require(discount <= 10000, "Wrong discount");
        addressToDiscount[discountReceiver] = discount;
    }

    function feeAmount() public override view returns(uint) {
        return (super.feeAmount() * (10000 - addressToDiscount[msg.sender])) / 10000;
    }

}
