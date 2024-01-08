// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IConvexDeposit.sol";
import "./ITangoSmartWallet.sol";
import "./IConvexWithdraw.sol";
import "./ITangoFactory.sol";

contract TangoSmartWallet is ITangoSmartWallet { 
    using SafeERC20 for IERC20;
    address public immutable factory;
    address public lpToken;
    uint256 public override stakedBalance;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant convex = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public override owner;


    event Stake(uint256 indexed amount);
    event WithDraw(uint256 indexed amount);
    modifier onlyFactory() {
        require(msg.sender == factory, "Opps!Only-factory");
        _;
    }
    constructor() public {
        factory = msg.sender;
    }
    function initialize(address _owner, address _lp, address _pool) external override onlyFactory() { 
        owner = _owner;
        lpToken = _lp;
        IERC20(_lp).approve(_pool, type(uint256).max);
    }

    function stake(address _pool, uint256 _pid) external override onlyFactory() {
        uint balance = IERC20(lpToken).balanceOf(address(this));
        require(balance > 0, "Invalid-amount");
        IConvexDeposit(_pool).depositAll(_pid, true);
        stakedBalance = stakedBalance + balance;
        emit Stake(balance);
    }

    function withdraw(address _pool, uint256 _amount) external override onlyFactory() {
        IConvexWithdraw(_pool).withdrawAndUnwrap(_amount, false);
        IERC20(lpToken).safeTransfer(msg.sender, _amount);  
        stakedBalance = stakedBalance - _amount;
        emit WithDraw(_amount);
    }

    function claimReward(address _pool) external override onlyFactory() returns (uint256, uint256) {
        IConvexWithdraw(_pool).getReward();
        uint balanceCrv = IERC20(crv).balanceOf(address(this));
        uint balanceCvx = IERC20(convex).balanceOf(address(this));
        return (
            balanceCrv, 
            balanceCvx
        );
    } 

}