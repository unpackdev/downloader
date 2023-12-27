// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title KINGMAKER
 * @author akibe
 */

import "./ERC721APresetToken.sol";

contract KINGMAKER is ERC721APresetToken {
    constructor() ERC721APresetToken('KINGMAKER', 'KING', 1000) {}
}
