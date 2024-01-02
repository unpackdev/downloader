// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./AaveV2Ethereum.sol";
import "./AaveV3Ethereum.sol";
import "./IProposalGenericExecutor.sol";

/**
 * @title Redeem CRV from AaveV2Ethereum and Transfer to GLC
 * @author efecarranza.eth
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xf92c5647c7f60a4a3db994b4953fc4408f5946cafdc0cebcd4c5924f40e04d36
 * - Discussion: https://governance.aave.com/t/arfc-deploy-acrv-crv-to-vecrv/11628
 */
contract AaveV2Ethereum_RedeemCRVFromAaveV2EthereumAndTransferToGLC_20231123 is
  IProposalGenericExecutor
{
  address public constant GLC_SAFE = 0x205e795336610f5131Be52F09218AF19f0f3eC60;

  function execute() external {
    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.CRV_A_TOKEN,
      address(this),
      IERC20(AaveV2EthereumAssets.CRV_A_TOKEN).balanceOf(address(AaveV2Ethereum.COLLECTOR))
    );

    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV3EthereumAssets.CRV_A_TOKEN,
      address(this),
      IERC20(AaveV3EthereumAssets.CRV_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR))
    );

    AaveV2Ethereum.COLLECTOR.transfer(
      AaveV2EthereumAssets.CRV_UNDERLYING,
      GLC_SAFE,
      IERC20(AaveV2EthereumAssets.CRV_UNDERLYING).balanceOf(address(AaveV2Ethereum.COLLECTOR))
    );

    AaveV2Ethereum.POOL.withdraw(AaveV2EthereumAssets.CRV_UNDERLYING, type(uint256).max, GLC_SAFE);

    AaveV3Ethereum.POOL.withdraw(AaveV3EthereumAssets.CRV_UNDERLYING, type(uint256).max, GLC_SAFE);
  }
}
