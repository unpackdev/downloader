// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address owner) external view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function delegate(address delegator) external;
  function approve(address spender, uint amount) external returns (bool);
}

contract InstaDelegateClone is Initializable {
  event LogDelegate(address delegator, address delegatee);
  event LogWithdraw(address delegator, uint256 amount);

  IERC20 constant public token = IERC20(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb); // INST token
  address public delegator;

  function initialize(address _delegator, address _delegatee) external initializer {
      require(_delegator != address(0), "address-not-valid");
      delegator = _delegator;
      token.delegate(_delegatee);
      emit LogDelegate(delegator, _delegatee);
  }

  function delegate(address _delegatee) external {
      require(delegator == msg.sender, "not-delegator");
      token.delegate(_delegatee);
      emit LogDelegate(delegator, _delegatee);
  }

  function withdrawToken(uint amount) public {
      require(delegator == msg.sender, "not-delegator");
      uint256 _amount = amount == uint256(-1) ? token.balanceOf(address(this)) : amount;
      require(token.transfer(msg.sender, _amount), "transfer-failed");
      emit LogWithdraw(msg.sender, _amount);
  }

  function spell(address _target, bytes memory _data) external {
    require(msg.sender == delegator, "not-delegator");
    require(_target != address(0), "target-invalid");
    assembly {
      let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)

      switch iszero(succeeded)
        case 1 {
            // throw if delegatecall failed
            let size := returndatasize()
            returndatacopy(0x00, 0x00, size)
            revert(0x00, size)
        }
    }
  }
}