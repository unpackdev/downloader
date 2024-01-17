// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721A.sol";

/**
 * @title Inbox3
 * @author maikir
 * @notice Contract for testing for inbox3
 *
 */
contract Inbox3ERC721Tester is
    ERC721A
{
    constructor() ERC721A("Inbox3", "IBX3") {}

    function mint(uint256 quantity) external payable {
        _safeMint(msg.sender, quantity);
    }
}
