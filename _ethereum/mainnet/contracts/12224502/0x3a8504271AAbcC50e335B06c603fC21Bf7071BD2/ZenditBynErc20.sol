// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract ZenditBynErc20 is ERC20Pausable, Ownable {
    constructor() public ERC20("ZENDIT BYN Placeholder Token", "zenditBYN") Ownable() {
        transferOwnership(0xd0dCdfDa207896a62E7D26C24d247CA895Da4913);
        _mint(owner(), 100000 * 10**18);
    }

    function burn(address account, uint256 amount) external onlyOwner returns (bool success) {
        _burn(account, amount);
        return true;
    }

    function pause() external onlyOwner returns (bool success) {
        _pause();
        return true;
    }

    function unpause() external onlyOwner returns (bool success) {
        _unpause();
        return true;
    }
}
