// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./Context.sol";
import "./Ownable.sol";
import "./ERC20Capped.sol";
import "./IVITA.sol";

contract VITA is IVITA, ERC20Capped, Ownable {

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_
    ) ERC20(name_, symbol_) ERC20Capped(cap_) {

    }

    function mint(address account, uint256 amount) public override onlyOwner {
        _mint(account, amount);
    }
}
