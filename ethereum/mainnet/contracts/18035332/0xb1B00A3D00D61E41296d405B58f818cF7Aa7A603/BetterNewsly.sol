// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/*
 BetterNewsly - The Better News Trading Terminal in Your Pocket
 Twitter: https://twitter.com/BetterNewsly
 Community: https://t.me/+Jm3OIlXxemc5ZDI0
 News Feed: https://t.me/BetterNewsly
 TG Bot: https://t.me/BetterNewslyBot
*/

contract BetterNewsly is ERC20, Pausable, Ownable {

    address public constant DEV_WALLET = 0x59aeb8663fF706bd8E16aF68D940491D0516e168;

    constructor() ERC20("BetterNewsly", "NEWSLY") {
        _mint(msg.sender, 800_000_000 * 10 ** decimals()); // 80% Liquidity
        _mint(DEV_WALLET, 200_000_000 * 10 ** decimals()); // 20% Dev Wallet
        pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}