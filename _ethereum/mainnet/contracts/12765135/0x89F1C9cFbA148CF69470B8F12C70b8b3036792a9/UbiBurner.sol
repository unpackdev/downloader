// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUBI.sol";

contract UbiBurner {
    event Burn(address token, uint256 amount);

    function burn(address _address, uint256 _amount) public {
      IUBI(_address).burn(_amount);
      emit Burn(_address, _amount);
    }
}
