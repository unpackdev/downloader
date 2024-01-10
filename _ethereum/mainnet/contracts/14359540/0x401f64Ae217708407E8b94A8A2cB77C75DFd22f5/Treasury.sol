//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Initializable.sol";
import "./Ownable.sol";

/**
 * @title dForce's lending Treasury Contract
 * @author dForce
 */
contract Treasury is Initializable, Ownable {

    constructor() public {
        initialize();
    }

    function initialize() public initializer {
        __Ownable_init();
    }
}
