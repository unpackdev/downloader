// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ITokenMinter.sol";
import "./ITokenLocker.sol";
import "./IBoostDelegate.sol";
import "./IVoterProxy.sol";
import "./IBooster.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract BoostDelegate is IBoostDelegate{
    using SafeERC20 for IERC20;

    address public constant escrow = address(0x3f78544364c3eCcDCe4d9C89a630AEa26122829d);
    address public constant prismaVault = address(0x06bDF212C290473dCACea9793890C5024c7Eb02c);
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public immutable convexproxy;
    address public immutable cvxprisma;

    uint256 public boostFee;
    address[] public sweepableTokens;

    event SetMintableClaimer(address indexed _address, bool _valid);
    event SetBoostFee(uint256 _fee);
    event SetSweepableTokens(address[] _tokens);

    constructor(address _proxy, address _cvxprisma, uint256 _fee){
        convexproxy = _proxy;
        cvxprisma = _cvxprisma;
        boostFee = _fee;
        sweepableTokens = [cvx, crv];
    }

    modifier onlyOwner() {
        require(IBooster(IVoterProxy(convexproxy).operator()).owner() == msg.sender, "!owner");
        _;
    }

    function setFee(uint256 _fee) external onlyOwner{
        boostFee = _fee;
        emit SetBoostFee(_fee);
    }

    function setSweepableTokens(address[] calldata _tokens) external onlyOwner{
        sweepableTokens = _tokens;
        emit SetSweepableTokens(_tokens);
    }

    function getFeePct(
        address, // claimant,
        address receiver,
        uint,// amount,
        uint,// previousAmount,
        uint// totalWeeklyEmissions
    ) external view returns (uint256 feePct){
        if(receiver == convexproxy){
            return 0;
        }
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
        require(msg.sender == prismaVault, "!vault");
        if(receiver == convexproxy){

            adjustedAmount = adjustedAmount / ITokenLocker(escrow).lockToTokenRatio() * ITokenLocker(escrow).lockToTokenRatio();
            if(adjustedAmount > 0){
                ITokenMinter(cvxprisma).mint(claimant, adjustedAmount);
            }

            for(uint256 i = 0; i < sweepableTokens.length; ){
                uint256 balance = IERC20(sweepableTokens[i]).balanceOf(convexproxy);

                if(balance > 0){
                    IBooster(IVoterProxy(convexproxy).operator()).recoverERC20FromProxy(sweepableTokens[i], balance, claimant);
                }

                unchecked{
                    ++i;
                }
            }

            
            return true;
        }

        return true;
    }

}