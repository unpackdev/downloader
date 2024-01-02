/** 
   (                  )     (               (     
   )\     (   (    ( /( (   )\ )  (     (   )\ )  
 (((_)   ))\  )(   )\()))\ (()/(  )\   ))\ (()/(  
 )\___  /((_)(()\ (_))/((_) /(_))((_) /((_) ((_)) 
((/ __|(_))   ((_)| |_  (_)(_) _| (_)(_))   _| |  
 | (__ / -_) | '_||  _| | | |  _| | |/ -_)/ _` |  
  \___|\___| |_|   \__| |_| |_|   |_|\___|\__,_|

Web: https://certifiedprotocol.net/

TG: https://t.me/Certified_Portal

Twitter (X): https://twitter.com/certified__eth

**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CertifiedPayments {
    IERC20 private _CFDContract;
    address private _owner;

    struct PaymentStruct {
        address certifier;
        uint256 timestamp;
        uint256 amount;
        uint256 certifierFees;
    }

    struct HoldStruct {
        uint256 threshold;
        uint8 fee;
    }

    mapping (address => mapping (address => mapping (uint256 => PaymentStruct))) public pendingPayments;    
    mapping (address => mapping (address => uint16)) public paymentsCounter; 
    HoldStruct public holdCFDTier1 = HoldStruct({threshold: 0, fee: 1});
    HoldStruct public holdCFDTier2 = HoldStruct({threshold: 100 * 10**3 * 10**9, fee: 5});
    uint32 public releaseTime = 604800;

    event Payment(address indexed from, address indexed to, address indexed certifier, uint16 paymentIndex, uint256 amount, string message);
    event Certify(address indexed from, address indexed to, address indexed certifier, uint16 paymentIndex, bool result);

    constructor() {
        _owner = msg.sender;
        _CFDContract = IERC20(address(0));
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function sendPayment(address to, address certifier, uint256 certifierFees, string calldata message) external payable {
        require(msg.value > 0, "No ETH sent");
        uint256 value = msg.value;

        if(msg.sender != _owner && _CFDContract != IERC20(address(0))){
            require(_CFDContract.balanceOf(msg.sender) >= holdCFDTier1.threshold, "Insufficient CFD balance");
            
            if(_CFDContract.balanceOf(msg.sender) < holdCFDTier2.threshold){
                value = value - (value * holdCFDTier1.fee / 1000);
            }
            else{
                value = value - (value * holdCFDTier2.fee / 10000);
            }
        }

        pendingPayments[msg.sender][to][paymentsCounter[msg.sender][to]].amount = value;
        pendingPayments[msg.sender][to][paymentsCounter[msg.sender][to]].certifier = certifier;
        pendingPayments[msg.sender][to][paymentsCounter[msg.sender][to]].certifierFees = certifierFees;
        pendingPayments[msg.sender][to][paymentsCounter[msg.sender][to]].timestamp = block.timestamp;
        
        emit Payment(msg.sender, to, certifier, paymentsCounter[msg.sender][to], value, message);

        paymentsCounter[msg.sender][to]++;
    }

    function certify(address payable from, address payable to, uint16 paymentIndex, bool result) external {
        require(pendingPayments[from][to][paymentIndex].certifier == msg.sender, "Certifier address not valid for this payment");
        require(pendingPayments[from][to][paymentIndex].amount > 0, "Payment already processed");

        uint256 certifierAmount = pendingPayments[from][to][paymentIndex].amount * pendingPayments[from][to][paymentIndex].certifierFees / 100;
        uint256 amount = pendingPayments[from][to][paymentIndex].amount - certifierAmount;

        if(result){
            to.transfer(amount);
        }
        else{
            from.transfer(amount);
        }
        payable(pendingPayments[from][to][paymentIndex].certifier).transfer(certifierAmount);

        pendingPayments[from][to][paymentIndex].amount = 0;
        
        emit Certify(from, to, pendingPayments[from][to][paymentIndex].certifier, paymentIndex, result);
    }

    function checkReleaseTime(address to, uint64 paymentIndex) external view returns (uint256) {
        if(block.timestamp - pendingPayments[msg.sender][to][paymentIndex].timestamp < releaseTime){
            return releaseTime - (block.timestamp - pendingPayments[msg.sender][to][paymentIndex].timestamp);
        }
        return 0;
    }

    function releaseFunds(address to, uint64 paymentIndex) external {
        require(block.timestamp - pendingPayments[msg.sender][to][paymentIndex].timestamp >= releaseTime, "Release time still in progress...");
        pendingPayments[msg.sender][to][paymentIndex].amount = 0;
        payable(msg.sender).transfer(pendingPayments[msg.sender][to][paymentIndex].amount);
    }

    function setCFDAddress(address addr) external onlyOwner {
        _CFDContract = IERC20(addr);
    }

    function setCFDHoldLayer1(uint256 threshold, uint8 fee) external onlyOwner {
        holdCFDTier1.threshold = threshold;
        holdCFDTier1.fee = fee;
    }

    function setCFDHoldLayer2(uint256 threshold, uint8 fee) external onlyOwner {
        holdCFDTier2.threshold = threshold;
        holdCFDTier2.fee = fee;
    }

    function withdraw() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function setReleaseTime(uint32 timeInSec) external onlyOwner {
        releaseTime = timeInSec;
    }
}