pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";

import "./Constants.sol";
import "./SafeAmount.sol";
import "./ISafetyLocker.sol";
import "./IFestaked.sol";
import "./SweepToOwner.sol";
import "./IReshapableToken.sol";
import "./Locker.sol";

/**
 * A contract to safely add liquidity.
 */
contract LiquidityAdder is Ownable, SweepToOwner {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public targetToken;
    ISafetyLocker public antiBot;
    IWETH public WETH;
    uint256 public ethCap;
    uint256 public ethDeposited;

    constructor(address _targetToken, IWETH _weth) public {
        targetToken = IERC20(_targetToken);
        WETH = _weth;
        require(targetToken.totalSupply() != 0, "LA: Token has no supply.");
    }

    function setEthCap(uint256 cap) external onlyOwner {
        ethCap = cap;
    }

    function setSafetyLock(ISafetyLocker _antiBot) external onlyOwner {
        antiBot = _antiBot;
        if (address(antiBot) != address(0)) {
            require(
                ISafetyLocker(_antiBot).IsSafetyLocker(),
                "Bad safetyLocker"
            );
        }
    }

    function safeBuyWithETHAndAddLiqAndDepositAndStake(
        address _targetToken,
        address depositToken,
        IFestaked stake,
        bool shouldDeposit,
        bool shouldStake,
        uint256 deadline
    ) external payable {
        uint256 amountEth = msg.value;
        require(amountEth != 0, "No ETH was sent");
        require(shouldDeposit, "Temp: Deposit is mandatory");
        WETH.deposit{value: amountEth}();
        uint256 _ethDeposited = ethDeposited;
        uint256 _ethCap = ethCap;
        if (_ethCap != 0 && _ethDeposited.add(amountEth) > _ethCap) {
            uint256 newAmount = _ethCap.sub(_ethDeposited);
            IERC20(address(WETH)).transfer(msg.sender, amountEth.sub(newAmount));
            amountEth = newAmount;
        }
        ethDeposited = ethDeposited.add(amountEth); // Add the eth optimistically.
        _safeBuyAndAddLiqAndDepositAndStake(
            address(WETH),
            amountEth,
            _targetToken,
            depositToken,
            stake,
            shouldDeposit,
            shouldStake,
            msg.sender,
            deadline
        );
    }

    function _safeBuyAndAddLiqAndDepositAndStake(
        address sourceToken,
        uint256 sourceAmount,
        address _targetToken,
        address depositToken,
        IFestaked stake,
        bool shouldDeposit,
        bool shouldStake,
        address to,
        uint256 deadline
    ) internal {
        // First buy target tokens with a very large slippage allowed
        // Then add the bought token as liquidity.
        // If shouldDeposit, deposit those tokens.
        // If shouldStake, stake those tokens.
        // pass it all to the owner
        (uint256 sourceLeft, uint256 targetAmount) =
            _safeBuy(sourceToken, sourceAmount.div(2), _targetToken, deadline, to);
        uint256 liquidity = _addBoughtLiquidity(sourceToken, _targetToken, sourceLeft,
            targetAmount, deadline);
        address pool = Constants.uniV2Factory.getPair(
                _targetToken,
                sourceToken);
        require(pool != address(0), "Pool address is 0");
        require(IERC20(pool).balanceOf(address(this)) >= liquidity, "Not enough liquidity was generated");
        // _syncLiquiditySupply(pool);

        _safeDepositLiqAndStakeFor(pool, liquidity, depositToken, stake,
            shouldDeposit, shouldStake, to);
    }

    function _addBoughtLiquidity(address sourceToken, address _targetToken,
        uint256 sourceToAdd, uint256 targetAmount, uint256 deadline) internal returns (uint256) {

        (/*uint256 sourceUsed */, /*uint256 targetUsed */, uint256 liquidity) =
            Constants.uniV2Router02.addLiquidity(
                sourceToken,
                _targetToken,
                sourceToAdd,
                targetAmount,
                0,
                0,
                address(this),
                deadline
            );
        uint256 ethRefund = IERC20(sourceToken).balanceOf(address(this));
        if (ethRefund != 0) {
            IERC20(sourceToken).transfer(msg.sender, ethRefund);
        }
        return liquidity;
    }

    function _safeDepositLiqAndStakeFor (
        address pool, uint256 liquidity, address depositToken, IFestaked stake,
        bool shouldDeposit, bool shouldStake, address to) internal {
        if (shouldDeposit) {
            _safeDepositAndStakeFor(
                pool,
                liquidity,
                depositToken,
                stake,
                shouldStake,
                to
            );
        } else {
            IERC20(pool).safeTransfer(to, liquidity);
        }
    }

    /**
     * Make sure to approve liquidityAdder on your lp token
     */
    // function safeDepositAndStake(
    //     address lpToken,
    //     uint256 lpAmount,
    //     address depositToken,
    //     IFestaked stake,
    //     bool shouldStake
    // ) public {
    //     IERC20(lpToken).transferFrom(msg.sender, address(this), lpAmount);
    //     _safeDepositAndStakeFor(
    //         lpToken,
    //         lpAmount,
    //         depositToken,
    //         stake,
    //         shouldStake,
    //         msg.sender
    //     );
    // }

    function _safeDepositAndStakeFor(
        address lpToken,
        uint256 lpAmount,
        address depositToken,
        IFestaked stake,
        bool shouldStake,
        address to
    ) internal {
        // Deposit and get deposit tokens
        IERC20(lpToken).approve(depositToken, lpAmount);
        uint256 deposited = IReshapableToken(depositToken).deposit(lpToken, lpAmount);
        require(deposited != 0, "LA: Zero deposit");
        uint256 postLpBalance = IERC20(lpToken).balanceOf(address(this));
        if (postLpBalance != 0) {
            // Return undeposited lp.
            IERC20(lpToken).transfer(to, postLpBalance);
        }
        if (shouldStake) {
            IERC20(depositToken).approve(address(stake), deposited);
            stake.stakeFor(to, deposited); // We might not stake all.
            uint256 postDepositBalance = IERC20(depositToken).balanceOf(address(this));
            if (postDepositBalance != 0) {
                IERC20(depositToken).transfer(to, postDepositBalance);
            }
        } else {
            IERC20(depositToken).transfer(to, deposited);
        }
    }

    function _safeBuy(
        address sourceToken,
        uint256 sourceAmount,
        address _targetToken,
        uint256 deadline,
        address beneficiary
    ) internal returns (uint256, uint256) {
        address[] memory path = new address[](2);
        path[0] = sourceToken;
        path[1] = _targetToken;
        Constants.uniV2Router02.swapExactTokensForTokens(
                sourceAmount,
                0,
                path,
                address(this),
                deadline
            );
        antiBot.verifyUserAddress(beneficiary, sourceAmount);

        return (IERC20(sourceToken).balanceOf(address(this)), IERC20(_targetToken).balanceOf(address(this)));
    }

    function syncLiquiditySupply(address pool)
        external
        onlyOwner()
    {
        _syncLiquiditySupply(pool);
    }

    function _syncLiquiditySupply(address pool) internal {
        ILockerUser target = ILockerUser(address(targetToken));
        ILocker locker = target.locker();
        if (address(locker) != address(0)) {
            locker.syncLiquiditySupply(pool);
        }
    }

    /**
     * @dev to save gas call this once.
     */
    function approveMe(address token) external {
        IERC20(address(WETH)).approve(address(Constants.uniV2Router02), 2**128);
        IERC20(token).safeApprove(address(Constants.uniV2Router02), 2**128);
    }
}
