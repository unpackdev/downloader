// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeListErc721Holder.sol";

/**
 * @dev AvantArteDraw is of type SafeListErc721Holder
 */
contract AvantArteDraw is SafeListErc721Holder {
    constructor(Props memory props)
        SafeListErc721Holder(props)
    // solhint-disable-next-line no-empty-blocks
    {

    }
}
