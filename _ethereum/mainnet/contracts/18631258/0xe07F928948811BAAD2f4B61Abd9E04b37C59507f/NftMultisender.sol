// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC721.sol";

contract NftMultisender {
    function sendNftToOneAddress(
        address _tokenAddress,
        address _to,
        uint256[] memory _tokenId
    ) external {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            IERC721(_tokenAddress).safeTransferFrom(
                msg.sender,
                _to,
                _tokenId[i]
            );
        }
    }

    function sendNftToManyAddresses(
        address _tokenAddress,
        address[] memory _to,
        uint256 _tokenId
    ) external {
        for (uint256 i = 0; i < _to.length; i++) {
            IERC721(_tokenAddress).safeTransferFrom(
                msg.sender,
                _to[i],
                _tokenId
            );
        }
    }
}
