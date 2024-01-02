pragma solidity ^0.8.20;

import "./DataTypes.sol";

interface IERC1155ConfigurationProvider {
    function getERC1155ReserveConfig(uint256 tokenId)
        external
        view
        returns (DataTypes.ERC1155ReserveConfiguration memory);
}
