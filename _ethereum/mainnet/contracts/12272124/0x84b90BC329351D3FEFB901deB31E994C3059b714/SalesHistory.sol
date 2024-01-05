// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";

contract SalesHistory {

    struct HistoryEntry {
        address tokenAddress;
        uint256 offeringId;
        address buyer;
        address recipient;
        uint256 price;
        uint256 timestamp;
    }

    HistoryEntry[] allSales;

    function getSales(uint256 start, uint256 length) public view returns (HistoryEntry[] memory sales) {
        require(start < allSales.length);
        uint256 remaining = allSales.length - start;
        uint256 actualLength = remaining < length ? remaining : length;
        sales = new HistoryEntry[](actualLength);

        for (uint256 idx = 0; idx < actualLength; idx++) {
            sales[idx] = allSales[idx+start];
        }

        return sales;
    }

    function postSale(address tokenAddress, uint256 offeringId, address buyer, address recipient, uint256 price, uint256 timestamp) internal {
        allSales.push();
        uint256 idx = allSales.length - 1;
        allSales[idx].tokenAddress = tokenAddress;
        allSales[idx].offeringId = offeringId;
        allSales[idx].buyer = buyer;
        allSales[idx].recipient = recipient;
        allSales[idx].price = price;
        allSales[idx].timestamp = timestamp;
    }
}
