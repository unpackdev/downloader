// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC1155D.sol";

contract WaveTestDrop is ERC1155 {
    uint256 private currentIndex = 1;
    bool private isFlipped = false;

    constructor() ERC1155("") {}

    function testMint_139E1071() external payable {
        uint256 _currentIndex = currentIndex;

        unchecked {
            _currentIndex++;
        }
        currentIndex = _currentIndex;
    }

    function flip() external {
        isFlipped = !isFlipped;
    }
}