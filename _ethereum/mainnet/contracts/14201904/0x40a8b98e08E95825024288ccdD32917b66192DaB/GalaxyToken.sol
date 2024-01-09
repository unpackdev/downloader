// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

//  GalaxyToken: ERC20-compatible fungible wrapped galaxy token
//
//    This contract implements a simple ERC20-compatible fungible token. It's deployed
//    and owned by the Treasury. The Treasury mints and burns these tokens when it
//    processes deposits and withdrawals.

contract GalaxyToken is Context, Ownable, ERC20 {
    constructor() Ownable() ERC20("WrappedGalaxy", "WGLX") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function ownerBurn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function destroyAndSend(address payable _recipient) public onlyOwner {
        require(totalSupply() == 0, "GalaxyToken: not empty");
        selfdestruct(_recipient);
    }
}
