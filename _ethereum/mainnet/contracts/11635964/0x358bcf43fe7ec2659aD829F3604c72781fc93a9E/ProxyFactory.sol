pragma solidity ^0.6.12;

contract ProxyFactory {
  /**
   * @dev This function enables deployment of EIP-1167 minimal proxies. The code below
   * was copied from the OpenZeppelin ProxyFactory.sol contract, as there is currently
   * no package that has a version compatible with Solidity ^0.6.0. EIP-1167 references:
   *   The EIP
   *     - https://eips.ethereum.org/EIPS/eip-1167
   *   Clone Factory repo and projects, included with the associated EIP
   *     - https://github.com/optionality/clone-factory
   *     - https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
   *   Open Zeppelin blog post and discussion
   *     - https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
   *     - https://forum.openzeppelin.com/t/deep-dive-into-the-minimal-proxy-contract/1928
   *   OpenZeppelin implementation that provided the source of this function
   *     - https://github.com/OpenZeppelin/openzeppelin-sdk/blob/b3e945251a7c786dbb8197cb7703acc8326f4a51/packages/lib/contracts/upgradeability/ProxyFactory.sol#L18-L35
   */
  function deployMinimal(address _logic, bytes memory _data) public returns (address proxy) {
    // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
    bytes20 targetBytes = bytes20(_logic);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x37)
    }

    if (_data.length > 0) {
      (bool success, ) = proxy.call(_data);
      require(success, "ProxyFactory: Initialization of proxy failed");
    }
  }
}
