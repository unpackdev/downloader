// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// Import from Core /////
import "./AddressRegistry.sol";
import "./AssetRegistry.sol";
import "./ProtocolState.sol";
import "./TRSY.sol";

/// Structs /////
import "./Structs.sol";

// Interface
import "./IERC20.sol";
import "./SafeERC20.sol";

///@title GovernanceAccess contract
///@notice Exposes functions for the governance module
abstract contract GovernanceAccess is TRSY, AddressRegistry, ProtocolState, AssetRegistry {
  using SafeERC20 for IERC20;

  ///@notice Called by the governance module in order to transfer asset when proxy is funded
  ///@param _asset asset address
  ///@param _recipient user address
  ///@param _amount number of token
  function transferAsset(address _asset, address _recipient, uint256 _amount)
    external
    onlyGovernance
  {
    IERC20(_asset).safeTransfer(_recipient, _amount);
  }

  ///@notice Called by the governance module in order to update proxy Accounting after rebalancing
  ///@param _asset asset address
  ///@param _amount number of token
  function updateAssetProxyAmount(address _asset, uint256 _amount) external onlyGovernance {
    proxyAssetAccounting[_asset] = _amount;
  }

  ///@notice Called by the governance module in order get all variables for rebalancing in one call
  /// (save gas)
  ///@param _asset asset address
  ///@return RebalanceParam struct with rebalance parameters
  function getRebalanceParams(address _asset) external view returns (RebalanceParam memory) {
    return RebalanceParam(
      _asset,
      totalAssetAccounting[_asset],
      proxyAssetAccounting[_asset],
      getQuote(_asset, 1e18),
      0,
      1e18 * protocolData.aum / totalSupply
    );
  }

  function getQuote(address _asset, uint256 _amount) public view virtual returns (uint256);

  modifier onlyGovernance() {
    if (msg.sender != address(GOVERNANCE_MODULE)) revert Unauthorized();
    _;
  }
}
