// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IWhiteBlackList {
    enum AccessType {
        UNLISTED,
        WHITELISTED,
        BLACKLISTED
    }
    event WhitelistedAddressAdded(address indexed addr);
    event WhitelistedAddressRemoved(address indexed addr);
    event BlacklistedAddressAdded(address indexed addr);
    event BlacklistedAddressRemoved(address indexed addr);

    function addAddressToWhitelist(address _address) external;

    function addAddressesToWhitelist(address[] calldata _addresses) external;

    function removeAddressFromWhitelist(address _address) external;

    function removeAddressesFromWhitelist(address[] calldata _addresses) external;

    function addAddressToBlacklist(address _address) external;

    function addAddressesToBlacklist(address[] calldata _addresses) external;

    function removeAddressFromBlacklist(address _address) external;

    function removeAddressesFromBlacklist(address[] calldata _addresses) external;

    function getAccessType(address _address) external view returns (AccessType);

    function isBlackListed(address _address) external view returns (bool);

    function registry() external view returns (address);
}
