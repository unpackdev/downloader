//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IPrivateSaleFactory.sol";
import "./IPrivateSale.sol";

contract PrivateSaleLens {
    struct SaleData {
        uint96 id;
        address sale;
        string name;
        uint256 maxSupply;
        uint256 amountSold;
        uint256 minAmount;
        uint256 price;
        bool isOver;
        uint256 userBalance;
        uint248 userAmount;
        uint248 userAmountBought;
        bool userIsWhitelisted;
        bool userIsComplient;
    }
    IPrivateSaleFactory public factory;

    constructor(IPrivateSaleFactory _factory) {
        factory = _factory;
    }

    function getSaleData(
        uint256 start,
        uint256 end,
        address user
    ) external view returns (SaleData[] memory availableSale) {
        uint256 len = factory.lenPrivateSales();
        if (end > len) {
            end = len;
        }
        availableSale = new SaleData[](end - start);

        for (uint256 i = start; i < end; i++) {
            IPrivateSale privateSale = IPrivateSale(factory.privateSales(i));
            IPrivateSale.UserInfo memory userInfo = privateSale.userInfo(user);

            if (userInfo.isWhitelisted) {
                availableSale[i - start] = SaleData({
                    id: uint96(i),
                    sale: address(privateSale),
                    name: privateSale.name(),
                    maxSupply: privateSale.maxSupply(),
                    amountSold: privateSale.amountSold(),
                    minAmount: privateSale.minAmount(),
                    price: privateSale.price(),
                    isOver: privateSale.isOver(),
                    userBalance: msg.sender.balance,
                    userAmount: userInfo.amount,
                    userAmountBought: userInfo.amountBought,
                    userIsWhitelisted: userInfo.isWhitelisted,
                    userIsComplient: userInfo.isComplient
                });
            }
        }
    }
}
