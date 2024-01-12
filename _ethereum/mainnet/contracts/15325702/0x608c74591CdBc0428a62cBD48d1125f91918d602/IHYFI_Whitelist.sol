// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.12;

interface IHYFI_Whitelist {
    function addMultipleToWhitelist(address[] memory _addresses) external;

    function addToWhitelist(address _address) external;

    function initialize() external;

    function isWhitelisted(address _address) external view returns (bool);

    function owner() external view returns (address);

    function removeFromWhitelist(address _address) external;

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}
