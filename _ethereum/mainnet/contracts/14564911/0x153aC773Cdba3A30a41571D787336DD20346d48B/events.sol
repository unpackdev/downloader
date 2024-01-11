//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./helpers.sol";

contract Events is Helpers {
    event supplyLog(
        uint256 amount_,
        address indexed caller_,
        address indexed to_
    );

    event withdrawLog(
        uint256 amount_,
        address indexed caller_,
        address indexed to_
    );

    event leverageLog(
        uint amt_
    );

    event deleverageLog(
        uint amt_
    );
}
