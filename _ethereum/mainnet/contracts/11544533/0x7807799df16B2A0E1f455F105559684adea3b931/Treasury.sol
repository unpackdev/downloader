pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IUniswap.sol";

// Treasury for the trading service
contract Treasury {

    /* Libraries */

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address internal constant uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /* Variables */

    // DAI
    address public currency;

    // user => balance (margin)
    mapping(address => uint256) public balances;

    // amount
    uint256 public totalUserBalance;

    // amount
    uint256 public dailyWithdrawalLimit;

    // amount
    uint256 public withdrawalsSinceCheckpoint;

    // block number
    uint256 public withdrawalCheckpoint;

    // amount
    uint256 public dailyOracleFundingLimit;

    // amount
    uint256 public oracleFundingSinceCheckpoint;

    // block number
    uint256 public oracleFundingCheckpoint;

    // amount
    uint256 public systemFundsLimit;

    IUniswap public uniswapRouter;

    address public owner;
    bool private initialized;

    address private trading;
    address private oracle;

    event OracleFunded(uint256 amountSpent, uint256 amountFunded);
    event SwappedOnUniswap(address currency1, address currency2, uint256 amountSpent, uint256 amountReceived);

    event NewContracts(address _oracle, address _trading);
    event NewWithdrawalLimit(uint256 amount);
    event NewOracleFundingLimit(uint256 amount);
    event NewSystemFundsLimit(uint256 amount);
    
    function initialize(address _currency) public {
        require(!initialized, '!initialized');
        initialized = true;
        owner = msg.sender;
        uniswapRouter = IUniswap(uniswap);
        currency = _currency;
    }

    function registerContracts(address _oracle, address _trading) external onlyOwner {
        oracle = _oracle;
        trading = _trading;
        emit NewContracts(_oracle, _trading);
    }

    function setWithdrawalLimit(uint256 amount) external onlyOwner {
        dailyWithdrawalLimit = amount;
        emit NewWithdrawalLimit(amount);
    }

    function setOracleFundingLimit(uint256 amount) external onlyOwner {
        dailyOracleFundingLimit = amount;
        emit NewOracleFundingLimit(amount);
    }

    function setSystemFundsLimit(uint256 amount) external onlyOwner {
        systemFundsLimit = amount;
        emit NewSystemFundsLimit(amount);
    }

    function fundOracle(
        uint256 amount
    ) external onlyOracle {
        // Check oracle limits. 5760 = blocks in a day for 15s/block
        if (oracleFundingCheckpoint.add(5760) < block.number) {
            oracleFundingCheckpoint = block.number;
            oracleFundingSinceCheckpoint = 0;
        }
        uint256 newOFSC = oracleFundingSinceCheckpoint.add(amount);
        require(newOFSC <= dailyOracleFundingLimit, '!daily_limit');
        oracleFundingSinceCheckpoint = newOFSC;
        require(IERC20(currency).approve(address(uniswapRouter), amount), '!approve');
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = uniswapRouter.WETH();
        uint[] memory amounts = uniswapRouter.swapExactTokensForETH(amount, 0, path, oracle, block.timestamp.add(1800));
        emit OracleFunded(amount, amounts[1]);
    }
    
    function swapOnUniswap(
        address[] calldata path,
        uint256 amount
    ) external onlyOwner {
        require(path.length > 1, '!invalid_path');
        require(IERC20(path[0]).approve(address(uniswapRouter), amount), '!approve');
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp.add(1800));
        emit SwappedOnUniswap(path[0], path[path.length - 1], amount, amounts[1]);
    }

    // all = true can be used to move funds to e.g. another treasury contract, including user balances
    function withdraw(
        uint256 amount,
        address to,
        bool all
    ) external onlyOwner {
        if (!all) {
            uint256 balance = IERC20(currency).balanceOf(address(this));
            require(balance > totalUserBalance, '!balance1');
            require(amount <= balance.sub(totalUserBalance), '!balance2');
        }
        IERC20(currency).safeTransfer(to, amount);
    }
    
    function userDeposit(
        address user,
        uint256 amount
    ) external onlyTrading {
        IERC20(currency).safeTransferFrom(user, address(this), amount);
        balances[user] = balances[user].add(amount);
        totalUserBalance = totalUserBalance.add(amount);
    }

    function userWithdraw(
        address user,
        uint256 amount
    ) external onlyTrading {
        uint256 userBalance = balances[user];
        if (amount <= userBalance) {
            // user can withdraw their treasury balance or less, regardless of daily limit
            balances[user] = balances[user].sub(amount);
            totalUserBalance = totalUserBalance.sub(amount);
            IERC20(currency).safeTransfer(user, amount);
        } else {
            uint256 totalAvailableToWithdraw = IERC20(currency).balanceOf(address(this)).sub(totalUserBalance).sub(systemFundsLimit);
            // user can withdraw more than their treasury balance (e.g. in profit)
            uint256 surplusWithdrawal = amount.sub(userBalance);
            require(surplusWithdrawal <= totalAvailableToWithdraw, '!system_threshold');
            // check surplus against daily withdrawal (surplus) limit. 5760 = blocks in a day for 15s/block
            if (withdrawalCheckpoint.add(5760) < block.number) {
                withdrawalCheckpoint = block.number;
                withdrawalsSinceCheckpoint = 0;
            }
            uint256 newWSC = withdrawalsSinceCheckpoint.add(surplusWithdrawal);
            require(newWSC <= dailyWithdrawalLimit, '!daily_limit');
            balances[user] = balances[user].sub(userBalance);
            totalUserBalance = totalUserBalance.sub(userBalance);
            IERC20(currency).safeTransfer(user, amount);
            withdrawalsSinceCheckpoint = newWSC;
        }
    }

    function collectFromUser(
        address user,
        uint256 amount
    ) external onlyTrading {
        balances[user] = balances[user].sub(amount);
        totalUserBalance = totalUserBalance.sub(amount);
    }

    function payToUser(
        address user,
        uint256 amount
    ) external onlyTrading {
        balances[user] = balances[user].add(amount);
        totalUserBalance = totalUserBalance.add(amount);
    }

    function getUserBalance(
        address user
    ) public view returns (uint256) {
        return balances[user];
    }

    function getTotalUserBalance() public view returns (uint256) {
        return totalUserBalance;
    }

    /* Modifiers */

    modifier onlyOwner() {
        require(msg.sender == owner, '!authorized');
        _;
    }

    modifier onlyTrading() {
        require(msg.sender == trading, '!authorized');
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, '!authorized');
        _;
    }

}