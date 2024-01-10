// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./Initializable.sol";
import "./Context.sol";
import "./IERC721Receiver.sol";
import "./CreepzInterfaces.sol";

contract CreepzAggregatorPool is Context, Initializable, IERC721Receiver {
  struct Stakeholder {
    uint256 totalStaked;
    uint256 unclaimed;
    uint256 TWAP;
  }

  uint256 public totalStaked;
  uint256 public totalTaxReceived;
  uint256 public totalClaimable;
  uint256 public lastClaimedTimestamp;

  uint256 public TWAP;

  mapping(address => Stakeholder) public stakes;

  address public immutable allowedOrigin;

  ILoomi public immutable Loomi;
  ICreepz public immutable Creepz;
  IMegaShapeshifter public immutable MegaShapeshifter;

  modifier onlyFromAllowedOrigin() {
    require(_msgSender() == allowedOrigin);
    _;
  }

  constructor(
    address origin,
    address loomiAddress,
    address creepzAddress,
    address megaShapeshifterAddress
  ) {
    // set the allowed origin to the aggregator address
    allowedOrigin = origin;

    Loomi = ILoomi(loomiAddress);
    Creepz = ICreepz(creepzAddress);
    MegaShapeshifter = IMegaShapeshifter(megaShapeshifterAddress);
  }

  function initialize() external initializer {
    // allow the aggregator to flash stake creepz & unstake mega
    Creepz.setApprovalForAll(allowedOrigin, true);
    MegaShapeshifter.setApprovalForAll(allowedOrigin, true);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function updateTWAPForTransfer(
    address from,
    address to,
    uint256 changes
  ) external onlyFromAllowedOrigin {
    // update the from's stats
    stakes[from].unclaimed += (TWAP - stakes[from].TWAP) * stakes[from].totalStaked;
    stakes[from].totalStaked -= changes;
    stakes[from].TWAP = TWAP;

    // update the to's stats
    stakes[to].unclaimed += (TWAP - stakes[to].TWAP) * stakes[to].totalStaked;
    stakes[to].totalStaked += changes;
    stakes[to].TWAP = TWAP;
  }

  function claimTaxFromCreepz(
    uint256 creepzId,
    uint256 reward,
    uint256 commissionRate,
    uint256 creepzNonce,
    bytes calldata creepzSignature
  ) external onlyFromAllowedOrigin {
    // need at least one shapeshifter staked to distribute tax
    require(totalStaked > 0);

    // claim the tax from creepz
    MegaShapeshifter.claimTax(reward, creepzNonce, creepzId, creepzSignature);

    // deduct the commission from the total tax received
    reward = (reward * commissionRate) / 1e4;

    // update the pool's stats
    TWAP += reward / totalStaked;
    totalTaxReceived += reward;
    totalClaimable += reward;

    // update the last claimed timestamp
    lastClaimedTimestamp = block.timestamp;
  }

  function claimTaxFromPool(address stakeholder) external onlyFromAllowedOrigin {
    // calculate the total reward amount
    uint256 totalReward = stakes[stakeholder].unclaimed + (TWAP - stakes[stakeholder].TWAP) * stakes[stakeholder].totalStaked;

    // update the pool's stats
    totalClaimable -= totalReward;

    // update the stakeholder's stats
    stakes[stakeholder].unclaimed = 0;
    stakes[stakeholder].TWAP = TWAP;

    // transfer the total reward to the stakeholder
    Loomi.transferLoomi(stakeholder, totalReward);
  }

  function stakeShapeshifters(address stakeholder, uint256[6] calldata shapeTypes) external onlyFromAllowedOrigin {
    // update the pool's stats
    totalStaked += shapeTypes[5];

    // update the stakeholder's stats
    stakes[stakeholder].unclaimed += (TWAP - stakes[stakeholder].TWAP) * stakes[stakeholder].totalStaked;
    stakes[stakeholder].totalStaked += shapeTypes[5];
    stakes[stakeholder].TWAP = TWAP;
  }

  function unstakeShapeshifters(address stakeholder, uint256[6] calldata shapeTypes) external onlyFromAllowedOrigin {
    // update the pool's stats
    totalStaked -= shapeTypes[5];

    // update the stakeholder's stats
    stakes[stakeholder].unclaimed += (TWAP - stakes[stakeholder].TWAP) * stakes[stakeholder].totalStaked;
    stakes[stakeholder].totalStaked -= shapeTypes[5];
    stakes[stakeholder].TWAP = TWAP;
  }

  function unstakeMegashapeshifter(address stakeholder, uint256 megaId) external onlyFromAllowedOrigin {
    // calculate the inefficiency score
    require(stakes[stakeholder].totalStaked * MegaShapeshifter.balanceOf(address(this)) >= totalStaked);

    // update the pool's stats
    totalStaked -= 5;

    // update the stakeholder's stats
    stakes[stakeholder].unclaimed += (TWAP - stakes[stakeholder].TWAP) * stakes[stakeholder].totalStaked;
    stakes[stakeholder].totalStaked -= 5;
    stakes[stakeholder].TWAP = TWAP;

    // transfer the mega shapeshifter
    MegaShapeshifter.transferFrom(address(this), stakeholder, megaId);
  }

  function mutateMegaShapeshifter(
    uint256[] calldata shapeIds,
    uint256 shapeType,
    bytes calldata signature
  ) external {
    // mutate by calling the MegaShapeshifter contract
    MegaShapeshifter.mutate(shapeIds, shapeType, signature);
  }

  function withdrawPoolEarnOwner(address withdrawAddress) external onlyFromAllowedOrigin {
    // get the loomi balance of the contract
    uint256 loomiBalance = Loomi.getUserBalance(address(this));

    // transfer the commission received to the withdraw address
    Loomi.transferLoomi(withdrawAddress, loomiBalance - totalClaimable);
  }
}
