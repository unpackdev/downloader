// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

import "./IBitbull.sol";



contract DechatIDOE is Ownable{ 
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint constant baseProportion = 10000000;

    uint public totalEth;
    uint public totalUsdt;
    mapping(address => uint) public balanceEth;
    mapping(address => uint) public balanceUsdt;
    mapping(address => uint) public ref;
    EnumerableSet.AddressSet accounts;
    
    Info public info;

    struct Info{
        uint startTime;
        uint endTime;
        uint minUsdt;
        uint minEth;
        uint priceEth;
        uint priceUsdt;
        uint targetEth;
        uint targetUsdt;
        IBitbull bitbull;
        IERC20 input;
    }

    event InvestUSDT(address indexed account, uint amount, uint ref);
    event InvestETH(address indexed account, uint amount, uint ref);

    constructor(Info memory info_) {
        info = info_;
        info.input.safeApprove(address(info.bitbull), type(uint).max);
    }

    function updateInfo(Info memory info_) external onlyOwner {
        info = info_;
    }

    function invest(
        string memory _ref,
        string memory _slug,
        address _paymentToken,
        uint256 _paymentAmount
    ) external payable {
        require(block.timestamp >= info.startTime && block.timestamp <= info.endTime, 'can not invest now');
        if (_paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            require(msg.value >= info.minEth, 'amount too low');
            require(totalEth < info.targetEth, 'STOPPED');
            info.bitbull.buy{value : msg.value}(_ref, _slug, _paymentToken, _paymentAmount);
            balanceEth[msg.sender] += msg.value;
            totalEth += msg.value;
            emit InvestETH(msg.sender, msg.value, bytes(_ref).length);
        } else {
            require(_paymentAmount >= info.minUsdt, 'amount too low');
            require(totalUsdt < info.targetUsdt, 'STOPPED');
            info.input.safeTransferFrom(msg.sender, address(this), _paymentAmount);
            info.bitbull.buy(_ref, _slug, _paymentToken, _paymentAmount);
            balanceUsdt[msg.sender] += _paymentAmount;
            totalUsdt += _paymentAmount;
            emit InvestUSDT(msg.sender, _paymentAmount, bytes(_ref).length);
        }
        
        ref[msg.sender] += bytes(_ref).length;
        accounts.add(msg.sender);
        
    }

    struct OutputParam {
        address account;
        uint amount;
        uint ref;
    }

    function outputData(uint start, uint end) external view onlyOwner returns(OutputParam[] memory){
        uint length = accounts.length();
        address account;
        if (end > length) {
            end = length;
        }
        require(start < end, 'param error: start or end');
        OutputParam[] memory out = new OutputParam[](end - start);
        for (uint i = start; i < end; i++) {
            account = accounts.at(i);
            out[i - start] = OutputParam(account, ((balanceEth[account] * info.priceEth + balanceUsdt[account] * 1e12 * info.priceUsdt) / baseProportion), ref[account]);
        }
        return out;
    }

    function withdraw(address addr) external onlyOwner(){
        SafeERC20.safeTransfer(IERC20(addr), msg.sender, IERC20(addr).balanceOf(address(this)));
    }

}