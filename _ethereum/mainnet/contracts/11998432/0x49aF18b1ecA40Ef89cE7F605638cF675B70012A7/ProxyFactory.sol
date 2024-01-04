// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Clones.sol";


library ProxyFactory
{
  event ProxyCreated(address proxy);


  function _deployMinimal(address logic, bytes memory data) internal returns (address proxy)
  {
    // deploy clone
    proxy = Clones.clone(logic);

    // attempt initialization
    if (data.length > 0)
    {
      (bool success,) = proxy.call(data);
      require(success, "ProxyFactory: init err");
    }

    emit ProxyCreated(proxy);

    return proxy;
  }
}
