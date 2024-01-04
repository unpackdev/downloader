// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./IToken.sol";
import "./IDelegate.sol";

interface BalDistributer {
    struct Claim {
        uint256 week;
        uint256 balance;
        bytes32[] merkleProof;
    }

    function claimWeeks(address, Claim[] calldata) external;
}

interface BPool {
    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);
}

interface Controller {
    function vaults(address) external view returns (address);

    function rewards() external view returns (address);
}

contract StrategyBalancerBPT {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant want = address(0x9dDE0b1d39d0d2C6589Cde1BFeD3542d2a3C5b11);
    address public constant distributer = address(0x6d19b2bF3A36A61530909Ae65445a906D98A2Fa8);
    address public constant bal = address(0xba100000625a3754423978a60c9317c58a424e3D);
    address public constant delegateRegistry = address(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);
    uint256 public performanceFee = 500;
    uint256 public constant performanceMax = 10000;

    uint256 public lastHarvestTimestamp = 0;
    address public governance;
    address public strategist;
    address public controller;
    IERC20 public token;
    BalDistributer public balDistributer;
    BPool public bPool;

    constructor(address _controller) public {
        governance = msg.sender;
        strategist = msg.sender;
        balDistributer = BalDistributer(distributer);
        bPool = BPool(want);
        controller = _controller;
    }

    function getName() external pure returns (string memory) {
        return "StrategyBalancerBPT";
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function deposit() public {
        // This strategy doesn't need to deposit
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == governance || msg.sender == strategist, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(Controller(controller).rewards(), balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        // since our token did not in gauge, we shall not need to check balance
        require(msg.sender == controller, "!controller");
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        balance = IERC20(want).balanceOf(address(this));
        address _vault = Controller(controller).vaults(address(want));
        IERC20(want).safeTransfer(_vault, balance);
    }

    function balanceOf() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function harvest(BalDistributer.Claim[] calldata claims) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        balDistributer.claimWeeks(address(this), claims);

        uint256 claimAmount = IERC20(bal).balanceOf(address(this));
        if (claimAmount > 0) {
            uint256 _fee = claimAmount.mul(performanceFee).div(performanceMax);
            IERC20(bal).safeTransfer(Controller(controller).rewards(), _fee);

            uint256 remainAmount = claimAmount.sub(_fee);
            IERC20(bal).safeApprove(address(bPool), 0);
            IERC20(bal).safeApprove(address(bPool), remainAmount);
            bPool.joinswapExternAmountIn(bal, remainAmount, 0);
            lastHarvestTimestamp = block.timestamp;
        }
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setLastHarvestTimestamp(uint256 timestamp) external {
        require(msg.sender == governance, "!governance");
        lastHarvestTimestamp = timestamp;
    }

    function setDelegate(bytes32 id, address delegate) external {
        require(msg.sender == governance, "!governance");
        IDelegate(delegateRegistry).setDelegate(id, delegate);
    }

    function clearDelegate(bytes32 id) external {
        require(msg.sender == governance, "!governance");
        IDelegate(delegateRegistry).clearDelegate(id);
    }
}
