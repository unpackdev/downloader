// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Required interface of an IAddressController compliant contract.
 */
interface IAddressController {
    /**
     * @dev Emitted when address is whitelisted by controller
     */
    event AddressVerified(address indexed _who, address indexed _address);
    /**
     * @dev Emitted when address is delisted by controller
     */
    event AddressDelisted(address indexed _who, address indexed _address);

     /**
     * @dev Returns if the address is verified by controller
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isVerified(address _address) external view returns (bool);

    function setVerifiedAddress(address _userAddress, bool _verified) external;

}
