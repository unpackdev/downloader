// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract SlykSimpleForwarder {
  address payable target;

  constructor(address payable _target) {
      require(_target != address(0x0));
      target = _target;
  }

  receive() external payable {
    (bool result,) = target.call{value: msg.value}("");
    require(result);
  }

  function flush() public {
    target.transfer(address(this).balance);
  }

  function flushToken(IERC20 token) public {
    token.transfer(target, token.balanceOf(address(this)));
  }
}