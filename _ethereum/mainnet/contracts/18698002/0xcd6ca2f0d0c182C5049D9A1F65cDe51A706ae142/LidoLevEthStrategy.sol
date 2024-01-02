// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import "./AffineVault.sol";
import "./LidoLevV3.sol";

///@dev deployed on 12/01/2023
/**
 * Vault eth lev eth staking
 * Strategy info: Lido Lev eth using aave and balancer flash loan
 * withdrawal requires curve to swap steth to eth
 * vault address: 0x1196B60c9ceFBF02C9a3960883213f47257BecdB
 */

contract LidoLevEthStrategy is LidoLevV3 {
    constructor(AffineVault _vault, address[] memory strategists) LidoLevV3(_vault, strategists) {}
}
