pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./AllowanceCrowdsale.sol";

contract TokenSale is AllowanceCrowdsale {
    constructor (uint256 rate, address payable wallet, IERC20 token, address tokenWallet)
        public
        Crowdsale(rate, wallet, token)
        AllowanceCrowdsale(tokenWallet)
    {
    }
}