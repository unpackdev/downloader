// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.21;

import "./IERC20.sol";

interface IVerseToken is IERC20 {

    function burn(
        uint256 _value
    )
        external;
}
