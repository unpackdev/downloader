// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./GenericRaffle.sol";

/* solhint-disable max-states-count */
contract KunAgueroRaffle is GenericRaffle {
    uint256 public constant MAX_SUPPLY = 9_320;

    function initialize(
        string memory baseURI,
        string memory _name,
        string memory _symbol,
        address payable _sandOwner,
        address _signAddress,
        address _sandContract
    ) public initializer {
        __GenericRaffle_init(baseURI, _name, _symbol, _sandOwner, _signAddress, MAX_SUPPLY);
        setAllowedExecuteMint(_sandContract);
    }
}
