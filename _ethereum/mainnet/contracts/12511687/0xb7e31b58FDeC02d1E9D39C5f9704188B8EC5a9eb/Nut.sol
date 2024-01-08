// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC20.sol";
import "./INut.sol";
import "./Governable.sol";

contract Nut is ERC20, Governable, INut {
    using SafeMath for uint;

    address public distributor;

    uint public constant MAX_TOKENS = 1000000 ether; // total amount of NUT tokens
    uint public constant SINK_FUND = 200000 ether; // 20% of tokens goes to sink fund

    constructor (string memory name, string memory symbol, address sinkAddr, address governorAddr) ERC20(name, symbol) {
        _mint(sinkAddr, SINK_FUND);
        __Governable__init(governorAddr);
    }

    /// @dev Set the new distributor
    function setNutDistributor(address addr) external onlyGov {
        distributor = addr;
    }

    /// @dev Mint nut tokens to receipt
    function mint(address receipt, uint256 amount) external override {
        require(msg.sender == distributor, "must be called by distributor");
        require(amount.add(this.totalSupply()) <= MAX_TOKENS, "cannot mint more than MAX_TOKENS");
        _mint(receipt, amount);
    }

}
