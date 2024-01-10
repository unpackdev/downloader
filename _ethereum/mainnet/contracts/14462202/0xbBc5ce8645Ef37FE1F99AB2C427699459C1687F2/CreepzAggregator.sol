// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./ECDSA.sol";
import "./Strings.sol";

import "./CreepzAggregatorPool.sol";
import "./CreepzInterfaces.sol";

//   /$$$$$$            /$$                 /$$
//  /$$__  $$          | $$                | $$
// | $$  \__/  /$$$$$$ | $$$$$$$   /$$$$$$ | $$  /$$$$$$
// | $$       |____  $$| $$__  $$ |____  $$| $$ |____  $$
// | $$        /$$$$$$$| $$  \ $$  /$$$$$$$| $$  /$$$$$$$
// | $$    $$ /$$__  $$| $$  | $$ /$$__  $$| $$ /$$__  $$
// |  $$$$$$/|  $$$$$$$| $$$$$$$/|  $$$$$$$| $$|  $$$$$$$
//  \______/  \_______/|_______/  \_______/|__/ \_______/
//   /$$$$$$
//  /$$__  $$
// | $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$$
// | $$       /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$|____ /$$/
// | $$      | $$  \__/| $$$$$$$$| $$$$$$$$| $$  \ $$   /$$$$/
// | $$    $$| $$      | $$_____/| $$_____/| $$  | $$  /$$__/
// |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$| $$$$$$$/ /$$$$$$$$
//  \______/ |__/       \_______/ \_______/| $$____/ |________/
//                                         | $$
//   /$$$$$$                               | $$                             /$$
//  /$$__  $$                              |__/                            | $$
// | $$  \ $$  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$    /$$$$$$   /$$$$$$
// | $$$$$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$ |____  $$|_  $$_/   /$$__  $$ /$$__  $$
// | $$__  $$| $$  \ $$| $$  \ $$| $$  \__/| $$$$$$$$| $$  \ $$  /$$$$$$$  | $$    | $$  \ $$| $$  \__/
// | $$  | $$| $$  | $$| $$  | $$| $$      | $$_____/| $$  | $$ /$$__  $$  | $$ /$$| $$  | $$| $$
// | $$  | $$|  $$$$$$$|  $$$$$$$| $$      |  $$$$$$$|  $$$$$$$|  $$$$$$$  |  $$$$/|  $$$$$$/| $$
// |__/  |__/ \____  $$ \____  $$|__/       \_______/ \____  $$ \_______/   \___/   \______/ |__/
//            /$$  \ $$ /$$  \ $$                     /$$  \ $$
//           |  $$$$$$/|  $$$$$$/                    |  $$$$$$/
//            \______/  \______/                      \______/

// catch us at https://cabalacreepz.co

