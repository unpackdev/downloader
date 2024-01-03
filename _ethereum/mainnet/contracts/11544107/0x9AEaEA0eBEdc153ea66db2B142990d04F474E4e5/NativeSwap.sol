// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

/** OpenZeppelin Dependencies Upgradable */
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
/** OpenZeppelin non ugpradable (Needed for the "Swap Token hex3t") */
import "./IERC20.sol";
/** Local Interfaces */
import "./IToken.sol";
import "./IAuction.sol";

contract NativeSwap is Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    event TokensSwapped(
        address indexed account,
        uint256 indexed stepsFromStart,
        uint256 userAmount,
        uint256 penaltyAmount
    );

    /** Role variables */
    bytes32 public constant MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /** Basic variables */
    uint256 public start;
    uint256 public period;
    uint256 public stepTimestamp;
    /** Contract Variables */
    IERC20 public swapToken;
    IToken public mainToken;
    IAuction public auction;
    /** Mappings */
    mapping(address => uint256) public swapTokenBalanceOf;

    /** Booleans */
    bool public init_;

    /** Variables after initial contract launch must go below here. https://github.com/OpenZeppelin/openzeppelin-sdk/issues/37 */
    /** End Variables after launch */

    /** Roles */
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Caller is not a manager");
        _;
    }
    modifier onlyMigrator() {
        require(hasRole(MIGRATOR_ROLE, _msgSender()), "Caller is not a migrator");
        _;
    }
    /** Init functions */
    function initialize(
        address _manager,
        address _migrator
    ) public initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        init_ = false;
    }

    function init(
        uint256 _period,
        uint256 _stepTimestamp,
        address _swapToken,
        address _mainToken,
        address _auction
    ) external onlyMigrator {
        require(!init_, "init is active");
        init_ = true;
        
        period = _period;
        stepTimestamp = _stepTimestamp;
        swapToken = IERC20(_swapToken);
        mainToken = IToken(_mainToken);
        auction = IAuction(_auction);
        
        if (start == 0) {
            start = now;
        }
    }
    /** End init functions */

    function deposit(uint256 _amount) external {
        require(
            swapToken.transferFrom(msg.sender, address(this), _amount),
            "NativeSwap: transferFrom error"
        );
        swapTokenBalanceOf[msg.sender] = swapTokenBalanceOf[msg.sender].add(
            _amount
        );
    }

    function withdraw(uint256 _amount) external {
        require(_amount >= swapTokenBalanceOf[msg.sender], "balance < amount");
        swapTokenBalanceOf[msg.sender] = swapTokenBalanceOf[msg.sender].sub(
            _amount
        );
        swapToken.transfer(msg.sender, _amount);
    }

    function swapNativeToken() external {
        uint256 stepsFromStart = calculateStepsFromStart();
        require(stepsFromStart <= period, "swapNativeToken: swap is over");
        uint256 amount = swapTokenBalanceOf[msg.sender];
        require(amount != 0, "swapNativeToken: amount == 0");
        uint256 deltaPenalty = calculateDeltaPenalty(amount);
        uint256 amountOut = amount.sub(deltaPenalty);
        swapTokenBalanceOf[msg.sender] = 0;
        mainToken.mint(address(auction), deltaPenalty);
        auction.callIncomeDailyTokensTrigger(deltaPenalty);
        mainToken.mint(msg.sender, amountOut);

        emit TokensSwapped(msg.sender, stepsFromStart, amount, deltaPenalty);
    }

    function calculateDeltaPenalty(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 stepsFromStart = calculateStepsFromStart();
        if (stepsFromStart > period) return amount;
        return amount.mul(stepsFromStart).div(period);
    }

    function calculateStepsFromStart() public view returns (uint256) {
        return now.sub(start).div(stepTimestamp);
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }
}
