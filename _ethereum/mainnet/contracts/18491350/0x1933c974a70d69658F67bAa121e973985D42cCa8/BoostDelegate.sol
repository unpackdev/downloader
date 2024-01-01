// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ITokenMinter.sol";
import "./IBoostDelegate.sol";
import "./IVoterProxy.sol";
import "./IBooster.sol";

contract BoostDelegate is IBoostDelegate{

    address public immutable convexproxy;
    address public immutable cvxprisma;

    uint256 public boostFee;
    
    event SetMintableClaimer(address indexed _address, bool _valid);
    event SetBoostFee(uint256 _fee);

    constructor(address _proxy, address _cvxprisma, uint256 _fee){
        convexproxy = _proxy;
        cvxprisma = _cvxprisma;
        boostFee = _fee;
    }

    modifier onlyOwner() {
        require(IBooster(IVoterProxy(convexproxy).operator()).owner() == msg.sender, "!owner");
        _;
    }

    function setFee(uint256 _fee) external onlyOwner{
        boostFee = _fee;
        emit SetBoostFee(_fee);
    }

    function getFeePct(
        address, // claimant,
        address,// receiver,
        uint,// amount,
        uint,// previousAmount,
        uint// totalWeeklyEmissions
    ) external view returns (uint256 feePct){
        return boostFee;
    }

    function delegatedBoostCallback(
        address claimant,
        address receiver,
        uint,// amount,
        uint adjustedAmount,
        uint,// fee,
        uint,// previousAmount,
        uint// totalWeeklyEmissions
    ) external returns (bool success){
        if(receiver == convexproxy){
            if(adjustedAmount == 0) return false;

            ITokenMinter(cvxprisma).mint(claimant, adjustedAmount);
            return true;
        }

        return true;
    }

}