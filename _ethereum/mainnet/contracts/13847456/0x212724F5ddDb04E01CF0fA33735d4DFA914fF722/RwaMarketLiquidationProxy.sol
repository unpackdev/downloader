// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ILendingPoolCollateralManager.sol";

interface IRestrictedToken {
  function hasMember(address usr) external view returns (bool);
}

contract RwaMarketLiquidationProxy is ILendingPoolCollateralManager, Ownable {
  address private collateralManager;

  function setManager(address _collateralManager) external onlyOwner {
    collateralManager = _collateralManager;
  }

  function seize(
    address user,
    address[] calldata assets,
    address to
  ) external override returns (uint256, string memory) {
    return (0, "not-allowed");
  }

  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external override returns (uint256, string memory) {
    require(
      IRestrictedToken(collateralAsset).hasMember(msg.sender) == true,
      'sender is not a member for this asset'
    );
    ILendingPoolCollateralManager(collateralManager).liquidationCall(
      collateralAsset,
      debtAsset,
      user,
      debtToCover,
      receiveAToken
    );
  }
}
