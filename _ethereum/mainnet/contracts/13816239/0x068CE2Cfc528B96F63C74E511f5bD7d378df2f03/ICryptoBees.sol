//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "./IERC721.sol";

interface ICryptoBees {
    struct Token {
        uint8 _type;
        uint8 color;
        uint8 eyes;
        uint8 mouth;
        uint8 nose;
        uint8 hair;
        uint8 accessory;
        uint8 feelers;
        uint8 strength;
        uint48 lastAttackTimestamp;
        uint48 cooldownTillTimestamp;
    }

    function getMinted() external view returns (uint256 m);

    function increaseTokensPot(address _owner, uint256 amount) external;

    function updateTokensLastAttack(
        uint256 tokenId,
        uint48 timestamp,
        uint48 till
    ) external;

    function mint(
        address addr,
        uint256 tokenId,
        bool stake
    ) external;

    function setPaused(bool _paused) external;

    function getTokenData(uint256 tokenId) external view returns (Token memory token);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function doesExist(uint256 tokenId) external view returns (bool exists);

    function performTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function performSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
