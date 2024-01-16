// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";

contract Tandoorio is ERC20Capped, ERC20Burnable {

    address payable public owner;

    uint256 feeInPercentage = 5;

    constructor(uint256 cap) ERC20("Tandoorio", "TAN") ERC20Capped(cap * (10 ** decimals())) {
        owner = payable(msg.sender);

        _mint(owner, cap * (10 ** decimals()));
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 amountToTransfer = amount;
        uint256 amountToBurn = calculateBurnableFee(amount);

        amountToTransfer = amount - amountToBurn;
        burn(amountToBurn);

        super._transfer(from, to, amountToTransfer);
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    modifier onlyOwner {
        require (msg.sender == owner, "Only owner is authorized to call this function");
        _;
    }

    function calculateBurnableFee(uint256 amount) public view returns (uint256) {
        return amount * feeInPercentage / 100;
    }
}