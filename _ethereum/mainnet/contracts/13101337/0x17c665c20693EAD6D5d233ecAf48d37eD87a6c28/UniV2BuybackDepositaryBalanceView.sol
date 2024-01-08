// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./OwnablePausable.sol";
import "./IDepositaryBalanceView.sol";
import "./Issuer.sol";

contract UniV2BuybackDepositaryBalanceView is IDepositaryBalanceView, OwnablePausable {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /// @notice Balance decimals.
    uint256 public constant override decimals = 18;

    /// @notice Address of buyback token.
    ERC20 public immutable token;

    /// @notice Address of issuer contract.
    Issuer public issuer;

    /// @notice Uniswap router contract.
    IUniswapV2Router02 public uniswapRouter;

    /// @notice Buyback caller.
    address public caller;

    /// @notice An event that is emitted when an issuer contract address changed.
    event IssuerChanged(address newIssuer);

    /// @notice An event that is emitted when an Uniswap router contract address changed.
    event UniswapRouterChanged(address newRouter);

    /// @notice An event that is emitted when an caller wallet changed.
    event CallerChanged(address newCaller);

    /// @notice An event that is emitted when an contract buyback stable token.
    event Buyback(uint256 amount, uint256 buy);

    constructor(
        address _token,
        address _issuer,
        address _uniswapRouter,
        address _caller
    ) public {
        token = ERC20(_token);
        issuer = Issuer(_issuer);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        caller = _caller;
    }

    /**
     * @notice Change issuer contract address.
     * @param _issuer New issuer contract address.
     */
    function changeIssuer(address _issuer) external onlyOwner {
        require(_issuer != address(0), "UniV2BuybackDepositaryBalanceView::changeIssuer: invalid address");
        issuer = Issuer(_issuer);

        require(issuer.stableToken().decimals() >= ERC20(token).decimals(), "UniV2BuybackDepositaryBalanceView::changeIssuer: invalid stable token decimals");

        emit IssuerChanged(_issuer);
    }

    /**
     * @notice Change Uniswap router contract address.
     * @param _uniswapRouter New Uniswap router contract address.
     */
    function changeUniswapRouter(address _uniswapRouter) external onlyOwner {
        require(_uniswapRouter != address(0), "UniV2BuybackDepositaryBalanceView::changeUniswapRouter: invalid address");
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        emit UniswapRouterChanged(_uniswapRouter);
    }

    /**
     * @notice Change caller wallet.
     * @param _caller New caller wallet.
     */
    function changeCaller(address _caller) external onlyOwner {
        caller = _caller;
        emit CallerChanged(_caller);
    }

    /**
     * @notice Transfer token to recipient.
     * @param _token Target token.
     * @param recipient Address of recipient.
     * @param amount Amount of transferred token.
     */
    function transfer(
        address _token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        ERC20(_token).safeTransfer(recipient, amount);
    }

    /**
     * @notice Buyback stable token from Uniswap pool.
     * @param amount Amount of buyback token.
     */
    function buy(uint256 amount) external whenNotPaused {
        require(_msgSender() == owner() || _msgSender() == caller, "UniV2BuybackDepositaryBalanceView::buy: invalid caller");
        require(amount > 0, "UniV2BuybackDepositaryBalanceView::buy: zero amount");

        address stableToken = address(issuer.stableToken());
        uint256 stableTokenDecimals = ERC20(stableToken).decimals();

        uint256 allowance = token.allowance(address(this), address(uniswapRouter));
        if (allowance < amount) {
            if (allowance > 0) {
                token.approve(address(uniswapRouter), 0);
            }
            token.approve(address(uniswapRouter), amount);
        }

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = stableToken;
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amount,
            amount.mul(10**(stableTokenDecimals.sub(token.decimals()))), // 1 to 1
            path,
            address(this),
            block.timestamp + 10 minutes
        );

        uint256 stableTotalSupply = ERC20(stableToken).totalSupply();
        uint256 collateralBalance = issuer.balance();
        if (stableTotalSupply > collateralBalance) {
            uint256 issuerInbalance = stableTotalSupply.sub(collateralBalance);
            uint256 burningAmount = issuerInbalance.min(ERC20(stableToken).balanceOf(address(this)));
            if (burningAmount > 0) {
                ERC20(stableToken).safeTransfer(address(issuer), burningAmount);
                issuer.rebalance();
            }
        }
        emit Buyback(amount, amounts[1]);
    }

    /**
     * @notice Get balance of depositary.
     * @return Balance of depositary.
     */
    function balance() external view override returns (uint256) {
        uint256 tokenBalance = token.balanceOf(address(this));

        return tokenBalance.mul(10**(decimals.sub(token.decimals())));
    }
}
