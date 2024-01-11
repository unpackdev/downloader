// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./Ownable.sol";

contract WhiteList is Ownable{

  uint256 nbWLSC = 0;
  uint256 nbCurrentWLC = 0;
  mapping(address => bool) wlC;
  mapping(address => bool) wlMintedC;

  constructor(uint256 _nbWLSC) {nbWLSC = _nbWLSC;}

  function nbWLSCValue() view external returns(uint256){return nbWLSC;}
  function isWL(address _user) view external returns(bool){return wlC[_user];}
  function isWLM(address _user) view external returns(bool){return wlMintedC[_user];}

  function WLM(address _msgsender) external {
    require(wlC[_msgsender] == true, "Wallet not whitelisted contest");
    require(wlMintedC[_msgsender] != true, "Wallet minted for the contest");
    wlMintedC[_msgsender] = true;
  }

  function WLA(address _user) external onlyOwner{
    require(wlC[_user] != true, "Wallet whitelisted in contest");
    require(nbCurrentWLC < nbWLSC, "Max whitelisted Wallet contest");
    wlC[_user] = true;
    wlMintedC[_user] = false;
    nbCurrentWLC++;
  }

}