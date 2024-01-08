//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "./IERC721.sol";

interface IChainGuardiansToken is IERC721 {
    function getProperties(uint256 _tokenId) external view returns (uint256 attrs, uint256[] memory compIds);

    function updateAttributes(
        uint256 _tokenId,
        uint256 _attributes,
        uint256[] calldata _componentIds
    ) external;
}
