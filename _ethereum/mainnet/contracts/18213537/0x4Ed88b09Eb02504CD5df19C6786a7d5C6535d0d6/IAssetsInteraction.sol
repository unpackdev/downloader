// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

interface IAssetsInteraction {
    function resurrectApe(uint256 tokenId, address recipient) external;
}

