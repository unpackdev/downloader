// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./MarketPlaceCore.sol";
import "./ILegitArtERC721.sol";

contract MarketPlaceCoreMock is MarketPlaceCore {
    constructor(
        IERC20 _usdc,
        ILegitArtERC721 _legitArtNFT,
        address _feeBeneficiary,
        uint256 _primaryFeePercentage,
        uint256 _secondaryFeePercentage
    ) MarketPlaceCore(_usdc, _legitArtNFT, _feeBeneficiary, _primaryFeePercentage, _secondaryFeePercentage) {}
}
