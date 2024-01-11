// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./YieldsterVaultProxy.sol";
import "./IProxyCreationCallback.sol";
import "./IAPContract.sol";

contract YieldsterVaultProxyFactory {
    address private mastercopy;
    address private APContract;
    address private owner;

    event ProxyCreation(YieldsterVaultProxy proxy);

    constructor(address _mastercopy, address _APContract)  {
        mastercopy = _mastercopy;
        APContract = _APContract;
        owner = msg.sender;
    }

    function setMasterCopy(address _mastercopy) public {
        require(msg.sender == owner, "Not Authorized");
        mastercopy = _mastercopy;
    }

    function setAPContract(address _APContract) public {
        require(msg.sender == owner, "Not Authorized");
        APContract = _APContract;
    }

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(bytes memory data)
        public
        returns (address)
    {
       YieldsterVaultProxy proxy = new YieldsterVaultProxy(mastercopy);
        if (data.length > 0) 
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0),0) {
                    revert(0, 0)
                }
            }
        
        IAPContract(APContract).setVaultStatus(address(proxy));
        emit ProxyCreation(proxy);
        return address(proxy);
    }

    /// @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(YieldsterVaultProxy).runtimeCode;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(YieldsterVaultProxy).creationCode;
    }
}
