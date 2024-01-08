// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./OwnablePausable.sol";
import "./IUniswapV2Router02.sol";

contract Market is OwnablePausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /// @notice Address of cumulative token.
    ERC20 public cumulativeToken;

    /// @notice Address of product token contract.
    ERC20 public immutable productToken;

    /// @notice Address of reward token contract.
    ERC20 public immutable rewardToken;

    /// @dev Address of UniswapV2Router.
    IUniswapV2Router02 public uniswapRouter;

    /// @notice An event thats emitted when an uniswap router contract address changed.
    event UniswapRouterChanged(address indexed newUniswapRouter);

    /// @notice An event thats emitted when an cumulative token changed.
    event CumulativeChanged(address indexed newCumulativeToken);

    /// @notice An event thats emitted when an account buyed token.
    event Buy(address indexed customer, address indexed currency, uint256 payment, uint256 buy, uint256 reward);

    /**
     * @param _cumulativeToken Address of cumulative token.
     * @param _productToken Address of product token.
     * @param _rewardToken Address of reward token.
     * @param _uniswapRouter Address of Uniswap router contract.
     */
    constructor(
        address _cumulativeToken,
        address _productToken,
        address _rewardToken,
        address _uniswapRouter
    ) public {
        require(_cumulativeToken != _productToken && _cumulativeToken != _rewardToken, "Market::constructor: invalid cumulative token address");
        require(_productToken != _rewardToken, "Market::constructor: invalid product token address");

        cumulativeToken = ERC20(_cumulativeToken);
        productToken = ERC20(_productToken);
        rewardToken = ERC20(_rewardToken);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    /**
     * @notice Changed uniswap router contract address.
     * @param _uniswapRouter Address new uniswap router contract.
     */
    function changeUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        emit UniswapRouterChanged(_uniswapRouter);
    }

    /**
     * @notice Changed cumulative token address.
     * @param newCumulativeToken Address new cumulative token.
     * @param recipient Address of recipient for withdraw current cumulative balance.
     */
    function changeCumulativeToken(address newCumulativeToken, address recipient) external onlyOwner {
        require(newCumulativeToken != address(productToken) && newCumulativeToken != address(rewardToken), "Market::changeCumulativeToken: invalid cumulative token address");
        require(cumulativeToken.decimals() <= productToken.decimals(), "Market::changeCumulativeToken: invalid cumulative token decimals");

        transfer(address(cumulativeToken), recipient, cumulativeToken.balanceOf(address(this)));
        cumulativeToken = ERC20(newCumulativeToken);
        emit CumulativeChanged(newCumulativeToken);
    }

    /**
     * @dev Transfer token to recipient.
     * @param from Address of transfered token contract.
     * @param recipient Address of recipient.
     * @param amount Amount of transfered token.
     */
    function transfer(
        address from,
        address recipient,
        uint256 amount
    ) public onlyOwner {
        require(recipient != address(0), "Market::transfer: cannot transfer to the zero address");

        ERC20(from).safeTransfer(recipient, amount);
    }

    /**
     * @dev Calculate product and reward amount by cumulative token amount.
     * @param amount Amount of cumulative token.
     * @return product Amount of product token.
     * @return reward Amount of reward token.
     */
    function _cumulativeToProduct(uint256 amount) internal view returns (uint256 product, uint256 reward) {
        ERC20 _productToken = productToken; // gas optimization

        product = amount.mul(10**uint256(_productToken.decimals()).sub(cumulativeToken.decimals()));

        uint256 productTokenBalance = _productToken.balanceOf(address(this));
        if (productTokenBalance > 0) {
            reward = product.mul(rewardToken.balanceOf(address(this))).div(productTokenBalance);
        }
    }

    /**
     * @notice Get token price.
     * @param currency Currency token.
     * @param payment Amount of payment.
     * @return product Amount of product token.
     * @return reward Amount of reward token.
     */
    function price(address currency, uint256 payment) public view returns (uint256 product, uint256 reward) {
        address _cumulativeToken = address(cumulativeToken);
        uint256 amountOut = payment;
        if (currency != _cumulativeToken) {
            address[] memory path = new address[](2);
            path[0] = currency;
            path[1] = _cumulativeToken;
            uint256[] memory amountsOut = uniswapRouter.getAmountsOut(payment, path);
            amountOut = amountsOut[1];
        }

        return _cumulativeToProduct(amountOut);
    }

    /**
     * @notice Buy token with ERC20.
     * @param currency Currency token.
     * @param payment Amount of payment.
     * @param productMin Minimum amount of output product token.
     * @return True if success.
     */
    function buy(
        address currency,
        uint256 payment,
        uint256 productMin
    ) external whenNotPaused returns (bool) {
        ERC20 _cumulativeToken = cumulativeToken; // gas optimization
        ERC20 _productToken = productToken; // gas optimization
        IUniswapV2Router02 _uniswapRouter = uniswapRouter; // gas optimization
        address sender = _msgSender();

        uint256 amountOut = payment;
        ERC20(currency).safeTransferFrom(sender, address(this), payment);
        if (currency != address(_cumulativeToken)) {
            address[] memory path = new address[](2);
            path[0] = currency;
            path[1] = address(_cumulativeToken);
            uint256 amountOutMin = productMin.div(10**uint256(_productToken.decimals()).sub(_cumulativeToken.decimals()));

            ERC20(currency).safeApprove(address(_uniswapRouter), payment);
            amountOut = _uniswapRouter.swapExactTokensForTokens(payment, amountOutMin, path, address(this), block.timestamp)[1];
        }

        (uint256 product, uint256 reward) = _cumulativeToProduct(amountOut);
        _productToken.safeTransfer(sender, product);
        if (reward > 0) {
            rewardToken.safeTransfer(sender, reward);
        }

        emit Buy(sender, currency, payment, product, reward);

        return true;
    }
}
