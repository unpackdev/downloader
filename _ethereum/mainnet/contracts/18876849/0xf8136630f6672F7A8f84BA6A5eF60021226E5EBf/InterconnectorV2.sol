// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ProtocolLinkage.sol";
import "./IInterconnectorV2.sol";
import "./ISupervisor.sol";
import "./IMinterestNFT.sol";
import "./IWeightAggregator.sol";
import "./IProxyONFT1155.sol";
import "./Interconnector.sol";

/**
 * Immutable storage-less contract with collection of protocol contracts
 */
contract InterconnectorV2 is IInterconnectorV2, Interconnector {
    IProxyONFT1155 public immutable proxyONFT1155;

    constructor(address owner_, address[] memory contractAddresses) Interconnector(owner_, contractAddresses) {
        proxyONFT1155 = IProxyONFT1155(contractAddresses[12]);
    }

    /// @notice Update interconnector version for all leaf contracts
    /// @dev Should include only leaf contracts
    function interconnectInternal() internal virtual override {
        Interconnector.interconnectInternal();
        proxyONFT1155.switchLinkageRoot(_self);
    }
}
