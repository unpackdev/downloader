// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "./Factory721.sol";
import "./Vault1155.sol";

contract Factory1155 is Factory721 {
  using Detector for address;

  constructor(address market) Factory721(market) {}

  function deployVault(
    string memory _name,
    string memory _symbol,
    address _collection,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _collectionOwnerFeeRatio,
    uint256[] memory _minPrices, // wei
    address[] memory _paymentTokens,
    uint256[] calldata _allowedTokenIds
  ) external override {
    require(_collection.is1155(), 'OnlyERC1155');

    address _vault = address(
      new Vault1155(
        _name,
        _symbol,
        _collection,
        msg.sender,
        _market,
        _minDuration * 1 days, // day -> sec
        _maxDuration * 1 days, // day -> sec
        _collectionOwnerFeeRatio, // bps: 1000 => 1%
        _minPrices, // wei
        _paymentTokens,
        _allowedTokenIds
      )
    );

    emit VaultDeployed(_vault, _collection);
  }
}
