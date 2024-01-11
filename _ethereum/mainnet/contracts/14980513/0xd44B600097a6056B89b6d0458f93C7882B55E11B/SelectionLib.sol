// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SelectionLib {
    // set struct of selections
    struct Selection {
        string name;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 mintCost;
    }

    struct NFTSelection {
        uint256 id;
        uint256 selectionIndex;
        uint256 selectionId;
    }
}