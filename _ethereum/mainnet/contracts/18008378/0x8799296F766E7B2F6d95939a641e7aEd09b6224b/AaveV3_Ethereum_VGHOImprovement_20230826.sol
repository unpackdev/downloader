// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AaveV3PayloadEthereum.sol";
import "./AaveV3Ethereum.sol";
import "./AaveV3.sol";
import "./IERC20.sol";

/**
 * @title vGHO improvement: upgrade vGHO implementation + set GHO borrow cap
 * @author BGD Labs @bgdlabs
 * - Discussion: https://governance.aave.com/t/temporarily-pausing-gho-integration-in-aave/14626
 */
contract AaveV3_Ethereum_VGHOImprovement_20230826 is AaveV3PayloadEthereum {
  address public immutable NEW_VGHO_IMPL;

  constructor(address newVGhoImpl) {
    NEW_VGHO_IMPL = newVGhoImpl;
  }

  function _postExecute() internal override {
    AaveV3Ethereum.POOL_CONFIGURATOR.updateVariableDebtToken(
      ConfiguratorInputTypes.UpdateDebtTokenInput({
        asset: AaveV3EthereumAssets.GHO_UNDERLYING,
        incentivesController: AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER,
        name: IERC20(AaveV3EthereumAssets.GHO_V_TOKEN).name(),
        symbol: IERC20(AaveV3EthereumAssets.GHO_V_TOKEN).symbol(),
        implementation: NEW_VGHO_IMPL,
        params: bytes('')
      })
    );
  }

  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);

    capsUpdate[0] = IEngine.CapsUpdate({
      asset: AaveV3EthereumAssets.GHO_UNDERLYING,
      supplyCap: EngineFlags.KEEP_CURRENT,
      borrowCap: 35_000_000
    });

    return capsUpdate;
  }
}
