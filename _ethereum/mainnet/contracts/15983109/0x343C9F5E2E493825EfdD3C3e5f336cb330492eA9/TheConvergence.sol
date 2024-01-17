// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter.sol";

/// @title The Convergence Drop
/// @author Martin Wawrusch for Roji Inc.
/// @custom:security-contact security@roji.io
contract TheConvergence is ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter {
    constructor() 
                    ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter( 
                      0.09 ether,
                      100,
                      50,
                                                        750,
                                                       "The Convergence", 
                                                       "CONVERGENCE", 
                                                       "https://static.rojiapi.com/meta-the-convergence/") {
   }
}

