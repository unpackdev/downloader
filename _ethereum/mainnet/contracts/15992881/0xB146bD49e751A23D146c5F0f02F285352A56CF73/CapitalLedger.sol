// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";

import "./Context.sol";
import "./Base.sol";
import "../../../cake/Routing.sol" as Routing;

import "./Arrays.sol";
import "./CapitalAssets.sol";
import "./UserEpochTotals.sol";

import "./ICapitalLedger.sol";

using Routing.Context for Context;
using UserEpochTotals for UserEpochTotal;
using Arrays for uint256[];

/**
 * @title CapitalLedger
 * @notice Track Capital held by owners and ensure the Capital has been accounted for.
 * @author Goldfinch
 */
contract CapitalLedger is ICapitalLedger, Base, IERC721ReceiverUpgradeable {
  /// Thrown when attempting to deposit nothing
  error ZeroDeposit();
  /// Thrown when withdrawing an invalid amount for a position
  error InvalidWithdrawAmount(uint256 requested, uint256 max);
  /// Thrown when depositing from address(0)
  error InvalidOwnerIndex();
  /// Thrown when querying token supply with an index greater than the supply
  error IndexGreaterThanTokenSupply();

  struct Position {
    // Owner of the position
    address owner;
    // Index of the position in the ownership array
    uint256 ownedIndex;
    // Address of the underlying asset represented by the position
    address assetAddress;
    // USDC equivalent value of the position. This is first written
    // on position deposit but may be updated.
    uint256 usdcEquivalent;
    // When the position was deposited
    uint256 depositTimestamp;
  }

  struct ERC721Data {
    // Id of the ERC721 assetAddress' token
    uint256 assetTokenId;
  }

  /// Data for positions in the vault. Always has a corresponding
  /// entry at the same index in ERC20Data or ERC721 data, but never
  /// both.
  mapping(uint256 => Position) public positions;

  // Which positions an address owns
  mapping(address => uint256[]) private owners;

  /// Total held by each user, while being aware of the deposit epoch
  mapping(address => UserEpochTotal) private totals;

  // The current position index
  uint256 private positionCounter;

  /// ERC721 data corresponding to positions, data has the same index
  /// as its corresponding position.
  mapping(uint256 => ERC721Data) private erc721Datas;

  /// @notice Construct the contract
  constructor(Context _context) Base(_context) {}

  /// @inheritdoc ICapitalLedger
  function depositERC721(
    address owner,
    address assetAddress,
    uint256 assetTokenId
  ) external onlyOperator(Routing.Keys.MembershipOrchestrator) returns (uint256) {
    if (CapitalAssets.getSupportedType(context, assetAddress) != CapitalAssetType.ERC721) {
      revert CapitalAssets.InvalidAsset(assetAddress);
    }
    if (!CapitalAssets.isValid(context, assetAddress, assetTokenId)) {
      revert CapitalAssets.InvalidAssetWithId(assetAddress, assetTokenId);
    }

    IERC721Upgradeable asset = IERC721Upgradeable(assetAddress);
    uint256 usdcEquivalent = CapitalAssets.getUsdcEquivalent(context, asset, assetTokenId);
    uint256 positionId = _mintPosition(owner, assetAddress, usdcEquivalent);

    erc721Datas[positionId] = ERC721Data({assetTokenId: assetTokenId});

    totals[owner].recordIncrease(usdcEquivalent);

    asset.safeTransferFrom(address(context.membershipOrchestrator()), address(this), assetTokenId);

    emit CapitalERC721Deposit({
      owner: owner,
      assetAddress: assetAddress,
      positionId: positionId,
      assetTokenId: assetTokenId,
      usdcEquivalent: usdcEquivalent
    });

    return positionId;
  }

  /// @inheritdoc ICapitalLedger
  function erc721IdOf(uint256 positionId) public view returns (uint256) {
    return erc721Datas[positionId].assetTokenId;
  }

  /// @inheritdoc ICapitalLedger
  function withdraw(uint256 positionId) external onlyOperator(Routing.Keys.MembershipOrchestrator) {
    Position memory position = positions[positionId];
    delete positions[positionId];

    CapitalAssetType assetType = CapitalAssets.getSupportedType(context, position.assetAddress);

    totals[position.owner].recordDecrease(position.usdcEquivalent, position.depositTimestamp);

    uint256[] storage ownersList = owners[position.owner];
    (, bool replaced) = ownersList.reorderingRemove(position.ownedIndex);
    if (replaced) {
      positions[ownersList[position.ownedIndex]].ownedIndex = position.ownedIndex;
    }

    if (assetType == CapitalAssetType.ERC721) {
      uint256 assetTokenId = erc721Datas[positionId].assetTokenId;
      delete erc721Datas[positionId];

      IERC721Upgradeable(position.assetAddress).safeTransferFrom(address(this), position.owner, assetTokenId);

      emit CapitalERC721Withdrawal(position.owner, positionId, position.assetAddress, position.depositTimestamp);
    } else {
      revert InvalidAssetType(assetType);
    }
  }

  /// @inheritdoc ICapitalLedger
  function assetAddressOf(uint256 positionId) public view returns (address) {
    return positions[positionId].assetAddress;
  }

  /// @inheritdoc ICapitalLedger
  function ownerOf(uint256 positionId) public view returns (address) {
    return positions[positionId].owner;
  }

  /// @inheritdoc ICapitalLedger
  function totalsOf(address addr) external view returns (uint256 eligibleAmount, uint256 totalAmount) {
    return totals[addr].getTotals();
  }

  /// @inheritdoc ICapitalLedger
  function totalSupply() public view returns (uint256) {
    return positionCounter;
  }

  /// @inheritdoc ICapitalLedger
  function balanceOf(address addr) external view returns (uint256) {
    return owners[addr].length;
  }

  /// @inheritdoc ICapitalLedger
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    if (index >= owners[owner].length) revert InvalidOwnerIndex();

    return owners[owner][index];
  }

  /// @inheritdoc ICapitalLedger
  function tokenByIndex(uint256 index) external view returns (uint256) {
    if (index >= totalSupply()) revert IndexGreaterThanTokenSupply();

    return index + 1;
  }

  /// @inheritdoc IERC721ReceiverUpgradeable
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  //////////////////////////////////////////////////////////////////
  // Private

  function _mintPosition(
    address owner,
    address assetAddress,
    uint256 usdcEquivalent
  ) private returns (uint256 positionId) {
    positionCounter++;

    positionId = positionCounter;
    positions[positionId] = Position({
      owner: owner,
      ownedIndex: owners[owner].length,
      assetAddress: assetAddress,
      usdcEquivalent: usdcEquivalent,
      depositTimestamp: block.timestamp
    });

    owners[owner].push(positionId);
  }
}
