// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
@title RootChain Manager Interface for Polygon Bridge.
*/
interface IRootChainManager {
    function depositEtherFor(address user) external payable;

    function depositFor(
        address sender,
        address token,
        bytes memory extraData
    ) external;
}

/**
@title FxState Sender Interface if FxPortal Bridge is used.
*/
interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data)
        external;
}
