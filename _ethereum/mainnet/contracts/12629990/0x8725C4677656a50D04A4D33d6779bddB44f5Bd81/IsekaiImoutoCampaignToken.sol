// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./ERC20Burnable.sol";

contract IsekaiImoutoCampaignToken is ERC20Burnable {
    constructor() ERC20("Isekai Imouto Campaign Token", "IICT") {
        _mint(msg.sender, 100000 ether); // 1000 token x 100 recipients
    }
}