contract CreepzAggregator is ERC1155, Ownable {
  using ECDSA for bytes32;
  using Clones for address;

  // Trump 0-4; Cuban 5-9; Paris 10-14; Elon 15-19;
  // Snoop 20-24; Gary 25-29; Bankz 30-34;

  ICreepz public immutable Creepz;
  IShapeshifter public immutable Shapeshifter;

  CreepzAggregatorPool[7] private pools;

  address public creepzProvider;
  uint256 public creepzStaked;

  mapping(address => uint256) public userToUsedNonce;
  address private signer;

  uint256 public commissionRate = 9500; // 1 - (n ÷ 1e4) commission cut for owner

  uint256 public constant CLAIM_INTERVAL = 43200; // tax is accumlated every 12 hours = 43200 seconds

  address public poolMaster;
  bool private initialized = false;

  constructor(address creepz, address shapeshifter) ERC1155("") {
    Creepz = ICreepz(creepz);
    Shapeshifter = IShapeshifter(shapeshifter);
  }

  function initialize(address _poolMaster, bytes32[7] calldata salts) external onlyOwner {
    require(!initialized);
    poolMaster = _poolMaster;

    // spawn the 7 pools
    for (uint256 i = 0; i < 7; i++) {
      poolMaster.cloneDeterministic(salts[i]);
      pools[i] = CreepzAggregatorPool(poolMaster.predictDeterministicAddress(salts[i]));
      pools[i].initialize();
    }

    initialized = true;
  }

  // transfer ERC1155 token
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public override {
    pools[id / 5].updateTWAPForTransfer(from, to, amount);
    super.safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public override {
    uint256[7] memory poolChanges;
    for (uint256 i; i < ids.length; i++) {
      poolChanges[ids[i] / 5] += amounts[i];
    }
    for (uint256 i; i < 7; i++) {
      if (poolChanges[i] > 0) {
        pools[i].updateTWAPForTransfer(from, to, poolChanges[i]);
      }
    }
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  // ---- creepz -----
  function stakeCreepz(uint256 creepzId) external {
    require(creepzProvider == address(0) && creepzStaked == 0);
    Creepz.transferFrom(_msgSender(), address(pools[0]), creepzId); // put in the donald pool
    creepzProvider = _msgSender();
    creepzStaked = creepzId;
  }

  function unstakeCreepz() external {
    require(creepzProvider == _msgSender() && creepzStaked != 0);
    Creepz.transferFrom(address(pools[0]), _msgSender(), creepzStaked);
    creepzProvider = address(0);
    creepzStaked = 0;
  }

  // ---- shapeshifter -----
  function _verifyShapeshiferSignature(
    uint256[] calldata shapeIds,
    uint256[6][7] calldata shapeTypes,
    uint256[7] calldata taxAmounts,
    uint256 nonce,
    bytes calldata signature
  ) internal view {
    require(nonce > userToUsedNonce[_msgSender()]);
    address recoveredAddress = keccak256(abi.encodePacked(shapeIds, shapeTypes, taxAmounts, nonce, _msgSender())).toEthSignedMessageHash().recover(signature);
    require(recoveredAddress != address(0) && recoveredAddress == signer);
  }

  function stakeShapeshifters(
    uint256[] calldata shapeIds,
    uint256[6][7] calldata shapeTypes, // an 2d array holding 7 * 6 uint256s, balances & total
    uint256[7] calldata taxAmounts,
    uint256[7] calldata creepzNonces,
    bytes[7] calldata creepzSignatures,
    uint256 nonce,
    bytes calldata signature
  ) external {
    // verify the signature & nonce
    _verifyShapeshiferSignature(shapeIds, shapeTypes, taxAmounts, nonce, signature);
    userToUsedNonce[_msgSender()] = nonce;

    // keep track of where the creepz is
    address creepzOrigin = address(pools[0]);

    for (uint256 i = 0; i < 7; i++) {
      // identify the interacting pools
      if (shapeTypes[i][5] != 0) {
        // claim the loomi from creepz if necessary, i.e. after the interval and the tax amount is not zero
        if (pools[i].lastClaimedTimestamp() + CLAIM_INTERVAL < block.timestamp && taxAmounts[i] != 0) {
          // flash stake to the pool
          if (creepzOrigin != address(pools[i])) {
            Creepz.transferFrom(creepzOrigin, address(pools[i]), creepzStaked);
            creepzOrigin = address(pools[i]);
          }
          // claim the tax
          pools[i].claimTaxFromCreepz(creepzStaked, taxAmounts[i], commissionRate, creepzNonces[i], creepzSignatures[i]);
        }
        // update the pool
        pools[i].stakeShapeshifters(_msgSender(), shapeTypes[i]);
        // mint the corresponding tokens
        for (uint256 j = 0; j < 5; j++) {
          if (shapeTypes[i][j] != 0) {
            super._mint(_msgSender(), i * 5 + j, shapeTypes[i][j], "");
          }
        }
      }
    }

    // flash stake back to the first pool if the origin is not the first pool
    if (creepzOrigin != address(pools[0])) {
      Creepz.transferFrom(creepzOrigin, address(pools[0]), creepzStaked);
    }

    // transfer the shapeshifters to this contract
    for (uint256 i = 0; i < shapeIds.length; i++) {
      Shapeshifter.transferFrom(_msgSender(), address(this), shapeIds[i]);
    }
  }

  function unstakeShapeshifters(
    uint256[] calldata shapeIds,
    uint256[6][7] calldata shapeTypes, // an 2d array holding 7 * 6 uint256s, balances & total
    uint256[7] calldata taxAmounts,
    uint256[7] calldata creepzNonces,
    bytes[7] calldata creepzSignatures,
    uint256 nonce,
    bytes calldata signature
  ) external {
    // verify the signature & nonce
    _verifyShapeshiferSignature(shapeIds, shapeTypes, taxAmounts, nonce, signature);
    userToUsedNonce[_msgSender()] = nonce;

    // keep track of where the creepz is
    address creepzOrigin = address(pools[0]);

    for (uint256 i = 0; i < 7; i++) {
      // identify the interacting pools
      if (shapeTypes[i][5] != 0) {
        // claim the loomi from creepz if necessary
        if (pools[i].lastClaimedTimestamp() + CLAIM_INTERVAL < block.timestamp && taxAmounts[i] != 0) {
          // flash stake to the pool
          if (creepzOrigin != address(pools[i])) {
            Creepz.transferFrom(creepzOrigin, address(pools[i]), creepzStaked);
            creepzOrigin = address(pools[i]);
          }
          // claim the tax
          pools[i].claimTaxFromCreepz(creepzStaked, taxAmounts[i], commissionRate, creepzNonces[i], creepzSignatures[i]);
        }
        // update the pool
        pools[i].unstakeShapeshifters(_msgSender(), shapeTypes[i]);
        // burn the corresponding tokens
        for (uint256 j = 0; j < 5; j++) {
          if (shapeTypes[i][j] != 0) {
            super._burn(_msgSender(), i * 5 + j, shapeTypes[i][j]);
          }
        }
      }
    }

    // flash stake back to the first pool if the origin is not the first pool
    if (creepzOrigin != address(pools[0])) {
      Creepz.transferFrom(creepzOrigin, address(pools[0]), creepzStaked);
    }

    // transfer the shapeshifters to the sender
    for (uint256 i = 0; i < shapeIds.length; i++) {
      Shapeshifter.transferFrom(address(this), _msgSender(), shapeIds[i]);
    }
  }

  // ---- mega shapeshifter -----
  function unstakeMegaShapeshifter(
    uint256 poolIndex,
    uint256[5] calldata burnTypes, // tokens to burn
    uint256 megaId,
    uint256 taxAmount,
    uint256 creepzNonce,
    bytes calldata creepzSignature,
    uint256 nonce,
    bytes calldata signature
  ) external {
    // verify the signature & nonce
    require(nonce > userToUsedNonce[_msgSender()]);
    address recoveredAddress = keccak256(abi.encodePacked(poolIndex, megaId, nonce, _msgSender())).toEthSignedMessageHash().recover(signature);
    require(recoveredAddress != address(0) && recoveredAddress == signer);
    userToUsedNonce[_msgSender()] = nonce;

    // claim the loomi from creepz if necessary
    if (pools[poolIndex].lastClaimedTimestamp() + CLAIM_INTERVAL < block.timestamp && taxAmount != 0) {
      // flash stake to the pool if the pool is not donald
      if (poolIndex != 0) {
        Creepz.transferFrom(address(pools[0]), address(pools[poolIndex]), creepzStaked);
      }
      // claim the tax
      pools[poolIndex].claimTaxFromCreepz(creepzStaked, taxAmount, commissionRate, creepzNonce, creepzSignature);
      // flash stake back to the aggregator if the pool is not donald
      if (poolIndex != 0) {
        Creepz.transferFrom(address(pools[poolIndex]), address(pools[0]), creepzStaked);
      }
    }

    // burn the tokens
    uint256 burnedAmount;
    for (uint256 i = 0; i < 5; i++) {
      if (burnTypes[i] != 0) {
        super._burn(_msgSender(), poolIndex * 5 + i, burnTypes[i]);
        burnedAmount++;
      }
    }
    // must have burnt 5 tokens at the end
    require(burnedAmount == 5);

    // unstake the mega shapeshifter from the designated pool
    pools[poolIndex].unstakeMegashapeshifter(_msgSender(), megaId);
  }

  function mutateMegashifter(
    uint256[] calldata shapeIds,
    uint256 shapeType,
    bytes calldata mutateSignature
  ) external {
    // transfer the shapeshifters to the pool
    for (uint256 i = 0; i < 5; i++) {
      Shapeshifter.transferFrom(address(this), address(pools[shapeType]), shapeIds[i]);
    }

    // mutate the mega shapeshifter in the designated pool
    pools[shapeType].mutateMegaShapeshifter(shapeIds, shapeType, mutateSignature);
  }

  // ---- claim tax from pools -----
  function claimTaxFromPools(
    uint256[] calldata poolIndexes,
    uint256[] calldata taxAmounts,
    uint256[] calldata creepzNonces,
    bytes[] calldata creepzSignatures
  ) external {
    require(poolIndexes.length == taxAmounts.length && poolIndexes.length == creepzNonces.length);

    // keep track of where the creepz is
    address creepzOrigin = address(pools[0]);

    for (uint256 i = 0; i < poolIndexes.length; i++) {
      // claim loomi from creepz if necessary
      if (pools[poolIndexes[i]].lastClaimedTimestamp() + CLAIM_INTERVAL < block.timestamp && taxAmounts[i] != 0) {
        // flash stake to the pool
        if (creepzOrigin != address(pools[poolIndexes[i]])) {
          Creepz.transferFrom(creepzOrigin, address(pools[poolIndexes[i]]), creepzStaked);
          creepzOrigin = address(pools[poolIndexes[i]]);
        }

        // claim the tax
        pools[poolIndexes[i]].claimTaxFromCreepz(creepzStaked, taxAmounts[i], commissionRate, creepzNonces[i], creepzSignatures[i]);
      }

      // claim tax from pool
      pools[poolIndexes[i]].claimTaxFromPool(_msgSender());
    }

    // flash stake back to the first pool if the origin is not the first pool
    if (creepzOrigin != address(pools[0])) {
      Creepz.transferFrom(creepzOrigin, address(pools[0]), creepzStaked);
    }
  }

  // ---- view ----
  function getPoolAddress(uint256 poolIndex) external view returns (address) {
    return address(pools[poolIndex]);
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId), ".json"));
  }

  // ---- owner ----
  function withdrawPoolEarnOwner(address withdrawlAddress) external onlyOwner {
    for (uint256 i; i < 7; i++) {
      pools[i].withdrawPoolEarnOwner(withdrawlAddress);
    }
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function setURI(string calldata _uri) external onlyOwner {
    _setURI(_uri);
  }

  // toggle the commission taking
  function setTakingCommissions(bool takingCommissions) external onlyOwner {
    if (takingCommissions) {
      commissionRate = 9500; // 1 - (9500 ÷ 1e4) = 5% commission cut for owner
    } else {
      commissionRate = 1e4;
    }
  }
}
