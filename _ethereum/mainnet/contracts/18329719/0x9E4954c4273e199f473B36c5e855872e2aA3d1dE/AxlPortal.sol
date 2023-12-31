// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IAxelarGateway.sol";
import "./IAxelarGasService.sol";
import "./AddressString.sol";
import "./AxelarExecutableBase.sol";

interface IPortalToken {
    function portalIn(uint256 _amount, address _from, address _wallet) external;

    function portalOut(uint256 _amount, address _wallet, address _to) external;
}

/**
 * @title Layer Zero Portal
 * @notice Portal implementation that can work with the layer zero messaging bridge
 */
contract AxlPortal is AxelarExecutableBase {
    using AddressToString for address;
    using StringToAddress for string;

    event PortalOut(string destinationChain, address from, address to, uint256 amount);
    event PortalIn(string originChainId, address from, address to, uint256 amount);
    event FalseSender(string sourceChain, string sourceAddress);

    IAxelarGasService public gasService;
    address public d8xToken; // address of the d8x token on that chain
    address internal foreignPortalAddress;

    constructor() {
        // using "borrowed" storage slot to prevent
        // other addresses from calling initialize
        foreignPortalAddress = msg.sender;
    }

    function initialize(address _d8xToken, address _gateway, address _gasService) public {
        require(d8xToken == address(0), "already initialized");
        require(msg.sender == foreignPortalAddress, "only dplr");
        require(_d8xToken != address(0), "zero address");
        foreignPortalAddress = address(this);
        _init(_gateway);
        gasService = IAxelarGasService(_gasService);
        d8xToken = _d8xToken;
    }

    function portalOut(
        string calldata _destinationChain,
        address _recipient,
        uint256 _amount
    ) external payable {
        bytes memory payload = abi.encode(_amount, block.chainid, msg.sender, _recipient);
        // destination address = this
        string memory destinationAddress = foreignPortalAddress.toString();
        // gas
        if (msg.value > 0) {
            gasService.payNativeGasForContractCall{ value: msg.value }(
                foreignPortalAddress,
                _destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
        }
        // register token amount leaving
        _executePortalOut(_amount, msg.sender, 0);
        // send the message/payload to another chain
        gateway.callContract(_destinationChain, destinationAddress, payload);
        emit PortalOut(_destinationChain, msg.sender, _recipient, _amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        if (sourceAddress.toAddress() != foreignPortalAddress) {
            emit FalseSender(sourceChain, sourceAddress);
            return;
        }
        (uint256 amount, uint256 originEVMChainId, address sender, address recipient) = abi.decode(
            payload,
            (uint256, uint256, address, address)
        );
        _executePortalIn(amount, recipient, originEVMChainId);
        emit PortalIn(sourceChain, sender, recipient, amount);
    }

    function _executePortalIn(uint256 _amount, address _recipient, uint256 _evmChainId) internal {
        address from = _createPortalAddress(_evmChainId);
        IPortalToken(d8xToken).portalIn(_amount, from, _recipient);
    }

    function _executePortalOut(uint256 _amount, address _sender, uint256 _evmChainId) internal {
        address to = _createPortalAddress(_evmChainId);
        IPortalToken(d8xToken).portalOut(_amount, _sender, to);
    }

    function _createPortalAddress(uint256 _chainId) internal pure returns (address) {
        uint256 combinedValue = (uint256(0x8D6A7E) << (8 * 17)) | _chainId;
        return address(uint160(combinedValue));
    }
}
