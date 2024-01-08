// SPDX-License-Identifier: GPL-3.0-or-later

/**   ____________________________________________________________________________________        
     ___________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\________/\/\/\/\/\/\_________
    _________/\/\____/\/\______/\/\____/\/\______/\/\____/\/\____________/\/\___________ 
   _________/\/\____/\/\______/\/\____/\/\______/\/\/\/\/\____________/\/\_____________  
  _________/\/\____/\/\______/\/\____/\/\______/\/\__/\/\__________/\/\_______________   
 ___________/\/\/\/\__________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\/\_________    
____________________________________________________________________________________ */

pragma solidity 0.8.4;

import "./OurProxy.sol";

/**
 * @title OurFactory
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

contract OurFactory {
    //======== Immutable storage =========
    address public immutable pylon;

    //======== Mutable storage =========
    /// @dev Gets set within the block, and then deleted.
    bytes32 public merkleRoot;

    //======== Subgraph =========
    event SplitCreated(
        address ourProxy,
        address proxyCreator,
        string splitRecipients,
        string nickname
    );

    //======== Constructor =========
    constructor(address pylon_) {
        pylon = pylon_;
    }

    //======== Deploy function =========
    function createSplit(
        bytes32 merkleRoot_,
        bytes memory data,
        string calldata splitRecipients_,
        string calldata nickname_
    ) external returns (address ourProxy) {
        merkleRoot = merkleRoot_;
        ourProxy = address(
            new OurProxy{salt: keccak256(abi.encode(merkleRoot_))}()
        );
        delete merkleRoot;

        emit SplitCreated(ourProxy, msg.sender, splitRecipients_, nickname_);

        // call setup() to set Owners of Split
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if eq(
                call(gas(), ourProxy, 0, add(data, 0x20), mload(data), 0, 0),
                0
            ) {
                revert(0, 0)
            }
        }
    }
}
