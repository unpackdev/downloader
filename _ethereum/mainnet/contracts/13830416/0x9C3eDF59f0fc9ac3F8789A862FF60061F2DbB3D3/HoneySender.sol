// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;
import "./Ownable.sol";

import "./IHoney.sol";

contract HoneySender is Ownable {
    mapping(address => uint256) wallets;

    IHoney private honeyContract = IHoney(0xe4c1B13dd712f650E34c1bc1D26Ccfa05F71Ee29);

    // how many honey amounts per wallet
    uint256 public txPerWallet = 2;

    constructor() {}

    /**
     * mints $HONEY to a recipient
     */
    function mint(uint256 amount) external {
        require(wallets[msg.sender] + amount <= txPerWallet, "No more $HONEY");
        wallets[msg.sender] += amount;
        honeyContract.mint(msg.sender, amount * 3000 ether);
    }

    function setTxPerWallet(uint256 _tx) external onlyOwner {
        txPerWallet = _tx;
    }
}
