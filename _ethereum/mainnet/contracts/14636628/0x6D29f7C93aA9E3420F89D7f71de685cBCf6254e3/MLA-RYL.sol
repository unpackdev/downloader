pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract MoonlightLoveAffairSplitter is Ownable, PaymentSplitter {

    constructor (address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable {}
}
