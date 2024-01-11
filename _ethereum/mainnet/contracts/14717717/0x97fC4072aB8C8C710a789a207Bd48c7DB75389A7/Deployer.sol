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
import "./Clones.sol";
import "./DonationSplitter.sol";
contract Deployer {
  event ContractDeployed(address indexed owner, address indexed group, address donationAddress);
  address public immutable implementation;
  constructor() {
    implementation = address(new DonationSplitter());
  }
  function genesis(address donationAddress, uint32 donationPercentage, address ownerAddress) external returns (address) {
    address payable clone = payable(Clones.clone(implementation));
    DonationSplitter d = DonationSplitter(clone);
    d.initialize(donationAddress, donationPercentage, ownerAddress);
    emit ContractDeployed(msg.sender, clone, donationAddress);
    return clone;
  }
}