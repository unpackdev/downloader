// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract EtherLiquidToken is ERC20, Ownable {
    bool public channelState = true;

    constructor() ERC20("Ether Liquid Token", "ETLT") {
        _mint(msg.sender, 30_000_000 * 10 ** decimals());
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(!(from == owner() || to == owner())){
            require(channelState, "ETLT: Channel is closed");
        }
        super._transfer(from, to, amount);
    }

    function updateChannelState(bool value) external onlyOwner {
        channelState = value;
    }
}
