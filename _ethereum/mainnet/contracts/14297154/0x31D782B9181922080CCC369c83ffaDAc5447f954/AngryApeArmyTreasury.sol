// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

error WithdrawalFailedTeamMemberA();
error WithdrawalFailedTeamMemberB();
error WithdrawalFailedTeamMemberC();
error WithdrawalFailedTeamMemberD();
error WithdrawalFailedTeamMemberE();
error ZeroBalance();
error ZeroAddress();

contract AngryApeArmyTreasury is Ownable {
    using SafeMath for uint256;

    address public teamMemberA;
    address public teamMemberB;
    address public teamMemberC;
    address public teamMemberD;
    address public teamMemberE;

    constructor() {
        teamMemberA = 0x6ab71C2025442B694C8585aCe2fc06D877469D30;
        teamMemberB = 0x901FC05c4a4bC027a8979089D716b6793052Cc16;
        teamMemberC = 0x45f14c6F6649D1D4Cb3dD501811Ab7263285eaa3;
        teamMemberD = 0x672A7EC8fC186f6C9aa32d98C896821182907b08;
        teamMemberE = 0x5FA988805E792B6cA0466B2dbb52693b2DEfF33F;
    }

    receive() external payable {}

    function calculateSplit(uint256 balance)
        public
        pure
        returns (
            uint256 teamMemberAAmount,
            uint256 teamMemberBAmount,
            uint256 teamMemberCAmount,
            uint256 teamMemberDAmount,
            uint256 teamMemberEAmount
        )
    {
        uint256 rest = balance;
        teamMemberAAmount = (balance * 7000) / 10000; //70% | 5.25% of OpenSea resell
        rest -= teamMemberAAmount;

        teamMemberBAmount = (balance * 2000) / 10000; //20% | 1.50% of OpenSea resell
        rest -= teamMemberBAmount;

        teamMemberCAmount = (balance * 330) / 10000; //3.3% | 0.2475% of OpenSea resells
        rest -= teamMemberCAmount;

        teamMemberDAmount = (balance * 330) / 10000; //3.3% | 0.2475% of OpenSea resells
        rest -= teamMemberDAmount;

        teamMemberEAmount = rest; //3.4% | 0.255% of OpenSea resells
    }

    function withdrawErc20(IERC20 token) external onlyOwner {
        uint256 totalBalance = token.balanceOf(address(this));
        if (totalBalance == 0) revert ZeroBalance();

        (
            uint256 teamMemberAAmount,
            uint256 teamMemberBAmount,
            uint256 teamMemberCAmount,
            uint256 teamMemberDAmount,
            uint256 teamMemberEAmount
        ) = calculateSplit(totalBalance);

        if (!token.transfer(teamMemberA, teamMemberAAmount))
            revert WithdrawalFailedTeamMemberA();

        if (!token.transfer(teamMemberB, teamMemberBAmount))
            revert WithdrawalFailedTeamMemberB();

        if (!token.transfer(teamMemberC, teamMemberCAmount))
            revert WithdrawalFailedTeamMemberC();

        if (!token.transfer(teamMemberD, teamMemberDAmount))
            revert WithdrawalFailedTeamMemberD();

        if (!token.transfer(teamMemberE, teamMemberEAmount))
            revert WithdrawalFailedTeamMemberE();
    }

    function withdrawEth() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        if (totalBalance == 0) revert ZeroBalance();

        (
            uint256 teamMemberAAmount,
            uint256 teamMemberBAmount,
            uint256 teamMemberCAmount,
            uint256 teamMemberDAmount,
            uint256 teamMemberEAmount
        ) = calculateSplit(totalBalance);

        if (!payable(teamMemberA).send(teamMemberAAmount))
            revert WithdrawalFailedTeamMemberA();

        if (!payable(teamMemberB).send(teamMemberBAmount))
            revert WithdrawalFailedTeamMemberB();

        if (!payable(teamMemberC).send(teamMemberCAmount))
            revert WithdrawalFailedTeamMemberC();

        if (!payable(teamMemberD).send(teamMemberDAmount))
            revert WithdrawalFailedTeamMemberD();

        if (!payable(teamMemberE).send(teamMemberEAmount))
            revert WithdrawalFailedTeamMemberE();
    }

    function setTeamMemberA(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        teamMemberA = address_;
    }

    function setTeamMemberB(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        teamMemberB = address_;
    }

    function setTeamMemberC(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        teamMemberC = address_;
    }

    function setTeamMemberD(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        teamMemberD = address_;
    }

    function setTeamMemberE(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        teamMemberE = address_;
    }
}
