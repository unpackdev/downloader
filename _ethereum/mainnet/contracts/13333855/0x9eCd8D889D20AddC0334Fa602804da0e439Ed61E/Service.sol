//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Interfaces.sol";
import "./Transfers.sol";

contract Service is Transfers {
    address public controller;
    address public pETH;

    constructor(address controller_, address pETH_) {
        require(
            controller_ != address(0)
            && pETH_ != address(0),
            "Service::Constructor: address is 0"
        );

        controller = controller_;
        pETH = pETH_;
    }

    function checkBorrowBalance(address account) public view returns (bool) {
        return calcAccountBorrow(account) <= 1e18;
    }

    function calcAccountBorrow(address account) public view returns (uint) {
        uint sumBorrow;

        address[] memory assets = ControllerInterface(controller).getAssetsIn(account);
        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            uint borrowBalance = PTokenInterface(asset).borrowBalanceStored(account);
            uint price = ControllerInterface(controller).getOracle().getUnderlyingPrice(asset);

            uint underlyingDecimal = asset == pETH ? 18 : ERC20(PTokenInterface(asset).underlying()).decimals();
            sumBorrow += price * borrowBalance / 10 ** underlyingDecimal;
        }

        return sumBorrow;
    }
}
