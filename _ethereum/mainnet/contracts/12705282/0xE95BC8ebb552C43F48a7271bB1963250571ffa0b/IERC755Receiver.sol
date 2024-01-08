// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Structs.sol";

interface IERC755Receiver {
    function onERC755Received(
        address operator,
        address from,
        uint256 tokenId,
        Structs.Policy[] memory rights,
        bytes calldata data
    ) external returns (bytes4);
}