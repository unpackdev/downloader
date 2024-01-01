// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./AaveV2Ethereum.sol";

contract V2EthSTokenPayloadExtra {
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
    TokenToUpdate[] memory tokensToUpdate = new TokenToUpdate[](3);

    tokensToUpdate[0] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.DAI_UNDERLYING,
      newSTokenImpl: 0xb44Fe5fA7A8fcF508984bE58bA807A22343B4493
    });
    tokensToUpdate[1] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.UNI_UNDERLYING,
      newSTokenImpl: 0x54f514CA167e1fc19231dA9a48bB7AA6ffe4F10d
    });
    tokensToUpdate[2] = TokenToUpdate({
      underlyingAsset: AaveV2EthereumAssets.TUSD_UNDERLYING,
      newSTokenImpl: 0x00C15a6aaF1e48763B53A9dc8D2077551BA45Fee
    });

    return tokensToUpdate;
  }
}
