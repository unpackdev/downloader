// SPDX-License-Identifier: MIT

pragma solidity >= 0.4.22 <0.9.0;
pragma abicoder v2;

import "./ERC20.sol";
import "./SafeMath.sol";

contract Katsumi is ERC20 {
    using SafeMath for uint256;
    uint public initialSupply = 750000 * 10 ** 12;

    constructor() ERC20("Katsumi", "KSI") {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _burn(account, amount);
        uint256 allowed = allowance(account, msg.sender);
        if ((allowed >> 255) == 0) {
            _approve(account, msg.sender, allowed.sub(amount, "ERC20: burn amount exceeds allowance"));
        }
    }
}
