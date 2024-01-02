// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface INonTransparentProxy {

    /**
     *  @dev   Sets the implementation address.
     *  @param newImplementation_ The address to set the implementation to.
     */
    function setImplementation(address newImplementation_) external;

}
