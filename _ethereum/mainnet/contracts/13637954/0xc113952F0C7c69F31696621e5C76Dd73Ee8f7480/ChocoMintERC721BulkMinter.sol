// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MintERC721Lib.sol";
import "./SignatureLib.sol";
import "./IChocoMintERC721.sol";

contract ChocoMintERC721BulkMinter {
  function mint(
    address chocoMintERC721,
    MintERC721Lib.MintERC721Data[] memory mintERC721Data,
    SignatureLib.SignatureData[] memory signatureData
  ) external {
    require(mintERC721Data.length == signatureData.length, "ChocoMintERC721BulkMinter: length verification failed");
    for (uint256 i = 0; i < mintERC721Data.length; i++) {
      IChocoMintERC721(chocoMintERC721).mint(mintERC721Data[i], signatureData[i]);
    }
  }
}
