// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract DepositContract {
    address public owner;
    address public usdtToken;
    address public nominatedWallet;
    uint256 public fee; 
    event DepositFunds(address indexed user, uint256 amount, string id);
    event Debug(string message);  
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address _usdtToken, address _nominatedWallet, uint256 _fee) {
        owner = msg.sender;
        usdtToken = _usdtToken;
        nominatedWallet = _nominatedWallet;
        fee = _fee;
    }

  function depositFunds(uint256 amount, string memory id) external {
    emit Debug("Start deposit");
    
    require(amount > 0, "Amount must be greater than 0");
    emit Debug("Amount is greater than 0");

    require(IERC20(usdtToken).balanceOf(msg.sender) >= amount, "Insufficient USDT balance");
    emit Debug("User has sufficient USDT balance");

    require(IERC20(usdtToken).allowance(msg.sender, address(this)) >= amount, "Not enough USDT allowance");
    emit Debug("User has provided sufficient USDT allowance");

    uint256 feeAmount = amount * fee / 100;
    uint256 depositAmount = amount - feeAmount;

    emit Debug("Before fee transfer");
    require(IERC20(usdtToken).transferFrom(msg.sender, nominatedWallet, feeAmount), "Fee transfer failed");
    emit Debug("After fee transfer, before deposit transfer");
    
    require(IERC20(usdtToken).transferFrom(msg.sender, address(this), depositAmount), "Deposit transfer failed");
    emit Debug("After deposit transfer");

    emit DepositFunds(msg.sender, depositAmount, id);
}

    function withdrawFunds(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(usdtToken).transfer(to, amount), "Withdrawal transfer failed");
    }

    function changeFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    function transferTokensTo(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");


        uint8 decimals = IERC20(usdtToken).decimals();

        uint256 amountInSmallestUnit = amount * (10 ** decimals);

        uint256 contractBalance = IERC20(usdtToken).balanceOf(address(this));
        require(contractBalance >= amountInSmallestUnit, "Insufficient token balance");
        require(IERC20(usdtToken).transfer(recipient, amountInSmallestUnit), "Token transfer failed");
    }
       function withdrawEther(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No Ether to withdraw");
        recipient.transfer(contractBalance);
    }
}