// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;
import "./IHopRouter.sol";
import "./bridgesBase.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract OnthisToArb is BridgesBase {
    receive() external payable {
        uint256 chargedFees = _chargeFee(msg.value);

        uint256 chainId = 42161;
        address recipient = msg.sender;
        uint256 amount = msg.value - chargedFees;
        uint256 amountOutMin = 0;
        uint256 deadline = block.timestamp + 3600;
        address relayer = address(0);
        uint256 relayerFee = 0;

        hopRouter.sendToL2{value: amount}(
            chainId,
            recipient,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );

        if (IPointsDistributor(rewardsContract).isPointDistributionActive()) {
            IPointsDistributor(rewardsContract).distributePoints(msg.value);
        }
    }
}
