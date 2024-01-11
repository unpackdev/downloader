// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./Structs.sol";

interface MetadataHandlerLike {
  function getCelestialTokenURI(uint256 id, CelestialV2 memory character) external view returns (string memory);

  function getFreakTokenURI(uint256 id, Freak memory character) external view returns (string memory);
}

interface InventoryCelestialsLike {
  function getAttributes(CelestialV2 memory character, uint256 id) external pure returns (bytes memory);

  function getImage(uint256 id, CelestialV2 memory character) external view returns (bytes memory);
}

interface InventoryFreaksLike {
  function getAttributes(Freak memory character, uint256 id) external view returns (bytes memory);

  function getImage(Freak memory character) external view returns (bytes memory);
}

interface IFnG {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function ownerOf(uint256 id) external returns (address owner);

  function isFreak(uint256 tokenId) external view returns (bool);

  function getSpecies(uint256 tokenId) external view returns (uint8);

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory);

  function setFreakAttributes(uint256 tokenId, Freak memory attributes) external;

  function getCelestialAttributes(uint256 tokenId) external view returns (Celestial memory);

  function setCelestialAttributes(uint256 tokenId, Celestial memory attributes) external;

  function burn(uint256 tokenId) external;

  function transferOwnership(address newOwner) external;
}

interface IFnGMig {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function ownerOf(uint256 id) external returns (address owner);

  function isFreak(uint256 tokenId) external view returns (bool);

  function getSpecies(uint256 tokenId) external view returns (uint8);

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory);

  function updateFreakAttributes(uint256 tokenId, Freak calldata attributes) external;

  function setFreakAttributes(uint256 tokenId, Freak memory attributes) external;

  function getCelestialAttributes(uint256 tokenId) external view returns (CelestialV2 memory celestial);

  function updateCelestialAttributes(uint256 tokenId, CelestialV2 calldata attributes) external;

  function setCelestialAttributes(uint256 tokenId, CelestialV2 memory attributes) external;

  function burn(uint256 tokenId) external;

  function transferOwnership(address newOwner) external;

  function mintFreak(address to, uint256 tokenId, Freak calldata attributes) external;

  function mintCelestial(address to, uint256 tokenId, CelestialV2 calldata attributes) external;

}

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

interface ICKEY {
  function ownerOf(uint256 tokenId) external returns (address);
}

interface IVAULT {
  function depositsOf(address account) external view returns (uint256[] memory);

  function _depositedBlocks(address account, uint256 tokenId) external returns (uint256);
}

interface ERC20Like {
  function balanceOf(address from) external view returns (uint256 balance);

  function burn(address from, uint256 amount) external;

  function mint(address from, uint256 amount) external;

  function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
  function mint(
    address to,
    uint256 id,
    uint256 amount
  ) external;

  function burn(
    address from,
    uint256 id,
    uint256 amount
  ) external;
}

interface ERC721Like {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function transfer(address to, uint256 id) external;

  function ownerOf(uint256 id) external returns (address owner);

  function mint(address to, uint256 tokenid) external;
}

interface PortalLike {
  function sendMessage(bytes calldata) external;
}

interface IHUNTING {
  function huntFromMigration(
    address owner,
    uint256[] calldata tokenIds,
    uint256 pool
  ) external;

  function observeFromMigration(address owner, uint256[] calldata tokenIds) external;
}

interface IChainlinkVRF {
  function isClaimed() external view returns (bool);

  function randomResult() external returns (uint256);

  function getRandomNumber() external returns (bytes32);
}

interface ICastle{
  function travelFromHunting(
		uint256[] calldata freakIds,
		uint256[] calldata celestialIds,
		uint256 fbxAmount,
		address owner
	) external;
}
