// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract USDC is ERC20, Ownable {
    using SafeMath for uint256;
    
    constructor() ERC20("USDC", "USDC") {
    }

    function mint(address account_, uint256 amount_) external onlyOwner() {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
}