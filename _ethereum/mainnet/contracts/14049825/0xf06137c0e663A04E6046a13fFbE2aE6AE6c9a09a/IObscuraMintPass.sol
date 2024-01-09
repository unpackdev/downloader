// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface IObscuraMintPass is IERC721Enumerable {
    function mintTo(address to, uint256 projectId) external;

    function isSalePublic(uint256 passId) external view returns (bool active);

    function getPassPrice(uint256 passId) external view returns (uint256 price);

    function getPassMaxTokens(uint256 passId)
        external
        view
        returns (uint256 maxTokens);

    function getTokenIdToPass(uint256 tokenId)
        external
        view
        returns (uint256 passId);
}
