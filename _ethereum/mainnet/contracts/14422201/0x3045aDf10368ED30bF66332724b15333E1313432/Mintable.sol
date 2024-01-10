// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IMintable.sol";
import "./Minting.sol";

abstract contract Mintable is Ownable, IMintable {
  address public imx;
  uint256 public tokencounter = 1;
  mapping(uint256 => bytes) public blueprints;
  mapping(uint8 => uint256) private drops;
  bool public isPreSale = true;
  uint8 public round = 0;
  uint256 MAX_PRESALE = 500;

  // whitelist
  mapping(address => bool) public whitelistedAddresses;
  mapping(address => uint256) public hasClaimedNFT;
  bool public isFirstPhase = true;
  bool public isSecondPhase = false;
  event AssetMinted(address to, uint256 id, bytes blueprint);

  constructor(address _owner, address _imx) {
    imx = _imx;
    drops[0] = 2000;
    drops[1] = 2000;
    drops[2] = 3000;
    drops[3] = 1500;
    drops[4] = 1000;
    drops[5] = 500;
    require(_owner != address(0), "Owner must not be empty");
    transferOwnership(_owner);
  }

  modifier onlyIMX() {
    require(msg.sender == imx, "Function can only be called by IMX");
    _;
  }

  function setrounds(uint8 _round) public onlyOwner {
    round = _round;
    tokencounter = 1;
  }

  function setNewDrop(uint8 _round, uint8 _drop) public onlyOwner {
    drops[_round] = _drop;
  }

  function deactivePhaseOne() public onlyOwner {
    isFirstPhase = false;
    isSecondPhase = true;
  }

  function deactivePreSale() public onlyOwner {
    isPreSale = false;
    isSecondPhase = false;
  }

  function addAddressToWhitelist(address[] calldata _beneficiaries)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelistedAddresses[_beneficiaries[i]] = true;
    }
  }

  function mintFor(
    address user,
    uint256 quantity,
    bytes calldata mintingBlob
  ) external override onlyIMX {
    if (isPreSale) {
      require(
        whitelistedAddresses[user],
        "Only whitelisted addresses can mint NFTs in presale"
      );
      if (isFirstPhase) {
        require(
          hasClaimedNFT[user] < 3,
          "You have already minted NFT for presale"
        );
        // We have fixed 500 For presale
        require(MAX_PRESALE >= tokencounter, "Minting is over");
      }
    }
    require(quantity == 1, "Mintable: invalid quantity");
    require(drops[round] >= tokencounter, "Minting is over");

    (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
    _mintFor(user, id, blueprint);
    blueprints[id] = blueprint;
    tokencounter++;
    hasClaimedNFT[user] = hasClaimedNFT[user] + 1;
    emit AssetMinted(user, id, blueprint);
  }

  function _mintFor(
    address to,
    uint256 id,
    bytes memory blueprint
  ) internal virtual;
}
