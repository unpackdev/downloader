// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

interface INFTPoolInterface {

    function token2Nft(uint256 amount, uint256[] memory nfts) external returns (uint256[] memory);

    function nft2Token(uint256[] memory nfts) external returns (uint256 amount);

}
