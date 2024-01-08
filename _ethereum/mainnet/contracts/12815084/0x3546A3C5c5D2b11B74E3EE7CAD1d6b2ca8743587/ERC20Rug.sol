// contracts/ERC20Rug.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./ERC20Capped.sol";
import "./Ownable.sol";

abstract contract ERC20Rug is ERC20Capped, Ownable {
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function burn(uint256 amount) public virtual returns (bool);
}
