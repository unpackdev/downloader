// contracts/OasysToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract OasysToken is ERC20, Ownable {
    constructor() ERC20("Oasys Token", "OAS") {
        _mint(msg.sender, 10_000_000_000 * 10**18);
    }

    function mintTo(address account, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }
}
