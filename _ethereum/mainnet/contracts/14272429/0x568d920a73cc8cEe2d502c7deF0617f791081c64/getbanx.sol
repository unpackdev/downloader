// SPDX-License-Identifier: MIT
//__________    _____    _______  ____  ___
//\______   \  /  _  \   \      \ \   \/  /
// |    |  _/ /  /_\  \  /   |   \ \     / 
// |    |   \/    |    \/    |    \/     \ 
// |______  /\____|__  /\____|__  /___/\  \
//        \/         \/         \/      \_/

pragma solidity >=0.8.0 <0.9.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Airdrop is Ownable {
  using SafeMath for uint256;

  IERC20 public token;

  mapping (address=>uint256) public airdrop;
  bool public locked = false;

  address[] private wallets;

  constructor(address _token) {
    token = IERC20(_token);
  }

  event claimAirdrop(address _wallet, uint256 _amount);
  event clearContract();

  modifier isLocked(){
        require(!locked, "Sorry, the contract is locked");
        _;
    }

  function changeLock(bool newLock) external onlyOwner{
    locked = newLock;
  }

  function getAirdrop() external isLocked {
    uint256 amount = airdrop[msg.sender];
    require(amount > 0, "No airdrop for this address");
    airdrop[msg.sender] = 0;

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
    emit claimAirdrop(msg.sender, amount);
  }

  function addAirdrop(address[] memory _wallets, uint256[] memory _amounts) external onlyOwner{
    require(_wallets.length != 0 && _amounts.length != 0, "Missing data");
    require(_wallets.length == _amounts.length, "Both lists need to be the same length");

    uint256 totalNew;
    for (uint256 index = 0; index < _amounts.length; index++) {
      totalNew += _amounts[index];
    }

    uint256 totalSored;
    for (uint256 index = 0; index < wallets.length; index++) {
      totalSored += airdrop[ wallets[index] ];
    }
    require(token.balanceOf( address(this) ) >= totalNew + totalSored, "You don't have enough balance for this airdrop");

    for (uint256 i = 0; i < _wallets.length; i++) {
      airdrop[_wallets[i]] += _amounts[i];

      bool foundWallet = false;
      for (uint256 j = 0; j < wallets.length; j++) {
        if(_wallets[i] == wallets[j]){
          foundWallet = true;
        }
      }
      if(!foundWallet){
        wallets.push(_wallets[i]);
      }
    }
  }

  function clearAllAirdrops() private {
    for (uint256 index = 0; index < wallets.length; index++) {
      airdrop[wallets[index]] = 0;
    }
    delete wallets;
  }

  function withdraw(address to) external onlyOwner{
    uint256 tokenBalance = token.balanceOf( address(this) );
    require( tokenBalance > 0, "Not enough balance");
    clearAllAirdrops();
    token.transfer(to, tokenBalance);
    emit clearContract();
  }

  function count() external view returns(uint256){
    return wallets.length;
  }

}