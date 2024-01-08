// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";

import "./ERC20Decimals.sol";
import "./ERC20Mintable.sol";
import "./ERC20Ownable.sol";

import "./Helper.sol";
import "./TokenRecover.sol";

/**
 * @title CMT_v2_B_TR_MB_NC_X
 * @dev Implementation of the CMT_v2_B_TR_MB_NC_X
 */
contract CMT_v2_B_TR_MB_NC_X is
    ERC20Decimals,
    ERC20Capped,
    ERC20Mintable,
    ERC20Burnable,
    ERC20Ownable,
    TokenRecover,
    Helper
{
    constructor(
        string memory __cmt_name,
        string memory __cmt_symbol,
        uint8 __cmt_decimals,
        uint256 __cmt_cap,
        uint256 __cmt_initial
    ) payable ERC20(__cmt_name, __cmt_symbol) ERC20Decimals(__cmt_decimals) ERC20Capped(__cmt_cap) {
        require(__cmt_initial <= __cmt_cap, "ERC20Capped: cap exceeded");
        ERC20._mint(_msgSender(), __cmt_initial);
    }

    function decimals() public view virtual override(ERC20, ERC20Decimals) returns (uint8) {
        return super.decimals();
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) onlyOwner {
        super._mint(account, amount);
    }

    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }
}
