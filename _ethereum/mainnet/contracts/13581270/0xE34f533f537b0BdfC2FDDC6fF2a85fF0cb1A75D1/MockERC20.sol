// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.8;


import "./Ownable.sol";
import "./ERC20.sol";


contract MockERC20 is ERC20, Ownable {
    // solhint-disable-next-line func-visibility
    constructor (string memory name, string memory symbol) ERC20(name, symbol) {}// solhint-disable-line no-empty-blocks

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
