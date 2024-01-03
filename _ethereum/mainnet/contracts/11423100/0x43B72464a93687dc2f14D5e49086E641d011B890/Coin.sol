// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.8.0;

import "./ERC777.sol";



contract Coin is ERC777 {
    address public lockWallet;
    uint256 public createdAt;
    uint256 public unlockAt;
    constructor(uint256 initialSupply, address[] memory defaultOperators)
        ERC777("4Bulls", "4B",  defaultOperators)
    {
        createdAt = block.timestamp;
        unlockAt = 1767225600;
        lockWallet = 0x26b73F1F1140aBaecd145fab2D877f2e14269Dd1;
        _mint(msg.sender, initialSupply, "", "");
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount)
        internal virtual override
    {
        require(!(block.timestamp < unlockAt && from == lockWallet), "Timelock for wallet");
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}
