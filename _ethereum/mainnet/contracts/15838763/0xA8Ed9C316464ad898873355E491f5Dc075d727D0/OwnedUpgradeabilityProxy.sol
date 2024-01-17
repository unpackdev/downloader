// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "./ContextMixin.sol";
import "./Proxy.sol";
import "./OwnedUpgradeabilityStorage.sol";
/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy 
is Proxy,
 OwnedUpgradeabilityStorage,
 ContextMixin
 {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() override public view returns (address) {
        return _implementation;
    }

    /**
     * @dev Tells the proxy type (EIP 897)
     * @return proxyTypeId Proxy type, 2 for forwarding proxy
     */
    function proxyType() override external pure returns (uint256 proxyTypeId) {
        return 2;
    }

    /**
     * @dev Upgrades the implementation address
     * @param implementationAddress representing the address of the new implementation to be set
     */
    function _upgradeTo(address implementationAddress) internal {
        require(_implementation != implementationAddress, "Proxy already uses this implementation");
        require(implementationAddress != address(0), "Implementation address cannot be zero address");
        _implementation = implementationAddress;
        emit Upgraded(implementationAddress);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(_msgSender() == proxyOwner(), "Only the proxy owner can call this method");
        _;
    }

    /**
     * @dev Tells the address of the proxy owner
     * @return the address of the proxy owner
     */
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) external onlyProxyOwner {
        require(newOwner != address(0), "New owner cannot be the null address");
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
     * @param implementationAddress representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementationAddress) public onlyProxyOwner {
        _upgradeTo(implementationAddress);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
     * and delegatecall the new implementation for initialization.
     * @param implementationAddress representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address implementationAddress, bytes memory data) external payable onlyProxyOwner {
        upgradeTo(implementationAddress);
        (bool success,) = address(this).delegatecall(data);
        require(success, "Call failed after proxy upgrade");
    }

    function _msgSender() internal view returns (address sender) {
        return ContextMixin.msgSender();
    }

}
