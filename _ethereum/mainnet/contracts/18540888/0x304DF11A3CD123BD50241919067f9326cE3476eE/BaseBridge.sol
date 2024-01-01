// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AccessControlUpgradeable.sol";
import "./IBridge.sol";

abstract contract BaseBridge is IBridge, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    address public innerToken;
    mapping(uint => mapping(bytes32 => bool)) public recvConfirmations;
    mapping(uint => mapping(bytes32 => bool)) public sendAcks;
    mapping(uint => bool) public supportedChains;
    uint public totalBridgedAmount;
    uint public nonce;
    uint public feeAmount;
    address public feeReceiver;

    function __Bridge_init(address _token) public onlyInitializing {
        innerToken = _token;
        _setRoleAdmin(KEEPER_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function transferAdmin(address _newAdmin) external onlyRole(ADMIN_ROLE) {
        _revokeRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, _newAdmin);
    }

    function setSupportedChain(uint _dstChainId, bool _isSupported) external onlyRole(ADMIN_ROLE) {
        supportedChains[_dstChainId] = _isSupported;
    }

    function setFeeAmount(uint _feeAmount) external onlyRole(ADMIN_ROLE) {
        feeAmount = _feeAmount;
    }

    function setFeeReceiver(address _feeReceiver) external onlyRole(ADMIN_ROLE) {
        feeReceiver = _feeReceiver;
    }

    // anyone wants to bridge can call this function
    function send(uint _dstChainId, address _receiver, uint _amount) external payable {
        require(supportedChains[_dstChainId], "Bridge: chain not supported");
        require(_amount > 0, "Bridge: amount must be greater than 0");

        require(msg.value >= feeAmount, "Bridge: fee not enough");
        if (feeAmount > 0) {
            (bool success,) = feeReceiver.call{value: feeAmount}("");
            require(success, "Bridge: fee transfer failed");
        }

        bytes32 id = _generateId();
        _sendToken(_amount);
        emit TokenSent(id, msg.sender, _dstChainId, _receiver, _amount);
    }

    function sendAck(uint _dstChainId, bytes32 _id) external onlyRole(KEEPER_ROLE) {
        require(sendAcks[_dstChainId][_id] == false, "Bridge: tx already acked");
        sendAcks[_dstChainId][_id] = true;
        emit TokenSentAck(_dstChainId, _id);
    }

    // only the bot with admin private key can call this function
    function recv(bytes32 _id, address _sender, uint _srcChainId, address _receiver, uint _amount) external onlyRole(KEEPER_ROLE) {
        require(recvConfirmations[_srcChainId][_id] == false, "Bridge: tx already confirmed");
        recvConfirmations[_srcChainId][_id] = true;

        _recvToken(_receiver, _amount);

        emit TokenReceived(_id, _sender, _srcChainId, _receiver, _amount);
    }

    function _generateId() internal returns (bytes32) {
        nonce++;
        return keccak256(abi.encodePacked(nonce));
    }

    function _sendToken(uint _amount) internal virtual;

    function _recvToken(address _receiver, uint _amount) internal virtual;

}
