/*
         |
        -+-
         A
        /=\               /\  /\    ___  _ __  _ __ __    __
      i/ O \i            /  \/  \  / _ \| '__|| '__|\ \  / /
      /=====\           / /\  /\ \|  __/| |   | |    \ \/ /
      /  i  \           \ \ \/ / / \___/|_|   |_|     \  /
    i/ O * O \i                                       / /
    /=========\        __  __                        /_/    _
    /  *   *  \        \ \/ /        /\  /\    __ _  ____  | |
  i/ O   i   O \i       \  /   __   /  \/  \  / _` |/ ___\ |_|
  /=============\       /  \  |__| / /\  /\ \| (_| |\___ \  _
  /  O   i   O  \      /_/\_\      \ \ \/ / / \__,_|\____/ |_|
i/ *   O   O   * \i
/=================\
       |___|

Christmas Gift enriches the festive season by applying a 1% transaction tax to fund a special Christmas ETH Airdrop to holders on Christmas Day.

https://christmasgifterc.vip/
https://christmasgifterc.vip/
https://x.com/XMASGIFTERC20
https://t.me/XMASGIFTERC20

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

contract ChristmasETHAirdrop is Ownable {
    uint256 public marketingFunds;
    mapping(address => bool) public hasReceivedAirdrop;
    uint256 public christmasDay = 1703523666; // Timestamp for December 25, 2023

    event Airdropped(address recipient, uint256 amount);

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Airdrop ETH to a list of addresses on Christmas day
    function airdropETH(address[] calldata _recipients, uint256 _amountPerRecipient) external onlyOwner {
        require(block.timestamp == christmasDay, "It's not Christmas Day");
        require(address(this).balance >= _recipients.length * _amountPerRecipient, "Insufficient ETH balance");

        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            if (!hasReceivedAirdrop[recipient]) {
                (bool sent, ) = recipient.call{value: _amountPerRecipient}("");
                require(sent, "Failed to send ETH");
                hasReceivedAirdrop[recipient] = true;
                emit Airdropped(recipient, _amountPerRecipient);
            }
        }
    }

    
    receive() external payable {}

   
    function depositETH() external payable {
      
    }
}