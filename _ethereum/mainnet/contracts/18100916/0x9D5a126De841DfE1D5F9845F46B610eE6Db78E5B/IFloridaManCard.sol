// SPDX-License-Identifier: UNLICENSED

import "./IERC1155.sol";

pragma solidity ^0.8.19;

interface IFloridaManCard is IERC1155 {
    function mintMysteryPack(address _to, uint256 _seasonId, uint256 _quantity)
        external
        returns (uint256[] memory minted);

    function withdrawFMAN() external;

    function transfer(address _to, uint256 _id, uint256 _quantity) external;

    function isCardValid(uint256 _id) external view returns (bool);

    function isSeasonValid(uint256 _id) external view returns (bool);

    function getSeasonCards(uint256 _id) external view returns (uint256[] memory seasonCardIds);

    function getSeasonIds() external view returns (uint256[] memory allSeasonIds);

    function getCardIds() external view returns (uint256[] memory allCardIds);

    function getCard(uint256 _id)
        external
        view
        returns (uint256 id, uint256 price, uint256 totalSupply, uint256 maxOwnable, uint256 level);
}
