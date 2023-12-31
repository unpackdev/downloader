// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ERC165.sol";
import "./PolyOneCreator.sol";
import "./IPolyOneCore.sol";
import "./IPolyOneDrop.sol";
import "./PolyOneLibrary.sol";

/**
 * @title PolyOneDrop
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Partial abstract implementation of shared functionality for drop contracts
 */
abstract contract PolyOneDrop is IPolyOneDrop, ERC165 {
  IPolyOneCore public polyOneCore;

  mapping(uint256 dropId => Drop dropParameters) public drops;
  mapping(uint256 dropId => mapping(uint256 tokenIndex => bool isClaimed)) public claimed;

  constructor(address _polyOneCore) {
    PolyOneLibrary.checkZeroAddress(_polyOneCore, "poly one core");
    polyOneCore = IPolyOneCore(_polyOneCore);
  }

  function createDrop(uint256 _dropId, Drop calldata _drop, bytes calldata) external onlyPolyOneCore {
    PolyOneLibrary.checkZeroAddress(_drop.collection, "collection");
    if (_dropExists(_dropId)) {
      revert DropAlreadyExists(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(_drop.startDate)) {
      revert InvalidDate(_drop.startDate);
    }

    drops[_dropId] = _drop;
  }

  function updateDrop(uint256 _dropId, Drop calldata _drop, bytes calldata) external onlyPolyOneCore {
    if (!_dropExists(_dropId)) {
      revert DropNotFound(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(drops[_dropId].startDate)) {
      revert DropInProgress(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(_drop.startDate)) {
      revert InvalidDate(_drop.startDate);
    }

    drops[_dropId] = Drop(
      _drop.startingPrice,
      _drop.bidIncrement,
      _drop.qty,
      _drop.startDate,
      _drop.dropLength,
      drops[_dropId].collection,
      _drop.baseTokenURI,
      _drop.royalties
    );
  }

  function updateDropRoyalties(uint256 _dropId, Royalties calldata _royalties) external onlyPolyOneCore {
    if (!_dropExists(_dropId)) {
      revert DropNotFound(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(drops[_dropId].startDate)) {
      revert DropInProgress(_dropId);
    }

    drops[_dropId].royalties = _royalties;
  }

  /**
   * @dev Validate the purchase intent of a token in a drop
   * @param _dropId The drop id
   * @param _tokenIndex The index of the token in the drop
   * @return The drop in storage
   */
  function _validatePurchaseIntent(uint256 _dropId, uint256 _tokenIndex) internal view returns (Drop storage) {
    if (!_dropExists(_dropId)) {
      revert DropNotFound(_dropId);
    }
    Drop storage drop = drops[_dropId];
    if (_tokenIndex == 0 || _tokenIndex > drop.qty) {
      revert TokenNotFoundInDrop(_dropId, _tokenIndex);
    }
    if (claimed[_dropId][_tokenIndex]) {
      revert TokenAlreadyClaimed(_dropId, _tokenIndex);
    }
    if (!PolyOneLibrary.isDateInPast(drop.startDate)) {
      revert DropNotStarted(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(drop.startDate + drop.dropLength)) {
      revert DropFinished(_dropId);
    }
    return drop;
  }

  /**
   * @dev Check if a drop has been previously created on this contract
   */
  function _dropExists(uint256 _dropId) internal view returns (bool) {
    return drops[_dropId].collection != address(0);
  }

  /**
   * @dev Validate a claim on behalf of a claimant
   *      This should allow the creator or an admin of PolyOneCore to initiate the claim process
   * @param _dropId The id of the drop to validate
   * @param _caller The address of the caller
   * @return True if the claim is valid
   */
  function _validateDelegatedClaim(uint256 _dropId, address _caller) internal view returns (bool) {
    return
      (polyOneCore.hasRole(polyOneCore.POLY_ONE_ADMIN_ROLE(), _caller)) || _caller == IPolyOneCreator(drops[_dropId].collection).creator();
  }

  /**
   * @dev Functions with the onlyPolyOneCore modifier attached should only be callable by the PolyOne Core contract
   */
  modifier onlyPolyOneCore() {
    if (msg.sender != address(polyOneCore)) {
      revert PolyOneLibrary.InvalidCaller(msg.sender);
    }
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IPolyOneDrop).interfaceId || super.supportsInterface(interfaceId);
  }
}
