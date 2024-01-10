//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract PresaleETH is Ownable,ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private _vaultAddress = 0xc29A9Dd4Bf84dDA6C416Bf1E3B8f936768018A2F;
    address private _devAddress = 0x75f5B78015D79B2f96BD6f24F77EF22ec829D7D0;
    bool public saleLive;

    uint256 public hardcap = 357 ether; // set to 0 to disable
    uint256 public totalDepositAmount;
    uint256 public minAmountForPurchase = 0.01 ether;

    struct Deposit {
        address depositor;
        uint256 amount;
        address receiver;
    }
    mapping(uint256 => Deposit) public Deposits;
    uint256 public depositCount;

    constructor() {}

    function setHardcap(uint256 _hardcap) external onlyOwner {
        hardcap = _hardcap;
    }

    function setMinMaxAmount(uint256 _minAmountForPurchase) external onlyOwner {
        minAmountForPurchase = _minAmountForPurchase;
    }

    function buyFromPresale(address receivingTokenWallet_) external payable nonReentrant{
        require(saleLive, "SALE_NOT_STARTED");
        require(msg.value > minAmountForPurchase, "BELOW_MIN_AMOUNT");
        totalDepositAmount += msg.value;
        require(hardcap == 0 || totalDepositAmount < hardcap,"HARDCAP_EXCEEDED");
        Deposits[depositCount++] = 
            Deposit({
                depositor: _msgSender(), 
                amount: msg.value, 
                receiver: receivingTokenWallet_
            });
    }

    function withdrawFund() public {
        require(_msgSender() == owner() || _msgSender() == _vaultAddress, "NOT_ALLOWED");
        require(_vaultAddress != address(0), "TREASURY_NOT_SET");
        (bool sent, ) = _devAddress.call{value: address(this).balance * 10 / 100}("");
        require(sent, "FAILED_SENDING_FUNDS");
        (sent, ) = _vaultAddress.call{value: address(this).balance}("");
        require(sent, "FAILED_SENDING_FUNDS");
    }

    function withdraw(address _token) external nonReentrant {
        require(_msgSender() == owner() || _msgSender() == _vaultAddress, "NOT_ALLOWED");
        require(_vaultAddress != address(0), "TREASURY_NOT_SET");
        IERC20(_token).safeTransfer(
            _vaultAddress,
            IERC20(_token).balanceOf(address(this))
        );
    }

    //*****************
    //*    SETTERS    *
    //*****************

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setVaultAddress(address addr) external onlyOwner {
        _vaultAddress = addr;
    }

    function setDevAddress(address addr) external onlyOwner {
        _devAddress = addr;
    } 

    function setMinAmountForPurchase(uint256 _amount) external onlyOwner{
        require(_amount > 0, "amount must be greater than 0");
        minAmountForPurchase = _amount;
    }

    function setHardCap(uint256 _hardcap) external onlyOwner{  
        hardcap = _hardcap;
    }
}