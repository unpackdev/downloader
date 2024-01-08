//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Transfers.sol";

contract Service is Transfers {
    address public controller;
    address public ETHUSDPriceFeed;
    address public pETH;

    constructor(address controller_, address ETHUSDPriceFeed_, address pETH_) {
        require(
            controller_ != address(0)
            && ETHUSDPriceFeed_ != address(0)
            && pETH_ != address(0),
            "Service::Constructor: address is 0"
        );

        controller = controller_;
        ETHUSDPriceFeed = ETHUSDPriceFeed_;
        pETH = pETH_;
    }

    function checkBorrowBalance(address account) public view returns (bool) {
        uint sumBorrow = calcAccountBorrow(account);

        if (sumBorrow != 0) {
            uint ETHUSDPrice = uint(AggregatorInterface(ETHUSDPriceFeed).latestAnswer());
            uint loan = sumBorrow * ETHUSDPrice / 1e8 / 1e18; // 1e8 is chainlink, 1e18 is eth

            return loan < 1;
        }

        return true;
    }

    function calcAccountBorrow(address account) public view returns (uint) {
        uint sumBorrow;

        address[] memory assets = ControllerInterface(controller).getAssetsIn(account);
        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            uint borrowBalance = PTokenInterface(asset).borrowBalanceStored(account);
            uint price = ControllerInterface(controller).getOracle().getUnderlyingPrice(asset);

            if (asset == pETH) {
                sumBorrow += price * borrowBalance / 10 ** 18;
            } else {
                sumBorrow += price * borrowBalance / (10 ** ERC20(PTokenInterface(asset).underlying()).decimals());
            }
        }

        return sumBorrow;
    }
}
