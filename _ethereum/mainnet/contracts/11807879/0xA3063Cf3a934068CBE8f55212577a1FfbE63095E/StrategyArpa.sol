pragma solidity 0.5.15;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IController.sol";
import "./TokenPool.sol";

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

contract StrategyArpa {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public want = address(0xBA50933C268F567BDC86E1aC131BE072C6B0b71a); // arpa

    address public governance;
    address public controller;

    // arpa reward is first stored here and is released linearly
    TokenPool public lockedPool;

    // period to release all the arpa in the locked pool
    uint256 public currentUnlockCycle;
    // initial arpa rewards unlock time
    uint256 public startTime;
    // last arpa rewards unlock time
    uint256 public lastUnlockTime;
    
    constructor(address _controller, address _governance, uint256 _startTime) public {
        governance = _governance;
        controller = _controller;
        startTime = _startTime;

        lockedPool = new TokenPool(IERC20(want));
    }

    /**
     * @dev Not used, preserved for interface
     */
    function deposit() public {}

    /**
     * @dev Get arpa rewards unlocked
     */
    function harvest() public {
        if (currentUnlockCycle == 0)
            return; // release ended
        uint256 timeDelta = now.sub(lastUnlockTime);
        if (currentUnlockCycle < timeDelta)
            currentUnlockCycle = timeDelta; // release all

        uint256 amount = lockedPool.balance().mul(timeDelta).div(currentUnlockCycle);

        currentUnlockCycle = currentUnlockCycle.sub(timeDelta);
        lastUnlockTime = now;

        lockedPool.transfer(address(this), amount);
    }
    
    /**
     * @dev Controller only function for creating additional rewards from dust
     * @param _asset Address of the dust
     * @return Amount of the dust
     */
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(address(_asset) != address(want), "!want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
    /**
     * @dev Withdraw partial funds, normally used with a vault withdrawal
     * @param _amount Amount of want token to withdraw
     */
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _balance;
        }
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount);
    }
    
    /**
     * @dev Withdraw all funds, normally used when migrating strategies
     */
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        balance = IERC20(want).balanceOf(address(this));
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }
    
    /**
     * @return deposited arpa + unlocked arpa rewards
     */
    function balanceOf() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    /**
     * @return deposited arpa + unlocked arpa rewards
     */
    function underlyingBalanceOf() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    /**
     * @dev we will lock more arpa tokens at each releasing cycle
     * @param amount the amount of arpa token to lock
     * @param nextUnlockCycle next reward releasing cycle, unit=day
     */
    function lock(uint256 amount, uint256 nextUnlockCycle) external {
        require(msg.sender == governance, "!governance");
        currentUnlockCycle = nextUnlockCycle * 1 days;
        if (now >= startTime) {
            lastUnlockTime = now;
        } else {
            lastUnlockTime = startTime;
        }
        
        require(
            lockedPool.token().transferFrom(msg.sender, address(lockedPool), amount),
            "Additional arpa transfer failed"
        );

    }

}