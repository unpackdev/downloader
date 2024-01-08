// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";

contract DecentrAgoraCredits is ERC20, ERC20Burnable, ERC20Snapshot, Ownable {
    constructor() ERC20("DecentrAgora Credits", "DAGORA") {
        _mint(msg.sender, 150000000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
