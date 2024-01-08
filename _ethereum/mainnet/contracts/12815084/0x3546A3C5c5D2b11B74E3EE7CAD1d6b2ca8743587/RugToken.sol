// contracts/RugToken.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./ERC20Rug.sol";

contract RugToken is ERC20Rug {
    event Burn(address accountFrom, address accountTo, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        address newOwner
    ) public ERC20(name, symbol) ERC20Capped(300_000_000 * (10**18)) {
        transferOwnership(newOwner);
        require(owner() == newOwner, "Ownership not transferred");
        ERC20._mint(newOwner, 300_000_000 * (10**18));
    }

    function burn(uint256 amount) public override returns (bool) {
        ERC20._burn(_msgSender(), amount);
        emit Burn(_msgSender(), address(0), amount);
        return true;
    }
}
