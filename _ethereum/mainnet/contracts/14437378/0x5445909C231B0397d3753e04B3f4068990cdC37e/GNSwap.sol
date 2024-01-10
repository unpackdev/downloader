// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";

interface IERC20Decimals is IERC20 {
  function decimals() external view returns (uint8);
}

/**
 * @title GNSwap
 * @dev Swap MONGv1 for MONGv2
 */
contract GNSwap is Ownable {
  IERC20Decimals private gnV1;
  IERC20Decimals private gnV2;

  mapping(address => uint256) public balances;

  mapping(address => bool) public swapped;

  constructor(address _v1, address _v2) {
    gnV1 = IERC20Decimals(_v1);
    gnV2 = IERC20Decimals(_v2);
  }

  function swap() external {
    require(!swapped[msg.sender], 'already swapped V1 for V2');
    require(balances[msg.sender] > 0, 'we do not see your balance');

    // TODO: determine ratio user should receive from V1 to V2
    // and update here
    // uint256 _v2Amount = gnV1.balanceOf(msg.sender);
    uint256 _v2Amount = getV2Amount();
    require(_v2Amount > 0, 'you do not have any V1 tokens');
    require(
      gnV2.balanceOf(address(this)) >= _v2Amount,
      'not enough V2 liquidity to complete swap'
    );
    swapped[msg.sender] = true;
    gnV1.transferFrom(msg.sender, address(this), _v2Amount);
    gnV2.transfer(
      msg.sender,
      (_v2Amount * 10**gnV2.decimals()) / 10**gnV1.decimals()
    );
  }

  function setSwapped(address _wallet, bool _swapped) external onlyOwner {
    swapped[_wallet] = _swapped;
  }

  function v1() external view returns (address) {
    return address(gnV1);
  }

  function v2() external view returns (address) {
    return address(gnV2);
  }

  function getV2Amount() public view returns (uint256) {
    return (balances[msg.sender] * 120) / 100;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function addBalances(address[] memory _users, uint256[] memory _amounts)
    external
    onlyOwner
  {
    require(_users.length == _amounts.length, 'same length');
    for (uint256 i = 0; i < _users.length; i++) {
      balances[_users[i]] = _amounts[i];
    }
  }
}
