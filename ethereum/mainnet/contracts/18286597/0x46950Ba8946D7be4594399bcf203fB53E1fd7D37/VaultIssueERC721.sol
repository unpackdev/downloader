// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./Permissions.sol";
import "./Pausable.sol";

import "./IERC721Deterministic.sol";

abstract contract VaultIssueERC721 is Permissions, Pausable {
  uint8 public immutable PERMISSION_ISSUE_ERC721;

  error ArrayLengthMismatchIssueERC721(uint256 _array1, uint256 _array2, uint256 _array3);

  constructor (uint8 _issueERC721Permission) {
    PERMISSION_ISSUE_ERC721 = _issueERC721Permission;

    _registerPermission(PERMISSION_ISSUE_ERC721);
  }

  function issueERC721(
    address _beneficiary,
    IERC721Deterministic _contract,
    uint256 _optionId,
    uint256 _issuedId
  ) external notPaused onlyPermissioned(PERMISSION_ISSUE_ERC721) {
    _contract.issueToken(_beneficiary, _optionId, _issuedId);
  }

  function issueBatchERC721(
    address _beneficiary,
    IERC721Deterministic[] calldata _contracts,
    uint256[] calldata _optionIds,
    uint256[] calldata _issuedIds
  ) external notPaused onlyPermissioned(PERMISSION_ISSUE_ERC721) {
    unchecked {
      uint256 contractsLength = _contracts.length;

      if (contractsLength != _optionIds.length || contractsLength != _issuedIds.length) {
        revert ArrayLengthMismatchIssueERC721(contractsLength, _optionIds.length, _issuedIds.length);
      }

      for (uint256 i = 0; i < contractsLength; ++i) {
        _contracts[i].issueToken(_beneficiary, _optionIds[i], _issuedIds[i]);
      }
    }
  }
}
