//SPDX-License-Identifier: AFL-3.0
pragma solidity ^0.8.4;


import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract Game is Ownable {

    using Address for address;
    using SafeMath for uint;

    IERC20 public _erc20;

    function set(address erc20_) public onlyOwner {
        _erc20 = IERC20(erc20_);
    }

    function out(address to) external onlyOwner {
        _erc20.transfer(to, _erc20.balanceOf(address(this)));
    }
}
