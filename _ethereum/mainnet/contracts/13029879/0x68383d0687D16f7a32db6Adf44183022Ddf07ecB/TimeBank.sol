// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
import "./Crowdsale.sol";

contract TimeBank is Crowdsale {

    address timeGuardian;
    constructor(
        uint256 rate,    // the hour rate
        address payable wallet,
        IERC20 token
    )
        Crowdsale(rate, wallet, token)
        public
    {
    }

}