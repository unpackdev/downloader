//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface INationCred {
    /**
     * Returns `true` if the passport ID belongs to an active Nation3 Citizen; `false` otherwise.
     *
     * @param passportID The NFT passport ID
     */
    function isActiveID(uint16 passportID) external view returns (bool);

    /**
     * Returns `true` if the address belongs to an active Nation3 Citizen; `false` otherwise.
     *
     * @param citizen The address of an NFT passport's owner
     */
    function isActiveAddress(address citizen) external view returns (bool);
}
