// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./TinyExplorersTypes.sol";

interface ITinyExplorersRenderer {
    function tokenURI(uint256 tokenId, TinyExplorersTypes.TinyExplorer memory explorerData) external view returns (string memory);
    function tokenAttributes(TinyExplorersTypes.TinyExplorer memory explorerData) external view returns (string memory);
}
