// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.7.0;


/**
* @title PollenDAO Pre-release Whitelist
* @notice A whitelist of users to prevent this release from being used on DEXs etc
* @author Quantafire (James Key)
*/
interface IWhitelist {

    /**
    * @notice Check if the address is whitelisted
    * @param account Addresses to check
    * @return Bool of whether _addr is whitelisted or not
    */
    function isWhitelisted(address account) external view returns (bool);

    /**
    * @notice Turn whitelisting on/off and add/remove whitelisted addresses.
    * Only the owner of the contract may call.
    * By default, whitelisting is disabled.
    * To enable whitelisting, add zero address to whitelisted addresses:
    * `updateWhitelist([address(0)], [true])`
    * @param accounts Addresses to add or remove
    * @param whitelisted `true` - to add, `false` - to remove addresses
    */
    function updateWhitelist(address[] calldata accounts, bool whitelisted) external;

    event Whitelist(address addr, bool whitelisted);
}
