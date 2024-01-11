// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20Checkouter.sol";
import "./ETHCheckouter.sol";

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Address.sol";

contract ETHAndERC20CheckoutCounter is Ownable, ERC20Checkouter, ETHCheckouter {
    using Address for address;
    using SafeMath for uint256;

    constructor() {
    }
}