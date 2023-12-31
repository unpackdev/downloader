// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IWallet.sol";

interface IWalletApeCoin is IWallet {
    function depositBAYCAndLock(uint32 tokenId, uint224 amount) external;

    function depositMAYCAndLock(uint32 tokenId, uint224 amount) external;

    function depositBAKCAndLock(
        address mainCollection,
        uint32 mainTokenId,
        uint32 bakcTokenId,
        uint224 amount
    ) external;

    function withdrawBAYCAndUnlock(uint32 tokenId) external;

    function withdrawMAYCAndUnlock(uint32 tokenId) external;

    function withdrawBAKCAndUnlock(uint32 tokenId) external;

    function autoCompound(uint256 poolId, uint32 tokenId) external;
}
