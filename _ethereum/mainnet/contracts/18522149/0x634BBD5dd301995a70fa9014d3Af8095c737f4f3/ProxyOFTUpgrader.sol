// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract ProxyOFTUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @inheritdoc UpgraderBase
    function _calls() internal pure virtual override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](1);
        _callsList[0] = abi.encodeWithSignature("syntheticToken()");
    }
}

contract ProxyOFTUpgraderV2 is ProxyOFTUpgrader {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _owner) ProxyOFTUpgrader(_owner) {}

    /// @inheritdoc UpgraderBase
    function _calls() internal pure virtual override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](1);
        _callsList[0] = abi.encodeWithSignature("token()");
    }
}
