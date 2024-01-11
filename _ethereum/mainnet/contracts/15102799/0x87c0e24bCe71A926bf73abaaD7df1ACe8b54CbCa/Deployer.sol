////////////////////////////////////////////////////////
//                                                    //
//     ____   __   __ _   __  ____  __  __   __ _     //
//    (    \ /  \ (  ( \ / _\(_  _)(  )/  \ (  ( \    //
//     ) D ((  O )/    //    \ )(   )((  O )/    /    //
//    (____/ \__/ \_)__)\_/\_/(__) (__)\__/ \_)__)    //
//    ____  ____  __    __  ____  ____  ____  ____    //
//   / ___)(  _ \(  )  (  )(_  _)(_  _)(  __)(  _ \   //
//   \___ \ ) __// (_/\ )(   )(    )(   ) _)  )   /   //
//   (____/(__)  \____/(__) (__)  (__) (____)(__\_)   //
//                                                    //
//      Built by:    https://cryptoforcharity.io      //
//      Author:      buzzybee.eth                     //
//                                                    //
////////////////////////////////////////////////////////

//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./Clones.sol";
import "./Ownable.sol";
import "./DonationSplitter.sol";
contract Deployer is Ownable {
  address public immutable implementation;
  address[] private _tokens;

  constructor(address wethAddress) {
    implementation = address(new DonationSplitter());

    _tokens = [wethAddress];
  }

  function genesis(address[] calldata donationAddresses, uint32[] calldata donationPercentages, address ownerAddress) external returns (address) {
    address payable clone = payable(Clones.clone(implementation));
    DonationSplitter d = DonationSplitter(clone);
    d.initialize(donationAddresses, donationPercentages, ownerAddress, _tokens);
    return clone;
  }

  function setTokens(address[] calldata tokens) public onlyOwner {
    _tokens = tokens;
  }
}