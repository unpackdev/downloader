// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPDBasicDao {
    event BasicDaoUnlocked(bytes32 indexed daoId);

    function unlock(bytes32 daoId) external;

    function ableToUnlock(bytes32 daoId) external view returns (bool);

    function getTurnover(bytes32 daoId) external view returns (uint256);

    function isUnlocked(bytes32 daoId) external view returns (bool);

    function getCanvasIdOfSpecialNft(bytes32 daoId) external view returns (bytes32);

    function setSpecialTokenUriPrefix(string memory prefix) external;

    function getSpecialTokenUriPrefix() external view returns (string memory);

    function setBasicDaoNftFlatPrice(uint256 price) external;

    function getBasicDaoNftFlatPrice() external view returns (uint256);
}
