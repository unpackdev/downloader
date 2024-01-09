// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./MutantKongzLab.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract MutantKongzHolders is Ownable {

    MutantKongzLab public mkl;

    uint nonce = 0;
    uint maxTx = 5;

    bool public open = false;

    constructor(){
        mkl = MutantKongzLab(0x030A868Aa956aB97F6ED4431663Ea0F7db0f9aed);
    }

    function changeMKLContract(address new_) external onlyOwner {
        mkl = MutantKongzLab(new_);
    }

    function toggleOpen() external onlyOwner {
        open = !open;
    }

    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function transferMKLOwnership() external onlyOwner {
        mkl.transferOwnership(_msgSender());
    }

    function withdrawMKL() external payable onlyOwner {
        mkl.withdraw();
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function holdersMint(uint qty) external {
        require(mkl.balanceOf(_msgSender()) > 0, "Holders only");
        require(open, "holders mint closed");
        require(qty <= maxTx,"max tx");
        mkl.giveaway(_msgSender(),qty);
    }

}