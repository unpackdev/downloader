pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./stores.sol";
import "./interfaces.sol";

abstract contract Helpers is Stores {
    /**
     * @dev Insta index
     */
    IndexInterface constant internal instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

    /**
     * @dev Maker MCD Manager
     */
    ManagerLike constant internal mcdManager = ManagerLike(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    /**
     * @dev Create a DSA v2
     */
    function createV2(address owner) internal returns (address newDsa) {
        newDsa = instaIndex.build(
            owner,
            2,
            address(0)
        );
    }
}