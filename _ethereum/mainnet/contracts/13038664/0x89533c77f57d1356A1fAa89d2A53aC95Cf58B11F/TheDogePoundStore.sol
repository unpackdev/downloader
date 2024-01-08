// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title TheDogePoundStore
 * TheDogePoundStore - a payment contract
 */
contract TheDogePoundStore is Ownable {
    using SafeMath for uint256;
    uint256 public profit;
    uint256 public profitShare;
    address public wallet;
    ERC20 public usdc;

    constructor(ERC20 _usdc, address _wallet, uint256 _profitShare) {
        usdc = _usdc;
        profit = 0;
        profitShare = _profitShare;
        wallet = _wallet;
    }

    function checkout(uint256 _total, uint256 _profit) public payable {
        require(usdc.transferFrom(msg.sender, address(this), _total), 'Please send correct USDC amount');
        profit = profit.add(_profit);
    }

    function withdraw() external onlyOwner {
        uint256 share = profit.mul(profitShare).div(100);
        uint256 balance = usdc.balanceOf(address(this)).sub(share);
        usdc.transfer(owner(), balance);
        usdc.transfer(wallet, share);
        profit = 0;
    }
}
