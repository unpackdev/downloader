// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "./Warded.sol";
import "./Living.sol";
import "./Initializable.sol";

abstract contract WardedLivingUpgradeable is Warded, Living, Initializable {

    function __WardedLiving_init() internal onlyInitializing {
        relyOnSender();
        run();
    }
}
