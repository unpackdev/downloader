// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ERC20Capped.sol";
import "./Ownable.sol";

contract OMTokenV2 is ERC20Capped, Ownable {
    constructor(address owner_) public ERC20("MANTRA DAO", "OM") ERC20Capped(888888888 * 10**18) {
        transferOwnership(owner_);
    }

    function mint(address account, uint256 amount) external onlyOwner returns (bool success) {
        _mint(account, amount);
        return true;
    }

    function renounceOwnership() public override {
        require(totalSupply() == cap(), "Total supply not equals to cap");
        super.renounceOwnership();
    }
}
