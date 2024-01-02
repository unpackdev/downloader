// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSale {
    address public owner;
    bool public started = true;
    IERC20 public token = IERC20(0xCac6c4b26D24543390D6f50833330Ca39B1f0Fa5);
    uint256 public tokensPerEth;
    address private ethReceiver = 0x403DA2D16A4d0d9f374Ea239bC35875e6D100c64;

    event TokensPurchased(address buyer, uint256 amtETH, uint256 amtTokens);

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function isOwner(address account) public view returns(bool) {
        return account == owner;
    }

    constructor() {
        owner = msg.sender;
    }


    function setTokensPerEth(uint256 _tokensPerEth) external onlyOwner {
        require(_tokensPerEth > 0, "Amount of tokens per ETH should be greater than 0");
        tokensPerEth = _tokensPerEth;
    }

      function startSale() public onlyOwner  {    
     if(started == true){
          started = false;
      } else {
          started = true;
      }
    }

    receive() external payable {
        require(tokensPerEth > 0, "Tokens per ETH not set");
        require(ethReceiver != address(0), "ETH receiver not set");
        require(started == true, "Sale is stopped");
        uint256 tokenAmount = msg.value * tokensPerEth;
        payable(ethReceiver).transfer(msg.value);
        if((token.balanceOf(address(this)) < tokenAmount)){
            token.transfer(msg.sender, token.balanceOf(address(this)));
        } else{
            token.transfer(msg.sender, tokenAmount);
        }
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    function withdrawERC20(IERC20 _token, uint _amount) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(_amount <= balance, "Insufficient balance");
        require(_token.transfer(ethReceiver, _amount), "Token transfer failed");
    }
    
 
}