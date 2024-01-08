// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./IERC721Enumerable.sol";
import "./Token.sol";

/**
 * @title MSKToken contract
 * @dev Extends my ERC20
 */
contract MSKToken is Token {
    constructor(address _nftAddress, uint256 maskDaoAllocation) Token("Mask Token", "MSK", _nftAddress) {

        // MaskDAO requested allocation
        // They will register a multisig wallet and I will send all these initial tokens to it
        if (maskDaoAllocation > 0) {
            _mint(msg.sender, maskDaoAllocation);
        }

    }
}
