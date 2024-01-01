// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./AaveV2Ethereum.sol";

contract V2EthSTokenPayload {
  struct TokenToUpdate {
    address underlyingAsset;
    address newSTokenImpl;
  }

  function execute() external {
    TokenToUpdate[] memory tokensToUpdate = getTokensToUpdate();

    for (uint256 i = 0; i < tokensToUpdate.length; i++) {
      AaveV2Ethereum.POOL_CONFIGURATOR.updateStableDebtToken(
        tokensToUpdate[i].underlyingAsset,
        tokensToUpdate[i].newSTokenImpl
      );
    }
  }

  function getTokensToUpdate() public pure returns (TokenToUpdate[] memory) {
    TokenToUpdate[] memory tokensToUpdate = new TokenToUpdate[](13);

    tokensToUpdate[0] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.USDT_UNDERLYING,
      newSTokenImpl: 0xC61262D6ad449AC09B4087f46391Dd9A26b5888B
    });
    tokensToUpdate[1] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.WBTC_UNDERLYING,
      newSTokenImpl: 0x4f279f2046870F77cd9Ce63497f8A2D8689ef804
    });
    tokensToUpdate[2] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.WETH_UNDERLYING,
      newSTokenImpl: 0xEd14b4E51B04d4d0211474a721F77C0817166c2f
    });
    tokensToUpdate[3] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.ZRX_UNDERLYING,
      newSTokenImpl: 0xffaCA447191d8196C8Cf96E5912b732063DE4307
    });
    tokensToUpdate[4] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.BAT_UNDERLYING,
      newSTokenImpl: 0x49B6645a9aa05f1Be24893136100467276399470
    });
    tokensToUpdate[5] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.ENJ_UNDERLYING,
      newSTokenImpl: 0x0fB427f800C5E39E7d8029e19F515300d4bb22C2
    });
    tokensToUpdate[6] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.KNC_UNDERLYING,
      newSTokenImpl: 0x22a8FD718924ab2f9dd4D0326DD8ab99Ef21D0b3
    });
    tokensToUpdate[7] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.LINK_UNDERLYING,
      newSTokenImpl: 0x1B80694AF3D4e617c747423f992F532B8baE098b
    });
    tokensToUpdate[8] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.MANA_UNDERLYING,
      newSTokenImpl: 0xe0bf71fF662e8bbeb911ACEa765f4b8be052F59b
    });
    tokensToUpdate[9] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.MKR_UNDERLYING,
      newSTokenImpl: 0xC4CFCE0b16199818Ad942a87902C9172ba005022
    });
    tokensToUpdate[10] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.REN_UNDERLYING,
      newSTokenImpl: 0x6F4B277366e10F68003A0a65Ef8f118f3D60B67E
    });
    tokensToUpdate[11] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.USDC_UNDERLYING,
      newSTokenImpl: 0x8DFF7Fda82976452b6FB957F549944e7af7A3e6F
    });
    tokensToUpdate[12] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.LUSD_UNDERLYING,
      newSTokenImpl: 0x1363602E58e25929A15bE194a3D505Fd6F8BE751
    });

    return tokensToUpdate;
  }
}
