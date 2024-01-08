// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IUtility {
    enum TokenAction {Pause, Unpause}

    function pauseToken(address _tokenAddress, bytes[] calldata _signatures) external;
    function unpauseToken(address _tokenAddress, bytes[] calldata _signatures) external;

    function setWrappedToken(uint8 _nativeChainId, bytes memory _nativeToken, address _wrappedToken, bytes[] calldata _signatures) external;
    function unsetWrappedToken(address _wrappedToken, bytes[] calldata _signatures) external;

    event TokenPause(address _account, address _token);
    event TokenUnpause(address _account, address _token);
    event WrappedTokenSet(uint8 _nativeChainId, bytes _nativeToken, address _wrappedToken);
    event WrappedTokenUnset(address _wrappedToken);
}
