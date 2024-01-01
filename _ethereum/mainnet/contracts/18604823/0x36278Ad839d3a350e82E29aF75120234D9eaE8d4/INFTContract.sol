//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./IERC721.sol";

interface INFTContract is IERC721 {
    function nftHashrate(uint256 _tokenId) external view returns (uint16);
}
