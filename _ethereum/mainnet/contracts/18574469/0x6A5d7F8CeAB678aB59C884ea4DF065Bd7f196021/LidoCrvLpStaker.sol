// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LidoStakerBase.sol";
import "./ILidoCrvLpStaker.sol";
import "./IPointsDistributor.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo. 
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract LidoCrvLpStaker is LidoStakerBase {
    address public constant ST_ETH_GAUGE =
        0x182B723a58739a9c974cFDB385ceaDb237453c28;
    address public constant STAKER = 0x271fbE8aB7f1fB262f81C77Ea5303F03DA9d3d6A;
    address public constant LP_TOKEN =
        0x06325440D014e39736583c165C2963BA99fAf14E;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant ZERO_ADDRESS =
        0x0000000000000000000000000000000000000000;
    address public constant CRV = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;

    address public rewardsContract;    

    function setPointsDistributorContract(
        address _rewardsContract
    ) public onlyOwner {
        rewardsContract = _rewardsContract;
    }

    function _chargeFee(uint256 amount) private returns (uint256) {
        address feeDestination = IPointsDistributor(rewardsContract)
            .feeDestination();
        uint256 shortcutComplexity = IPointsDistributor(rewardsContract)
            .shortcuts(address(this))
            .complexity;
        uint256 fee = amount / (shortcutComplexity * 1000);

        payable(feeDestination).transfer(fee);
        return fee;
    }

    receive() external payable {
        uint256 chargedFees = _chargeFee(msg.value);
        uint256 amoutAfterFee = msg.value - chargedFees;
        uint256 depositEthAmount = amoutAfterFee / 2;
        uint256 depositStEthAmount = amoutAfterFee - depositEthAmount;

        require(depositEthAmount > 0, "!depositEthAmount");
        require(depositStEthAmount > 0, "!depositStEthAmount");

        ILido(ST_ETH).submit{value: depositStEthAmount}(ZERO_ADDRESS);
        uint256 stEthAmount = IERC20(ST_ETH).balanceOf(address(this));

        IERC20(ST_ETH).approve(STAKER, IERC20(ST_ETH).balanceOf(address(this)));
        IStEthGauge(ST_ETH_GAUGE).set_approve_deposit(STAKER, true);

        uint256 depositEthAmountCopy = depositEthAmount;

        IStaker(STAKER).deposit_and_stake{value: depositEthAmountCopy}(
            CRV,
            LP_TOKEN,
            ST_ETH_GAUGE,
            2,
            [ETH, ST_ETH, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
            [depositEthAmountCopy, stEthAmount, 0, 0, 0],
            0,
            false,
            ZERO_ADDRESS
        );

        uint256 stakedLpTokensBalance = IERC20(ST_ETH_GAUGE).balanceOf(
            address(this)
        );
        IERC20(ST_ETH_GAUGE).transfer(msg.sender, stakedLpTokensBalance);

        uint256 remainingEth = address(this).balance;
        uint256 remainingStEth = IERC20(ST_ETH).balanceOf(address(this));
        uint256 remainingLpTokens = IERC20(LP_TOKEN).balanceOf(address(this));
        uint256 remaingStLpTokens = IERC20(ST_ETH_GAUGE).balanceOf(
            address(this)
        );

        require(remainingStEth <= 1, "!remainingStEth");
        require(remainingEth == 0, "!remainingEth");
        require(remaingStLpTokens == 0, "!remamingStLpTokens");
        require(remainingLpTokens == 0, "!remainingLpTokens");

        if (IPointsDistributor(rewardsContract).isPointDistributionActive()) {
            IPointsDistributor(rewardsContract).distributePoints(msg.value);
        }
    }
}
