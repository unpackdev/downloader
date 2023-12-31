// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

abstract contract ERC20Mintable is Context, Ownable, ERC20 {
    /**
   * @dev Mint tokens
   */
    function mint(address _to, uint256 _amount) onlyOwner public virtual {
        _mint(_to, _amount);
    }
}
