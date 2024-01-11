// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./WrappedPiErc20Interface.sol";

contract MockPermitUser {
  address private token;

  constructor(address _token) public {
    token = _token;
  }

  function acceptTokens(
    address _from,
    uint256 _amount,
    uint256 _deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    WrappedPiErc20Interface(token).permit(_from, address(this), _amount, _deadline, v, r, s);
    IERC20(token).transferFrom(_from, address(this), _amount);
  }
}
