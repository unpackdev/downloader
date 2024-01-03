// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract BirdPool is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public BIRDToken;

    constructor(IERC20 _BIRDToken) Ownable() {
        BIRDToken = _BIRDToken;
    }

    function allowTransferToStaking(address _stakingAddress, uint256 _amount) public onlyOwner() {
        require(_stakingAddress!=address(0),"Invalid address");
        require(_amount>0,"Invalid Amount");
        BIRDToken.approve(_stakingAddress, _amount);
    }
}