// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract Donut is ERC20Pausable, Ownable {
    uint256 public maxSupplyAmount = 100*(10**8)*(10**18);

    constructor() ERC20("Donut", "DONUT") {
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(ERC20.totalSupply() + amount <= maxSupplyAmount, "ERC20: cap exceeded");
        _mint(account, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}