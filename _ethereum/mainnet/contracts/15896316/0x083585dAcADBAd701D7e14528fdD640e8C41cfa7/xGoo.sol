// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";

contract xGoo is ERC20("xGoo", "xGOO"), Ownable {
    address public xGooMinter;

    error Unauthorized();

    constructor(address _xGooMinter) {
        xGooMinter = _xGooMinter;
    }

    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();
        _;
    }

    function mint(address to, uint256 amount) external only(xGooMinter) {
        _mint(to, amount);
    }

    function burn(uint256 amount) external only(xGooMinter) {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external only(xGooMinter) {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender) - amount_;

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }

    function changeMinter(address newMinter) external onlyOwner {
        xGooMinter = newMinter;
    }

}
