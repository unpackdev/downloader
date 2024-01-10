// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract Presale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposited(address indexed user, uint256 amount);
    event PresaleEnabledUpdated(bool enabled);

    IERC20 public satm;
    
    mapping(address => uint256) public deposits;

    address[] public investors;

    address public masterWallet;

    uint256 public totalDepositedEthBalance;

    uint256 public depositRate = 3100; // Token price. i.e. 1 SATM = 3100e-7 ETH

    bool public presaleEnabled = false;

    constructor(
        IERC20 _satm,
        address _masterWallet
    ) {
        require(address(_satm) != address(0), "SATM address should not be zero address");
        require(_masterWallet != address(0), "Master wallet address should not be zero address");
        
        satm = _satm;
        masterWallet = _masterWallet;
   }

    function depositedUserCount() public view returns (uint256) {
        return investors.length;
    }
    
    function updatePresaleRate(uint256 rate) public onlyOwner {
        require(rate > 0, "UpdateSwapRate: Rate is less than Zero");
        depositRate = rate;
    }

    function setPresaleEnabled(bool _enabled) public onlyOwner {
        presaleEnabled = _enabled;
        emit PresaleEnabledUpdated(_enabled);
    }

    function deposit() public payable nonReentrant {
        // Get the ether amount that investor sent to this function
        uint256 ethAmount = msg.value;

        require(ethAmount > 0, "Ether Amount is less than zero");
        require(presaleEnabled == true, "Presale is not available");

        uint256 satmTokenAmount = ethAmount.mul(10 ** 7).div(depositRate);

        // Send Ether to the master wallet
        (bool success, ) = payable(masterWallet).call{value: ethAmount}("");
        require(success, "Failed to send Ether");
        // Send SATM to the investor
        satm.safeTransferFrom(masterWallet, msg.sender, satmTokenAmount);

        totalDepositedEthBalance = totalDepositedEthBalance + ethAmount;

        // Record the deposit amount for each investor
        if (deposits[msg.sender] == 0) {
            investors.push(msg.sender);
        }
        deposits[msg.sender] = deposits[msg.sender] + ethAmount;
        
        emit Deposited(msg.sender, ethAmount);
    }

    function updateSatmToken(IERC20 _satm) public onlyOwner {
        require(address(_satm) != address(0), "SATM token address should not be zero address");
        satm = _satm;
    }

    function updateMasterWalletAddress(address _newWalletAddress) public onlyOwner {
        require(address(_newWalletAddress) != address(0), "Master Wallet address should not be zero address");
        masterWallet = _newWalletAddress;
    }
}