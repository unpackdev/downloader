// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC20.sol";
import "./INut.sol";
import "./Governable.sol";

contract Nut is ERC20, Governable, INut {
    using SafeMath for uint;

    address public distributor;
    address public sink;
    uint public constant MAX_TOKENS = 1000000 ether; // total amount of NUT tokens

    constructor (string memory name, string memory symbol, address sinkAddr, address governorAddr) ERC20(name, symbol) {
        __Governable__init(governorAddr);
        sink = sinkAddr;
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

    function mintSink(uint amount) external override {
        require(msg.sender == distributor, "must be called by distributor");
        require(amount.add(this.totalSupply()) <= MAX_TOKENS, "cannot mint more than MAX_TOKENS");
        _mint(sink, amount);
    }
}
