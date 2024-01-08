// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";


contract aKeeperPresale is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public aKEEPER;
    address public USDC;
    address public USDT;
    address public DAI;
    address public gnosisSafe;
    mapping( address => uint ) public amountInfo;
    mapping( address => uint ) public airdropInfo;
    uint deadline;
    
    event aKeeperRedeemed(address tokenOwner, uint amount);

    constructor(address _aKEEPER, address _USDC, address _USDT, address _DAI, address _gnosisSafe, uint _deadline) {
        require( _aKEEPER != address(0) );
        require( _USDC != address(0) );
        require( _USDT != address(0) );
        require( _DAI != address(0) );
        aKEEPER = IERC20(_aKEEPER);
        USDC = _USDC;
        USDT = _USDT;
        DAI = _DAI;
        gnosisSafe = _gnosisSafe;
        deadline = _deadline;
    }

    function setRecipients(address[] calldata _recipients, uint[] calldata _amounts) external onlyOwner() {
        for (uint i=0; i < _recipients.length; i++) {
            amountInfo[_recipients[i]] = _amounts[i];
        }
    }

    function setDeadline(uint _deadline) external onlyOwner() {
        deadline = _deadline;
    }

    function getTokens(address principle, uint amount) external {
        require(block.timestamp < deadline, "Deadline has passed.");
        require(principle == USDC || principle == USDT || principle == DAI, "Token is not acceptable.");
        require(IERC20(principle).balanceOf(msg.sender) >= amount, "Not enough token amount.");
        // Get aKeeper amount. aKeeper is 9 decimals and 1 aKeeper = $10
        uint aKeeperAmount;
        if (principle == DAI) {
            aKeeperAmount = amount.div(1e10);
        }
        else {
            aKeeperAmount = amount.mul(1e2);
        }
        require(amountInfo[msg.sender] >= aKeeperAmount, "Cannot get more than allocation.");

        IERC20(principle).safeTransferFrom(msg.sender, gnosisSafe, amount);
        aKEEPER.transfer(msg.sender, aKeeperAmount);
        amountInfo[msg.sender] = amountInfo[msg.sender].sub(aKeeperAmount);
        emit aKeeperRedeemed(msg.sender, aKeeperAmount);
    }

    function airdropTokens(address[] calldata _recipients, uint[] calldata _amounts) external onlyOwner() {
        for (uint i=0; i < _recipients.length; i++) {
            uint airdropAmount = _amounts[i].sub(airdropInfo[_recipients[i]]);
            if (airdropAmount > 0) {
                aKEEPER.transfer(_recipients[i], airdropAmount);
                airdropInfo[_recipients[i]] = airdropInfo[_recipients[i]].add(airdropAmount);
            }
        }
    }

    function withdraw() external onlyOwner() {
        uint256 amount = aKEEPER.balanceOf(address(this));
        aKEEPER.transfer(msg.sender, amount);
    }
}
