// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ProtocolLinkage.sol";
import "./IInterconnectorLeaf.sol";

abstract contract InterconnectorLeaf is IInterconnectorLeaf, LinkageLeaf {
    function getInterconnector() public view returns (IInterconnector) {
        return IInterconnector(getLinkageRootAddress());
    }
}
