// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ITokenMinter.sol";
import "./ITokenLocker.sol";
import "./IPrismaVesting.sol";

contract VestingClaim{

    address public immutable escrow;
    address public immutable prismaVesting;
    address public immutable convexproxy;
    address public immutable cvxprisma;

    
    event Claimed(address indexed _address, uint256 _amount);

    constructor(address _proxy, address _cvxprisma, address _escrow, address _prismaVesting){
        convexproxy = _proxy;
        cvxprisma = _cvxprisma;
        escrow = _escrow;
        prismaVesting = _prismaVesting;
    }

    function claimToConvexFull() external{
        claimToConvex(0);
    }

    function claimToConvex(uint256 _amount) public{
        //get previous
        (uint256 beforeAmount,) = ITokenLocker(escrow).getAccountBalances(convexproxy);
        beforeAmount *= ITokenLocker(escrow).lockToTokenRatio();

        //call claim
        IPrismaVesting(prismaVesting).lockFutureClaimsWithReceiver(msg.sender, convexproxy, _amount);

        //get difference
        (uint256 afterAmount,) = ITokenLocker(escrow).getAccountBalances(convexproxy);
        afterAmount *= ITokenLocker(escrow).lockToTokenRatio();

        //mint
        ITokenMinter(cvxprisma).mint(msg.sender, afterAmount - beforeAmount);

        emit Claimed(msg.sender, afterAmount - beforeAmount);
    }

}