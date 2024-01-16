// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./ERC2771Context.sol";

contract MMRegistry is ERC2771Context, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // deployer address => [proxy contract addresses]
    mapping(address => EnumerableSet.AddressSet) private deployments;

    mapping(address => bytes32) public proxyType;

    event Added(address indexed deployer, address indexed deployment);
    event Deleted(address indexed deployer, address indexed deployment);

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {}

    function add(
        address _deployer,
        address _proxy,
        bytes32 _type
    ) external {
        // require(
        //     owner() == _msgSender() || _deployer == _msgSender(),
        //     "Dont have permission for this operation"
        // );

        bool success = deployments[_deployer].add(_proxy);
        require(success, "Failed to add to registry");

        proxyType[_proxy] = _type;

        emit Added(_deployer, _proxy);
    }

    function remove(address _deployer, address _proxy) external {
        // require(
        //     owner() == _msgSender() || _deployer == _msgSender(),
        //     "Dont have permission for this operation"
        // );

        delete proxyType[_proxy];

        bool success = deployments[_deployer].remove(_proxy);
        require(success, "Failed to remove from registry");

        emit Deleted(_deployer, _proxy);
    }

    function getAll(address _deployer)
        external
        view
        returns (address[] memory)
    {
        return deployments[_deployer].values();
    }

    function count(address _deployer) external view returns (uint256) {
        return deployments[_deployer].length();
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}
