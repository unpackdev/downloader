//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Clones.sol";
import "./HogeVendor.sol";

interface IHogeVendor {
    function initialize(uint buyPrice, uint sellPrice) external;
}

contract VendorFactory is Context {

    event VendorCreated(address indexed creator, address indexed vendor);
    address vendorContract;

    constructor(address vendorAddress) {
        vendorContract = vendorAddress;
    }

    function createVendor(uint buyPrice, uint sellPrice) public returns (address new_vendor) {
        //require(buyPrice >= sellPrice, "buyPrice must be larger than sellPrice")
        new_vendor = Clones.clone(vendorContract);
        IHogeVendor(new_vendor).initialize(buyPrice, sellPrice);
        Ownable(new_vendor).transferOwnership(_msgSender());
        emit VendorCreated(_msgSender(), new_vendor);
    }    


}
