// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./console.sol";

contract Presale is Ownable, ReentrancyGuard {
    struct Info {
        uint allocation;
        bool registered;
    }
    uint public saleStartTime;
    uint public saleEndTime;
    uint public initialEthlPerEth = 28571429000000000000000; // 28571.428 --- 0.000035EthL                             
    uint public finalEthlPerEth = 6451613000000000000000; // 6451.612  --- 0.000149 EthL
    uint public totalRaised;
    uint public totalTokens;
    address public dev;
    address[] public investors;
    mapping(address => Info) public info;
    event BuyTokens(address indexed _owner, uint _ethAmount, uint _tokenAmount);
    event ShareTransferred (address indexed _admin, uint _adminShare, address indexed _dev, uint _devShare);

    constructor(address _ownerAddress, address _devAddress) Ownable(_ownerAddress) {
        dev = _devAddress;
    }
    
    modifier saleInProgress() {
        require(
            block.timestamp < saleEndTime,
            "Sale has ended"
        );
        _;
    }

    receive() external payable {}

    function startSale() external onlyOwner {
        require(saleStartTime == 0, "Sale has already started");
        saleStartTime = 1700895180;
        saleEndTime = saleStartTime + (42 days);
    }

    function buyTokens(uint _ethAmount) external payable nonReentrant saleInProgress {
        require(msg.value == _ethAmount, "Invalid Ether amount");

        Info storage info_ = info[msg.sender];

          if (!info_.registered) {
            info_.registered = true;
            investors.push(msg.sender);
        }
        uint ethlPerEth = calculateEthlPerEth();
        uint tokenAmount = (_ethAmount * ethlPerEth) / 1 ether;

        info_.allocation += tokenAmount;
        totalRaised += _ethAmount;
        totalTokens += tokenAmount;

        emit BuyTokens(msg.sender, _ethAmount, tokenAmount);
    }

    function calculateEthlPerEth() public view returns (uint) {
        uint daysElapsed = (block.timestamp - saleStartTime) / 1 days;
        uint ethlPerEth = initialEthlPerEth - (526660000000000000000 * daysElapsed);
        return ethlPerEth < finalEthlPerEth ? finalEthlPerEth : ethlPerEth;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        super.transferOwnership(newOwner);
    }
    
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getTotalInvestors() external view returns(uint) {
        return investors.length;
    }

    function transferShares() external nonReentrant onlyOwner {
        require(dev != address(0), "Admin or dev address not set");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to transfer");

        uint256 adminShare = (contractBalance * 95) / 100;
        uint256 devShare = contractBalance - adminShare;

        (bool successAdmin, ) = owner().call{value: adminShare}("");
        require(successAdmin, "Transfer to admin failed");

        (bool successDev, ) = dev.call{value: devShare}("");
        require(successDev, "Transfer to dev failed");
        emit ShareTransferred(owner(), adminShare, dev, devShare);
    }
    
    function getInvestors() external view returns (address[] memory) {
        return investors;
    }
}
