//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TTCAirdropper is Ownable {

  error ArrayMismatch();

  address public constant ttcContractAddress = 0xECCAE88FF31e9f823f25bEb404cbF2110e81F1FA;

  function airdrop(address[] calldata _addresses, uint256[] calldata _tokenIds) external onlyOwner {
    if (_addresses.length != _tokenIds.length) revert ArrayMismatch();

    ERC721A ttcContract = ERC721A(ttcContractAddress);

    uint256 addressLength = _addresses.length;
    for (uint256 i; i < addressLength;) {
      ttcContract.safeTransferFrom(ttcContractAddress, _addresses[i], _tokenIds[i]);

      unchecked { ++i; }
    }
  }

}
