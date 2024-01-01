// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Ownable.sol";
import "Port3BQLSharesProxy.sol";

contract Port3BQLSharesFactory is Ownable {

    address public tokenImplementation;

    event ImplChanged(address newImplementation);
    event ProxyCreated(address indexed proxy, address deployer);

    constructor(address _bqlSharesImpl, address _owner) Ownable(_owner) {
        tokenImplementation = _bqlSharesImpl; 
        emit ImplChanged(_bqlSharesImpl);
    }

    function setImpl(address newImpl) external onlyOwner {
        tokenImplementation = newImpl;
        emit ImplChanged(newImpl);
    }

    function deployBQLShares(
        string memory _name,
        string memory _symbol, 
        string memory _uri,
        address _sharesSubject,
        address _protocolFeeDestination,
        uint256 _curveBase 
    ) external onlyOwner {
        // owner, _name, _symbol, _uri, _sharesSubject, _protocolFeeDestination, _curveBase
        bytes memory params = abi.encode(msg.sender, _name, _symbol, _uri, _sharesSubject, _protocolFeeDestination, _curveBase);
        _deploy(params);
    }

    function _generateInitData(bytes memory data) private pure returns (bytes memory res) {
        bytes4 selector;
        selector = 0xea2b3316; // abi selector for initializer 
        res = abi.encodePacked(selector, data);
    }

    function _deploy(
        bytes memory params
    ) private returns (address) {
        bytes memory initData = _generateInitData(params);
        bytes memory callData = abi.encode(tokenImplementation, initData);
        bytes memory bytecode = abi.encodePacked(type(Port3BQLSharesProxy).creationCode, callData);
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, params));
        address res;
        assembly {
            res := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(res != address(0), "Shares failed to deploy");
        emit ProxyCreated(res, msg.sender);
        return res;
    }

}

