// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";

contract XPilgrim is ERC20("xPilgrim", "xPIL"), Ownable {

    function mint(address account, uint256 amount) public onlyOwner {
        return _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        return _burn(account, amount);
    }

}
