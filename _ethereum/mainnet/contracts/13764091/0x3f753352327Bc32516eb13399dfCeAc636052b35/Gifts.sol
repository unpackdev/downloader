// SPDX-License-Identifier: MIT

// _________  ________  ________  _________
//|\___   ___\\   __  \|\   __  \|\___   ___\
//\|___ \  \_\ \  \|\ /\ \  \|\  \|___ \  \_|
//     \ \  \ \ \   __  \ \  \\\  \   \ \  \
//      \ \  \ \ \  \|\  \ \  \\\  \   \ \  \
//       \ \__\ \ \_______\ \_______\   \ \__\
//        \|__|  \|_______|\|_______|    \|__|

pragma solidity >=0.8.0 <0.9.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Gifts is Ownable {
  using SafeMath for uint256;

  IERC20 public token;

  struct Deposit{
    address receiver;
    uint256 amount;
  }

  mapping (address => uint256) public gifts;
  mapping (address => Deposit[]) private deposits;

  address[] private wallets;

  constructor(address _token) {
    token = IERC20(_token);
  }

  event claimGift(address _wallet, uint256 _amount);

  function getGifts() external {
    uint256 amount = gifts[msg.sender];
    require(amount > 0, "No gifts for this address");
    gifts[msg.sender] = 0;

    uint walletIndex;
    for (uint256 index = 0; index < wallets.length; index++) {
      if(wallets[index] == msg.sender){
        walletIndex = index;
      }
    }

    for (uint256 index = walletIndex; index < wallets.length - 1; index++) {
      wallets[index] = wallets[index+1];
    }
    wallets.pop();

    token.transfer(msg.sender, amount);
    emit claimGift(msg.sender, amount);
  }

  function addGifts(address[] memory _wallets, uint256[] memory _amounts) external {
    uint256 _walletsLength = _wallets.length;
    uint256 walletsLength = wallets.length;

    require(_walletsLength != 0 && _amounts.length != 0, "Missing data");
    require(_walletsLength == _amounts.length, "Both lists need to be the same length");

    uint256 totalNew;
    for (uint256 index = 0; index < _walletsLength; index++) {
      totalNew += _amounts[index];
    }

    require(token.allowance(msg.sender, address(this)) >= totalNew, "Not enough allowance to send tokens");

    token.transferFrom(msg.sender, address(this), totalNew);

    for (uint256 i = 0; i < _walletsLength; i++) {
      gifts[_wallets[i]] += _amounts[i];

      Deposit memory deposit;
      deposit.receiver = _wallets[i];
      deposit.amount = _amounts[i];
      deposits[msg.sender].push(deposit);

      bool foundWallet = false;
      for (uint256 j = 0; j < walletsLength; j++) {
        if(_wallets[i] == wallets[j]){
          foundWallet = true;
        }
      }
      if(!foundWallet){
        wallets.push(_wallets[i]);
      }
    }
  }

  function getDeposits(address _address) external view returns(Deposit[] memory){
    return deposits[_address];
  }

}
