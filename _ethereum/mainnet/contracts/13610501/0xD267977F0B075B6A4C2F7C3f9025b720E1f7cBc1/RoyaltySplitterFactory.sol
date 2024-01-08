// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./RoyaltySplitter.sol";

contract RoyaltySplitterFactory {

    event RoyaltySplitterCreated(address indexed royaltySplitter);

    function createRoyaltySplitter(address[] memory participants, uint256[] memory cuts, string[] memory participantsNames, string memory name) external {
        RoyaltySplitter royaltySplitter = new RoyaltySplitter();
        royaltySplitter.initiate(participants, cuts, participantsNames, name);
        emit RoyaltySplitterCreated(address (royaltySplitter));
    }

}
