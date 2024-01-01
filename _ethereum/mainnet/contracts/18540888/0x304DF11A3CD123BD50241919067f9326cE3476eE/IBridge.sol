// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBridge {
    event TokenSent(bytes32 id, address sender, uint dstChainId, address receiver, uint amount);
    event TokenSentAck(uint dstChainId, bytes32 id);
    event TokenReceived(bytes32 id, address sender, uint srcChainId, address receiver, uint amount);

    function send(uint _dstChainId, address _receiver, uint _amount) external payable;

    function sendAck(uint _dstChainId, bytes32 _id) external;

    function recv(bytes32 _id, address _sender, uint _srcChainId, address _receiver, uint _amount) external;

    function transferAdmin(address _newAdmin) external;

    function setSupportedChain(uint _dstChainId, bool _isSupported) external;

    function recvConfirmations(uint _srcChainId, bytes32 _txHash) external view returns (bool);

    function sendAcks(uint _dstChainId, bytes32 _txHash) external view returns (bool);

    function innerToken() external view returns (address);

    function supportedChains(uint _dstChainId) external view returns (bool);
}
