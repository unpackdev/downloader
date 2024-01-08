// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";


contract Crowdsale is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public token;

    address public usdt;
    address public usdc;
    
    mapping (address => uint256) public vestedAmount;
    mapping (address => uint256) public tokensClaimed;
    
    uint256 public totalVested;
    
    uint public tokenPrice = 18518518518519; // in usd 0.018518518518519
    uint256 private tokenDecimals = 18;
    
    uint256 public startDate;
    
    uint256 public lockupPeriod = 360 days; // 12 months

    constructor (uint256 _startDate, address _token, address _usdt, address _usdc) /*public*/ {
        startDate = _startDate;
        token = IERC20(_token);
        usdt = _usdt;
        usdc = _usdc;
    }
    
    function buyTokens(uint amount, address _paymentToken) public {
        require(_paymentToken == usdt || _paymentToken == usdc, "Unsuportted token");
        require(block.timestamp < startDate + lockupPeriod, "Presale is over");

        uint usd_amount = amount / (uint(10) ** (IERC20Metadata(_paymentToken).decimals()));
        require(usd_amount >= 20000, "Wrong payment amount");

        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), amount);

        uint256 vested = (usd_amount * 1000000000000000 / tokenPrice) * (uint(10) ** (IERC20Metadata(address(token)).decimals())); // First, you have to multiply, then divide
        vestedAmount[msg.sender] += vested;
        
        require(vested <= token.balanceOf(address(this)) - totalVested, "Not enough tokens in contract");
        totalVested += vested;
    }
    
    function claim() public {
        require(block.timestamp >= startDate + lockupPeriod, 'Lockup period did not pass since the creation of the contract');

        uint256 tokensToSend = availableToClaim(msg.sender);
        require(tokensToSend > 0, 'Nothing to claim');

        tokensClaimed[msg.sender] += tokensToSend;

        token.safeTransfer(msg.sender, tokensToSend);
    }

    function availableToClaim(address _address) public view returns(uint256) {
        return unlockedTokens(_address) - tokensClaimed[_address];
    }
    
    function unlockedTokens(address _address) public view returns(uint256) {
        if(block.timestamp < (startDate + lockupPeriod)) {
            return 0;
        }

        return vestedAmount[_address];
    }
    
    function claimTokens(address _token) public onlyOwner {
        if(_token == address(token)) {
            IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)) - totalVested);
        }
        IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}