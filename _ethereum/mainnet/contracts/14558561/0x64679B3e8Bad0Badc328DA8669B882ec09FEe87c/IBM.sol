//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IValidator.sol";
import "./IKillswitch.sol";

interface IBM is IERC721, IERC721Metadata, IValidator, IKillswitch {
    event NewGodFather(address owner, uint256 tokenId, uint256 level, uint256 timestamp);

    function setBaseUri(string memory baseUri) external;
    function setSettings(address settingsAddress) external;
    function setHoney(address honeyAddress) external;
    function setPriceStrategy(address priceStrategyAddress) external;
    function setBonusProgram(address bonusProgramAddress) external;
    function setSalesStartAt(uint256 timestamp) external;

    function totalSupply() external view returns (uint256);
    function getPrice() external view returns (uint256);
    function getBearLevel(uint256 tokenId) external view returns (uint256);
    function getBearEfficiency(uint256 tokenId) external view returns (uint256);
    function getOwnerEfficiency(address owner) external view returns (uint256);
    function getHoneyAvailableForClaimAt(uint256 _ts) external view returns (uint256);
    function getHoneyAvailableForClaimAt(address owner, uint256 _ts) external view returns (uint256);
    function getLevelupPrice(uint256 currentRank) external view returns (uint256);
    function getSalesStartAt() external view returns (uint256);

    function mint(uint256 amount) external payable;
    function claimHoney() external;
    function levelUp(uint256 tokenId, uint256 honeyValue) external;

    function validatorMintOne(address mintFor) external;
    function validatorMint(address mintFor, uint256 tokenId) external;
    function validatorBurn(uint256 tokenId) external;

    function withdraw() external;
}
