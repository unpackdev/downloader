// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";

import "./Helper.sol";
import "./TokenGeneratorMetadata.sol";

/**
 * @title CMT_v2_B_X
 * @author Create My Token (https://www.createmytoken.com/)
 * @dev Implementation of the CMT_v2_B_X
 */
contract CMT_v2_B_X is ERC20, Helper, TokenGeneratorMetadata {
    constructor(
        string memory __cmt_name,
        string memory __cmt_symbol,
        uint256 __cmt_initial
    ) payable ERC20(__cmt_name, __cmt_symbol) {
        require(__cmt_initial > 0, "ERC20: supply cannot be zero");

        _mint(_msgSender(), __cmt_initial);
    }
}
