// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./UUPSUpgradeable.sol";
import "./ERC1967Proxy.sol";

/**
 * @title TEARClaim
 * @custom:website www.descend.gg
 * @notice Claim contract proxy for $TEAR
 */
contract TEARClaimProxy is ERC1967Proxy {
    constructor(
        address _implementation,
        bytes memory _data
    ) ERC1967Proxy(_implementation, _data) {}

    receive() external payable virtual {}
}
