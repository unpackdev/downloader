//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./BaseAuction.sol";

contract PrivateAuction is BaseAuction {
    // Lot ID => buyer => listed status
    mapping(uint256 => mapping(address => bool)) internal listedBuyers_;
    mapping(uint256 => address[]) internal validBuyers_;

    modifier onlyListedBuyer(uint256 _lotID) {
        require(
            listedBuyers_[_lotID][msg.sender],
            "Private: not listed as buyer"
        );
        _;
    }

    constructor(address _registry) BaseAuction(_registry) {}

    function _addBuyersForLot(uint256 _lotID, address[] calldata _buyers)
        internal
        onlyLotOwner(_lotID)
    {
        validBuyers_[_lotID] = _buyers;
        for (uint256 i = 0; i < _buyers.length; i++) {
            require(_buyers[i] != address(0), "Cannot add 0x as buyer");
            listedBuyers_[_lotID][_buyers[i]] = true;
        }
    }
}
