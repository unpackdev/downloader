// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address owner) external view returns (uint256);
  function delegate(address delegator) external;
  function approve(address spender, uint amount) external returns (bool);
}

contract InstaDelegateClone is Initializable {
  event LogDelegate(address owner, address delegatee);
  event LogChangeOwner(address oldOwner, address newOwner);
  event LogWithdraw(address owner, uint256 amount);

  IERC20 constant public token = IERC20(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb); // INST token
  address public owner;

  modifier isOwner {
    require(owner == msg.sender, "not-owner");
    _;
  }

  function initialize(address _owner, address _delegatee) external initializer {
      require(_owner != address(0), "address-not-valid");
      owner = _owner;
      token.delegate(_delegatee);
      emit LogDelegate(owner, _delegatee);
  }

  function delegate(address _delegatee) external isOwner {
      token.delegate(_delegatee);
      emit LogDelegate(owner, _delegatee);
  }

  function changeOwner(address _newOwner) external isOwner {
      require(_newOwner != address(0), "not-vaild-new-owner");
      emit LogChangeOwner(owner, _newOwner);
      owner = _newOwner;
  }

  function withdrawToken(uint amount) public isOwner {
      uint256 _amount = amount == uint256(-1) ? token.balanceOf(address(this)) : amount;
      require(token.transfer(msg.sender, _amount), "transfer-failed");
      emit LogWithdraw(msg.sender, _amount);
  }

  function spell(address _target, bytes memory _data) external isOwner {
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