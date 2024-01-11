/////////////////////////////////////////////////////////////////////////////////////
//
//   ____   __   __ _   __  ____  __  __   __ _   
//  (    \ /  \ (  ( \ / _\(_  _)(  )/  \ (  ( \  
//   ) D ((  O )/    //    \ )(   )((  O )/    /  
//  (____/ \__/ \_)__)\_/\_/(__) (__)\__/ \_)__)  
//   ____  ____  __    __  ____  ____  ____  ____ 
//  / ___)(  _ \(  )  (  )(_  _)(_  _)(  __)(  _ \
//  \___ \ ) __// (_/\ )(   )(    )(   ) _)  )   /
//  (____/(__)  \____/(__) (__)  (__) (____)(__\_)
//
//  SPDX-License-Identifier: MIT
//  Built by: https://cryptoforcharity.io
//  Inspired by: https://moneypipe.xyz
//
/////////////////////////////////////////////////////////////////////////////////////
pragma solidity ^0.8.4;
import "./Initializable.sol";
contract DonationSplitter is Initializable {
  Charity private _charity;
  address private _owner;
  struct Charity {
    address account;
    uint32 percentage;
  }
  function initialize(address c, uint32 p, address o) initializer public {
    _charity = Charity(c, p);
    _owner = o;
  }
  receive () external payable {
    _transfer(_charity.account, msg.value * _charity.percentage / 100);
    _transfer(_owner, msg.value * (100 - _charity.percentage) / 100);
  }
  // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
  error TransferFailed();
  function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
  }
}