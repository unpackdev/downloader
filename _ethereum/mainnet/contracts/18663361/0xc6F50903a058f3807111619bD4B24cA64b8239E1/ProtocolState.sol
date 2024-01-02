// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Structs.sol";
import "./Ownable.sol";

///@title ProtocolState contract
///@notice Protocol data storage
abstract contract ProtocolState is Ownable {
  /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

  ///@notice Protocol data
  ProtocolData public protocolData;

  ///@notice Number of token in the protocol
  mapping(address => uint256) public totalAssetAccounting;

  ///@notice Number of token in the proxy
  mapping(address => uint256) public proxyAssetAccounting;

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  error ValueOutOfBounds();

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event ProtocolAumUpdated(uint256);
  event MaxAumDeviationAllowedUpdated(uint16);
  event TaxFactorUpdated(uint72);
  event ManagementFeeUpdated(uint72);

  /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/

  ///@notice Get number of token in the standard pool
  ///@param _asset asset address
  ///@return number of token in standard pool
  function standardAssetAccounting(address _asset) public view returns (uint256) {
    return totalAssetAccounting[_asset] - proxyAssetAccounting[_asset];
  }

  ///@notice Get protocolAUM in USD
  ///@return protocol AUM
  function getProtocolAUM() external view returns (uint256) {
    return protocolData.aum;
  }

  /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/

  ///@notice Change the AUM's comparison deviation threshold
  ///@param threshold new threshold
  ///@dev 200 = 2 % of deviation
  function updateMaxAumDeviationAllowed(uint16 threshold) public onlyOwner {
    // We bound the threshold to 0.1 % to 5%
    if (threshold < 10 || threshold > 500) revert ValueOutOfBounds();
    protocolData.maxAumDeviationAllowed = threshold;
    emit MaxAumDeviationAllowedUpdated(threshold);
  }

  ///@notice set the tax factor
  ///@param _taxFactor new tax factor
  ///@dev 100% = 100e18
  function updateTaxFactor(uint72 _taxFactor) public onlyOwner {
    if (_taxFactor > 100e18) revert ValueOutOfBounds();
    protocolData.taxFactor = _taxFactor;
    emit TaxFactorUpdated(_taxFactor);
  }

  ///@notice change annual management fee
  ///@param _annualFee new annual fee
  ///@dev 100% = 1e18
  function updateManagementFee(uint72 _annualFee) public onlyOwner {
    // We bound the fee to 0 % to 5%
    if (_annualFee > 5e16) revert ValueOutOfBounds();
    protocolData.managementFee = _annualFee;
    emit ManagementFeeUpdated(_annualFee);
  }

  ///@notice Update last fee collection time to current timestamp
  function _updateLastFeeCollectionTime() internal {
    protocolData.lastFeeCollectionTime = uint48(block.timestamp);
  }

  ///@notice Update the protocol AUM
  function _updateProtocolAUM(uint256 _aum) internal {
    protocolData.aum = _aum;
    emit ProtocolAumUpdated(_aum);
  }

  function _increaseAssetTotalAmount(address[] memory _assets, uint256[] memory _amounts) internal {
    for (uint256 i; i < _assets.length; i++) {
      _increaseAssetTotalAmount(_assets[i], _amounts[i]);
    }
  }

  function _increaseAssetTotalAmount(address _asset, uint256 _amount) internal {
    totalAssetAccounting[_asset] += _amount;
  }

  function _increaseAssetProxyAmount(address[] memory _assets, uint256[] memory _amounts) internal {
    for (uint256 i; i < _assets.length; i++) {
      proxyAssetAccounting[_assets[i]] += _amounts[i];
    }
  }

  function _decreaseAssetTotalAmount(address[] memory _assets, uint256[] memory _amounts) internal {
    for (uint256 i; i < _assets.length; i++) {
      _decreaseAssetTotalAmount(_assets[i], _amounts[i]);
    }
  }

  function _decreaseAssetTotalAmount(address _asset, uint256 _amount) internal {
    totalAssetAccounting[_asset] -= _amount;
  }

  function _decreaseAssetProxyAmount(address[] memory _assets, uint256[] memory _amounts) internal {
    for (uint256 i; i < _assets.length; i++) {
      proxyAssetAccounting[_assets[i]] -= _amounts[i];
    }
  }
}
