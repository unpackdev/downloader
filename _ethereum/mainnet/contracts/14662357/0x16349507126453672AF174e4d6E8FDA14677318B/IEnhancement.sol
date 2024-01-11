// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @title Enhancement Interface
 */
interface IEnhancement {
    
    event BeforeGodTier(uint256 indexed tokenId);

    event BeforeEnhanced(uint256 indexed tokenId);

    event BeforeFailed(uint256 indexed tokenId);
}
