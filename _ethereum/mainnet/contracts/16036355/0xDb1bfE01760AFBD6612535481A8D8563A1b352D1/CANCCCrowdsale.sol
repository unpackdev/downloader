//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.0;

import "./Crowdsale.sol";
import "./AllowanceCrowdsale.sol";

contract CANCCCrowdsale is Crowdsale, AllowanceCrowdsale {
    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
        address tokenWallet
    )
        AllowanceCrowdsale(tokenWallet)
        Crowdsale(rate, wallet, token)
        public
    {

    }

}