// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "./SafeMath.sol";

import "./IERC20.sol";
import "./ILOVE.sol";
import "./IERC20Permit.sol";

import "./ERC20Permit.sol";
import "./LovelyDAOAccessControlled.sol";

contract LovelyDAOERC20Token is ERC20Permit, ILOVE, LovelyDAOAccessControlled {
    using SafeMath for uint256;

    constructor(address _authority)
        ERC20("LovelyDAO", "LOVE", 9)
        ERC20Permit("LovelyDAO")
        LovelyDAOAccessControlled(ILovelyDAOAuthority(_authority))
    {}

    function mint(address account_, uint256 amount_) external override onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external override {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}