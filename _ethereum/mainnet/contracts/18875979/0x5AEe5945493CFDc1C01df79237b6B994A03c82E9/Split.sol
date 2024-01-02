// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FundSplitter {
    address payable public deployerWallet;
    address payable public gasWallet;
    address payable public serviceWallet;

    constructor(address payable _deployerWallet, address payable _gasWallet, address payable _serviceWallet) {
        deployerWallet = _deployerWallet;
        gasWallet = _gasWallet;
        serviceWallet = _serviceWallet;
    }

    receive() external payable {
        require(msg.value > 0, "Invalid amount");

        uint256 amountDeployer = (msg.value * 63) / 100;
        uint256 amountGas = (msg.value * 22) / 100;
        uint256 amountService = msg.value - amountDeployer - amountGas;

        deployerWallet.transfer(amountDeployer);
        gasWallet.transfer(amountGas);
        serviceWallet.transfer(amountService);
    }
}
