// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.3;

interface IMultiTokenMediator {
    function relayTokens(
        address token,
        address _receiver,
        uint256 _value
    ) external;

    function bridgeContract() external view returns (address);
}
