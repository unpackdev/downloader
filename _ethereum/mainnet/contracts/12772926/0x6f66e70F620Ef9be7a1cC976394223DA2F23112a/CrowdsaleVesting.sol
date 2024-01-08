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
    
    uint public tokenPrice = 25; // in usd 0.25
    uint256 private tokenDecimals = 18;
    
    uint256 public startDate;
    
    uint256 public oneMonth = 30 days;
    uint256 public lockupPeriod = 360 days;

    uint256 public vestingPeriod = 12; // in months

    constructor (uint256 _startDate, address _token, address _usdt, address _usdc) /*public*/ {
        require(block.timestamp < _startDate, "startDate must be in the future");
        startDate = _startDate;
        token = IERC20(_token);
        usdt = _usdt;
        usdc = _usdc;
    }
    
    function buyTokens(uint amount, address _paymentToken) public {
        require(_paymentToken == usdt || _paymentToken == usdc, "Unsuportted token");
        require(block.timestamp < startDate + lockupPeriod, "Presale is over");

        uint usd_amount = amount / (uint(10) ** (IERC20Metadata(_paymentToken).decimals()));
        require(usd_amount >= 2000, "Wrong payment amount");

        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), amount);

        uint256 vested = (usd_amount * 100 / tokenPrice) * (uint(10) ** (IERC20Metadata(address(token)).decimals())); // First, you have to multiply, then divide
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
        
        uint256 monthsPassed = ((block.timestamp - (startDate + lockupPeriod)) / oneMonth) + 1;
        monthsPassed = monthsPassed > vestingPeriod ? vestingPeriod : monthsPassed;
        
        return vestedAmount[_address] * monthsPassed / vestingPeriod;
    }
    
    function claimTokens(address _token) public onlyOwner {
        if(_token == address(token)) {
            IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)) - totalVested);
        }
        IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}