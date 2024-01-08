// SPDX-License-Identifier: GPL-3.0-or-later

/**   ____________________________________________________________________________________        
     ___________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\________/\/\/\/\/\/\_________
    _________/\/\____/\/\______/\/\____/\/\______/\/\____/\/\____________/\/\___________ 
   _________/\/\____/\/\______/\/\____/\/\______/\/\/\/\/\____________/\/\_____________  
  _________/\/\____/\/\______/\/\____/\/\______/\/\__/\/\__________/\/\_______________   
 ___________/\/\/\/\__________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\/\_________    
____________________________________________________________________________________ */

pragma solidity 0.8.4;

import "./OurStorage.sol";

interface IOurFactory {
    function pylon() external returns (address);

    function merkleRoot() external returns (bytes32);
}

/**
 * @title OurProxy
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

contract OurProxy is OurStorage {
    constructor() {
        _pylon = IOurFactory(msg.sender).pylon();
        merkleRoot = IOurFactory(msg.sender).merkleRoot();
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address impl = pylon();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    function pylon() public view returns (address) {
        return _pylon;
    }
}
