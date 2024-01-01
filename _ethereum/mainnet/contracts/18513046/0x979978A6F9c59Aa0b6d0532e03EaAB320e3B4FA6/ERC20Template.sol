// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract ERC20Template is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        address owner
    ) ERC20(name, symbol) {
        _transferOwnership(owner);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public whenNotPaused onlyOwner {
        _mint(to, amount);
    }

    function burn(
        uint256 amount
    ) public virtual override whenNotPaused onlyOwner {
        super.burn(amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public virtual override whenNotPaused onlyOwner {
        super.burnFrom(account, amount);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
