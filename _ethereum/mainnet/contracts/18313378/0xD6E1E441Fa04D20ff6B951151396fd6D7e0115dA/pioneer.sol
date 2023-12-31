// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./AccessProtectedUpgradable.sol";
import "./IUSDT.sol";

contract PioneerSale is PausableUpgradeable,ReentrancyGuardUpgradeable,AccessProtectedUpgradable {

    using SafeERC20Upgradeable for ERC20Upgradeable;

    IUSDT   public  USDT;
    bool    private initialized;
    uint256 public  totalDeposit;
    uint256 public  initialPrice;
    address public  collectionWallet;
    
    uint256 public totalDepositors;

    mapping(address => string) public depositTxids;
    // Mapping to store the amount of USDT each user has deposited
    mapping(address => uint256) public deposits;

    event Deposited(address indexed user, uint256 amount);

    function init(address usdtAddress_, address collectionWalletAddr) external initializer
    {
        require(!initialized);
        require(usdtAddress_ != address(0), "Invalid contract address");
        require(collectionWalletAddr != address(0), "Invalid wallet address");
        
        USDT = IUSDT(usdtAddress_);
        initialPrice = 1000;
        collectionWallet = collectionWalletAddr;
        __Ownable_init();
        __Pausable_init();
        initialized = true;
    }


    function deposit(uint256 usdtAmount_) external whenNotPaused {
        require(usdtAmount_ > 0, "Amount should be greater than 0");
        if(deposits[msg.sender] == 0) {
            totalDepositors += 1; // Increment the total depositors count if this is the first deposit for the user
        }

        deposits[msg.sender] += usdtAmount_;
        totalDeposit += usdtAmount_;
        ERC20Upgradeable(address(USDT)).safeTransferFrom(msg.sender, collectionWallet ,usdtAmount_);

        emit Deposited(msg.sender, usdtAmount_);
    }

    function checkDeposit() external view returns (uint256) {
        return deposits[msg.sender];
    }

    function setCollectionWallet(address wallet)external onlyOwner{
        require(wallet!= address(0), "Invalid address");
        collectionWallet = wallet;
    }

    function privateDeposit(address depositorAddr, uint256 amount_, string memory txid) external onlyOwner{
        require(depositorAddr!= address(0), "Invalid address");
        if(deposits[msg.sender] == 0) {
            totalDepositors += 1; // Increment the total depositors count if this is the first deposit for the user
        }
        deposits[depositorAddr] += amount_;
        totalDeposit += amount_;
        depositTxids[depositorAddr] = txid;  // Store the txid

        emit Deposited(depositorAddr, amount_);
    }

    function stopDeposits() external onlyOwner {
        _pause();
    }

    function startDeposits() external onlyOwner {
        _unpause();
    }

    function getPrice()public view returns(uint256){
        if (totalDeposit <= 150000000000){
            return initialPrice;
        }else{
            return totalDeposit * 10000 / 1500000000000;
        }

    }
}

