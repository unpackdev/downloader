// SPDX-License-Identifier: GPL-3.0-or-later

/**   ____________________________________________________________________________________        
     ___________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\________/\/\/\/\/\/\_________
    _________/\/\____/\/\______/\/\____/\/\______/\/\____/\/\____________/\/\___________ 
   _________/\/\____/\/\______/\/\____/\/\______/\/\/\/\/\____________/\/\_____________  
  _________/\/\____/\/\______/\/\____/\/\______/\/\__/\/\__________/\/\_______________   
 ___________/\/\/\/\__________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\/\_________    
____________________________________________________________________________________ */

pragma solidity 0.8.4;

import "./OurSplitter.sol";
import "./OurMinter.sol";
import "./OurIntrospector.sol";

/**
 * @title OurPylon
 * @author Nick A.
 * https://github.com/ourz-network/our-contracts
 *
 * These contracts enable creators, builders, & collaborators of all kinds
 * to receive royalties for their collective work, forever.
 *
 * Thank you,
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * @author OpenZeppelin                 https://github.com/OpenZeppelin/openzeppelin-contracts
 * @author Zora                         https://github.com/ourzora
 */

contract OurPylon is OurSplitter, OurMinter, OurIntrospector {
    // Disables modification of Pylon after deployment
    constructor() {
        threshold = 1;
    }

    /**
     * @dev Setup function sets initial storage of Poxy.
     * @param owners_ List of addresses that can execute transactions other than claiming funds.
     * @notice see OurManagement -> setupOwners()
     * @notice approves Zora AH to handle Zora ERC721s
     */
    function setup(address[] calldata owners_) external {
        setupOwners(owners_);
        emit SplitSetup(owners_);

        // Approve Zora AH
        _setApprovalForAH();
    }
}
