// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./IInterconnector.sol";
import "./IProxyONFT1155.sol";

interface IInterconnectorV2 is IInterconnector {
    function proxyONFT1155() external view returns (IProxyONFT1155);
}
