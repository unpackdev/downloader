// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface ICoin {
    function mint(address account, uint amount) external;
    function burn(address _from, uint _amount) external;
    function balanceOf(address account) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IToken {
    function ownerOf(uint id) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external; // ERC721
    function safeTransferFrom(address from, address to, uint tokenId, uint amount) external; // ERC1155
    function isApprovedForAll(address owner, address operator) external returns(bool);
    function setApprovalForAll(address operator, bool approved) external;
}

interface IGHGMetadata {
    ///// GENERIC GETTERS /////
    function getGoldhunterMetadata(uint16 _tokenId) external view returns (string memory);
    function getShipMetadata(uint16 _tokenId) external view returns (string memory);
    function getHouseMetadata(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - SHIPS /////
    function shipIsPirate(uint16 _tokenId) external view returns (bool);
    function shipIsCrossedTheOcean(uint16 _tokenId) external view returns (bool);
    function getShipBackground(uint16 _tokenId) external view returns (string memory);
    function getShipShip(uint16 _tokenId) external view returns (string memory);
    function getShipFlag(uint16 _tokenId) external view returns (string memory);
    function getShipMast(uint16 _tokenId) external view returns (string memory);
    function getShipAnchor(uint16 _tokenId) external view returns (string memory);
    function getShipSail(uint16 _tokenId) external view returns (string memory);
    function getShipWaves(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - HOUSES /////
    function getHouseBackground(uint16 _tokenId) external view returns (string memory);
    function getHouseType(uint16 _tokenId) external view returns (string memory);
    function getHouseWindow(uint16 _tokenId) external view returns (string memory);
    function getHouseDoor(uint16 _tokenId) external view returns (string memory);
    function getHouseRoof(uint16 _tokenId) external view returns (string memory);
    function getHouseForeground(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - GOLDHUNTERS /////
    function goldhunterIsCrossedTheOcean(uint16 _tokenId) external view returns (bool);
    function goldhunterIsPirate(uint16 _tokenId) external view returns (bool);
    function getGoldhunterIsGen0(uint16 _tokenId) external pure returns (bool);
    function getGoldhunterSkin(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterLegs(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterFeet(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterTshirt(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHeadwear(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterMouth(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterNeck(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterSunglasses(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterTool(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterPegleg(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHook(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterDress(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterFace(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterPatch(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterEars(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHead(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterArm(uint16 _tokenId) external view returns (string memory);
}