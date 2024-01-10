//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./PaymentSplitter.sol";
import "./IChocoMintERC721.sol";

contract ChocoMintSellableWrapper is PaymentSplitter {
  IChocoMintERC721 public chocomintERC721;
  uint256 public supplied;
  uint256 public mintPrice;
  uint256 public supplyLimit;
  uint256 public saleStartTimestamp;

  constructor(
    address _chocomintERC721Address,
    uint256 _mintPrice,
    uint256 _supplyLimit,
    uint256 _saleStartTimestamp,
    address[] memory _payees,
    uint256[] memory _shares
  ) PaymentSplitter(_payees, _shares) {
    chocomintERC721 = IChocoMintERC721(_chocomintERC721Address);
    mintPrice = _mintPrice;
    supplyLimit = _supplyLimit;
    saleStartTimestamp = _saleStartTimestamp;
  }

  function sell() public payable {
    require(block.timestamp >= saleStartTimestamp, "SellableWrapper: sale has not started");
    require(msg.value == mintPrice, "SellableWrapper: msg value must be same as mint price");
    require(supplied < supplyLimit, "SellableWrapper: sale has already ended");
    SecurityLib.SecurityData memory validSecurityData = SecurityLib.SecurityData(0, 9999999999, 0);
    MintERC721Lib.MintERC721Data memory mintERC721Data = MintERC721Lib.MintERC721Data(
      validSecurityData,
      address(this),
      msg.sender,
      supplied + 1,
      ""
    );
    bytes32 root = MintERC721Lib.hashStruct(mintERC721Data);
    SignatureLib.SignatureData memory signatureData = SignatureLib.SignatureData(root, new bytes32[](0), "");
    chocomintERC721.mint(mintERC721Data, signatureData);
    supplied++;
  }
}
