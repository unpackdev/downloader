// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract Airdrop is Ownable, AccessControl {
  bytes32 public constant ROLE_CONTRACTOR = keccak256("ROLE_CONTRACTOR");
  
  struct ERC20TokenType {
    address tokenAddress;
    uint256 minPrice;
  }

  uint256 private ethMinPrice = 0 ether;
  
  ERC20TokenType[] private tokenTypes;
  mapping(address => uint256) private airdropQty;

  bool public contractPaused = false;

  function circuitBreaker() public onlyOwner {
    if (contractPaused == false) { 
      contractPaused = true; 
    }
    else { 
      contractPaused = false; 
    }
  }

  modifier checkIfPaused() {
    require(contractPaused == false);
    _;
  }
  
  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function addERC20TokenType(address _tokenAddress, uint256 _minPrice) external onlyRole(ROLE_CONTRACTOR) {
    bool isExist = false;
    if (tokenTypes.length > 0) {
      for (uint i = 0; i < tokenTypes.length; i++) {
        if (tokenTypes[i].tokenAddress == _tokenAddress) {
          tokenTypes[i].minPrice = _minPrice;
          isExist = true;
        }
      }
    }
    if (!isExist) {
      ERC20TokenType memory tokenType = ERC20TokenType(_tokenAddress, _minPrice);   
      tokenTypes.push(tokenType);
    }
  }

  function removeERC20TokenType(address _tokenAddress) external onlyRole(ROLE_CONTRACTOR) {
    require(tokenTypes.length > 0, "Supported token undefined");

    for (uint i = 0; i < tokenTypes.length; i++) {
      if (tokenTypes[i].tokenAddress == _tokenAddress) {
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance == 0, "Token has balance. Please withdraw.");

        tokenTypes[i] = tokenTypes[tokenTypes.length - 1];
        tokenTypes.pop();
      }
    }
  }

  function listERC20TokenTypes() external onlyOwner view returns (ERC20TokenType[] memory) {
    return tokenTypes;
  }

  function setEthPrice(uint256 _amount) external onlyOwner {
    ethMinPrice = _amount;
  }

  function buyAirdrop(IERC20 _token, uint256 _amount) external checkIfPaused returns (uint256) {
    require(tokenTypes.length > 0, "Supported token undefined");

    bool isExist = false;
    address _tokenAddress = address(_token);
    for (uint i = 0; i < tokenTypes.length; i++) {
      if (tokenTypes[i].tokenAddress == _tokenAddress) {
        require(_amount >= tokenTypes[i].minPrice, "Insufficient payment");

        uint256 allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance");

        isExist = true;
      }
    }
    require(isExist, "Token not recognized");

    _token.transferFrom(msg.sender, address(this), _amount);
    // _token.transferFrom(msg.sender, owner(), _amount);
    airdropQty[msg.sender]++;
    return airdropQty[msg.sender];
  }

  function buyAirdropWithEth() external checkIfPaused payable returns (uint256) {
    require(msg.value >= ethMinPrice, "Insufficient payment");

    airdropQty[msg.sender]++;
    return airdropQty[msg.sender];
  }

  function redeemAirdrop() external checkIfPaused returns (uint256) {
    require(airdropQty[msg.sender] > 0, "Insufficient balance");

    airdropQty[msg.sender]--;
    return airdropQty[msg.sender];
  }

  function redeemAirdropCustomQty(uint256 _qty) external checkIfPaused returns (uint256) {
    require(airdropQty[msg.sender] >= _qty, "Insufficient balance");

    airdropQty[msg.sender] -= _qty;
    return airdropQty[msg.sender];
  }
  
  function airdropQtyOf(address _account) external view returns (uint256) {
    return airdropQty[_account];
  }
  
  function getMyAirdropQty() external view returns (uint256) {
    return airdropQty[msg.sender];
  }
    
  function withdraw(address _tokenAddress) external onlyOwner {
    for (uint i = 0; i < tokenTypes.length; i++) {
      
      if (tokenTypes[i].tokenAddress == _tokenAddress) {
        IERC20 token = IERC20(tokenTypes[i].tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));

        require(tokenBalance > 0, "Insufficient balance");
        token.transfer(address(this), tokenBalance);
      }
    }
  }
    
  function withdrawEth() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function getBalance(address _tokenAddress) external onlyOwner view returns (uint256) {
    IERC20 token = IERC20(_tokenAddress);
    return token.balanceOf(address(this));
  }

  function getEthBalance() external onlyOwner view returns (uint256) {
    return address(this).balance;
  }
}
