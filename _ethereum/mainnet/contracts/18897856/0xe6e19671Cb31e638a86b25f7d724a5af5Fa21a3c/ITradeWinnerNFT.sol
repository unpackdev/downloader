// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IERC721AUpgradeable.sol";
import "./Structs.sol";

interface ITradeWinnerNFT is IERC721AUpgradeable {
    function mint(
        address to,
        MMNFTMetadata calldata _tokenMetadata
    ) external returns (uint256);

    function mintBatch(
        address to,
        MMNFTMetadata[] calldata _tokensMetadata
    ) external returns (uint256[] memory);
}
