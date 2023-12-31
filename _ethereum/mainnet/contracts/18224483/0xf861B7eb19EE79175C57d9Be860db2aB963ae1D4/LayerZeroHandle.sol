// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

import "./IUserApplication.sol";
import "./IBridgeHandle.sol";
import "./NonblockingLzApp.sol";

contract LayerZeroHandle is Initializable, LzApp, IBridgeHandle {

    event SendLzMessage(uint64 indexed nonce, uint16 dstChainId, address dstAddress, bytes32 messageHash);

    event ReceiveLzMessage(uint64 indexed nonce, uint16 srcChainId, address srcAddress, bytes32 messageHash);

    event NewChainMapping(uint16 uaChainId, uint16 bridgeChainId);

    event ModUserApplication(address oldUserApplication, address newUserApplication);

    //l0ChainId=> ua chainId
    mapping(uint16 => uint16) public uaChainIdMapping;

    //ua chainId=>l0ChainId
    mapping(uint16 => uint16) public bridgeChainIdMapping;

    IUserApplication public userApplication;

    // zkBridgeHandle or l0BridgeHandle
    string public label;

    function initialize(address _userApplication, address _lzEndpoint, string memory _label) public initializer {
        __Ownable_init();
        userApplication = IUserApplication(_userApplication);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        label = _label;
    }

    function sendMessage(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, bytes memory _adapterParams, uint _nativeFee) payable external {
        require(msg.sender == address(userApplication), "LayerZeroHandle:not a trusted source");
        uint16 bridgeChainId = _getBridgeChainId(_dstChainId);
        uint64 nonce = _lzSend(bridgeChainId, _payload, _refundAddress, address(this), _adapterParams, _nativeFee);
        bytes memory _bytes = getTrustedRemoteAddress(bridgeChainId);
        address dstAddress;
        assembly {
            dstAddress := mload(add(_bytes, 20))
        }
        emit SendLzMessage(nonce, bridgeChainId, dstAddress, keccak256(_payload));
    }

    function estimateFees(uint16 _dstChainId, bytes calldata _payload, bytes calldata _adapterParam) external view returns (uint256 fee){
        (fee,) = lzEndpoint.estimateFees(_getBridgeChainId(_dstChainId), address(this), _payload, false, _adapterParam);
    }

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal override {
        bytes memory _bytes = getTrustedRemoteAddress(_srcChainId);
        address srcAddress;
        assembly {
            srcAddress := mload(add(_bytes, 20))
        }
        userApplication.receiveMessage(_getUaCHainId(_srcChainId), srcAddress, _nonce, _payload);
        emit ReceiveLzMessage(_nonce, _srcChainId, srcAddress, keccak256(_payload));
    }

    function _getBridgeChainId(uint16 uaChainId) internal view returns (uint16) {
        uint16 bridgeChainId = bridgeChainIdMapping[uaChainId];
        if (bridgeChainId == 0) {
            bridgeChainId = uaChainId;
        }
        return bridgeChainId;
    }

    function _getUaCHainId(uint16 bridgeChainId) internal view returns (uint16) {
        uint16 uaChainId = uaChainIdMapping[bridgeChainId];
        if (uaChainId == 0) {
            uaChainId = bridgeChainId;
        }
        return uaChainId;
    }

    function setChainMapping(uint16 uaChainId, uint16 bridgeChainId) external onlyOwner {
        bridgeChainIdMapping[uaChainId] = bridgeChainId;
        uaChainIdMapping[bridgeChainId] = uaChainId;
        emit NewChainMapping(uaChainId, bridgeChainId);
    }

    function setUa(address _userApplication) external onlyOwner {
        require(_userApplication != address(0), "LayerZeroHandle:to Cannot be zero address");
        emit ModUserApplication(address(userApplication), _userApplication);
        userApplication = IUserApplication(_userApplication);
    }


    function setLabel(string calldata _label) external onlyOwner {
        require(bytes(_label).length > 0, "ZKBridgeHandle:invalid label");
        label = _label;
    }
}
