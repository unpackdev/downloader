// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./IERC721Enumerable.sol";

interface IShogunNFT is IERC721Enumerable {
    function lockToken(uint256[] memory _tokenIds) external;

    function unlockToken(uint256[] memory _tokenIds) external;

    function seppuku(uint256 _tokenId) external;
}
