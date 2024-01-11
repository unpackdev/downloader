// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
_____ _               _            ______    
| ___ \ |             | |           | ___ \   
| |_/ / | ___   ___   | | ___   ___ | |_/ /__ 
| ___ \ |/ _ \ / _ \  | |/ _ \ / _ \|  __/ __|
| |_/ / | (_) | (_) | | | (_) | (_) | |  \__ \
\____/|_|\___/ \___/  |_|\___/ \___/\_|  |___/
                                              
 https://blooloops.io/                                             
                                                                                                         
*/

import "./BlooLoopsPaymentSplitter.sol";

contract BlooLoopsRoyaltiesSplitter is BlooLoopsPaymentSplitter {
  constructor(address[] memory payees, uint256[] memory shares) BlooLoopsPaymentSplitter(payees, shares) {}
}