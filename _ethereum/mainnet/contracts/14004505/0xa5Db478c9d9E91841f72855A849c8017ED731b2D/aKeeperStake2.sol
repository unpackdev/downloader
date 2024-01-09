// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IStaking.sol";


contract aKeeperStake2 is Ownable {
    using SafeMath for uint256;

    IERC20 public aKEEPER;
    IERC20 public KEEPER;
    address public staking;
    mapping( address => uint ) public depositInfo;

    uint public depositDeadline;
    uint public withdrawStart;
    uint public withdrawDeadline;

    
    constructor(address _aKEEPER, uint _depositDeadline, uint _withdrawStart, uint _withdrawDeadline) {
        require( _aKEEPER != address(0) );
        aKEEPER = IERC20(_aKEEPER);
        depositDeadline = _depositDeadline;
        withdrawStart = _withdrawStart;
        withdrawDeadline = _withdrawDeadline;
    }

    function setDepositDeadline(uint _depositDeadline) external onlyOwner() {
        depositDeadline = _depositDeadline;
    }

    function setWithdrawStart(uint _withdrawStart) external onlyOwner() {
        withdrawStart = _withdrawStart;
    }

    function setWithdrawDeadline(uint _withdrawDeadline) external onlyOwner() {
        withdrawDeadline = _withdrawDeadline;
    }

    function setKeeperStaking(address _KEEPER, address _staking) external onlyOwner() {
        KEEPER = IERC20(_KEEPER);
        staking = _staking;
    }

    function depositaKeeper(uint amount) external {
        require(block.timestamp < depositDeadline, "Deadline passed.");
        aKEEPER.transferFrom(msg.sender, address(this), amount);
        depositInfo[msg.sender] = depositInfo[msg.sender].add(amount);
    }

    // function withdrawaKeeper() external {
    //     require(block.timestamp > withdrawStart, "Not started.");
    //     uint amount = depositInfo[msg.sender].mul(110).div(100);
    //     require(amount > 0, "No deposit present.");
    //     delete depositInfo[msg.sender];
    //     aKEEPER.transfer(msg.sender, amount);
    // }

    function migrate() external {
        require(block.timestamp > withdrawStart, "Not started.");
        require( address(KEEPER) != address(0) );
        uint amount = depositInfo[msg.sender].mul(110).div(100);
        require(amount > 0, "No deposit present.");
        delete depositInfo[msg.sender];
        KEEPER.transfer(msg.sender, amount);
    }

    function migrateTrove(bool _wrap) external {
        require(block.timestamp > withdrawStart, "Not started.");
        require( staking != address(0) );
        uint amount = depositInfo[msg.sender].mul(110).div(100);
        require(amount > 0, "No deposit present.");
        delete depositInfo[msg.sender];
        KEEPER.approve( staking, amount );
        IStaking( staking ).stake( amount, msg.sender, _wrap );
    }

    function withdrawAll() external onlyOwner() {
        require(block.timestamp > withdrawDeadline, "Deadline not yet passed.");
        uint256 Keeperamount = KEEPER.balanceOf(address(this));
        KEEPER.transfer(msg.sender, Keeperamount);
    }
}