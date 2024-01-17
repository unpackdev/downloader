// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io

**************************************/

import "./IERC20.sol";
import "./IEquityBadge.sol";
import "./IVestedGovernor.sol";

/**************************************

    AppStorage library

    ------------------------------

    A specialized version of Diamond Storage is AppStorage.
    This pattern is used to more conveniently and easily share state variables between facets.

 **************************************/

library LibAppStorage {

    // structs: data containers
    struct AppStorage {
        IERC20 usdt;
        IEquityBadge equityBadge;
        IVestedGovernor vestedGovernor;
    }

    // diamond storage getter
    function appStorage() internal pure
    returns (AppStorage storage s) {

        // set slot 0 and return
        assembly {
            s.slot := 0
        }

        // explicit return
        return s;

    }

    /**************************************

        Get USDT

     **************************************/

    function getUSDT() internal view
    returns (IERC20) {

        // return
        return appStorage().usdt;

    }

    /**************************************

        Get badge

     **************************************/

    function getBadge() internal view
    returns (IEquityBadge) {

        // return
        return appStorage().equityBadge;

    }

    /**************************************

        Get vested governor

     **************************************/

    function getGovernor() internal view
    returns (IVestedGovernor) {

        // return
        return appStorage().vestedGovernor;

    }

    /**************************************

        Get timelock

     **************************************/

    function getTimelock() internal view
    returns (address) {

        // return
        return appStorage().vestedGovernor.timelock();

    }

}
