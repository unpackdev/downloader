pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract Payments is PaymentSplitter {
    uint256[] private _teamShares = [595, 405];
    address[] private _team = [0x3A9Bb8cC601347644b8B73CD2E8B086e970F5ac9, 0xe5092830a697352197bc7D17854F7C90a7828F02];

    constructor () PaymentSplitter(_team, _teamShares) payable {
    }
}