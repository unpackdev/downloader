// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./ERC20CappedUpgradeable.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract ThunderBot is Initializable, OwnableUpgradeable {
    IUniswapV2Router02 public uniswapV2Router;

    uint256 public feePercentage;
    address public teamWallet;
    address public revShareWallet;
    uint256 public revSharePercentageFees;

    event FeeTaken(uint256 amount);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * @param _uniswapV2Router Uniswap router address
     * @param _teamWallet Team wallet address
     * @param _revShareWallet Revenue share wallet address
     */
    function initialize(
        address _uniswapV2Router,
        address _teamWallet,
        address _revShareWallet
    ) public initializer {
        __Ownable_init();

        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);

        feePercentage = 100;
        teamWallet = _teamWallet;
        revShareWallet = _revShareWallet;
        revSharePercentageFees = 40;
    }

    /**
     * @dev Sets the fee percentage. Can only be called by the owner.
     */
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "Invalid fee percentage");
        feePercentage = _feePercentage;
    }

    /**
     * @dev Sets the revenue share percentage. Can only be called by the owner.
     */
    function setRevSharePercentage(
        uint256 _revSharePercentageFees
    ) public onlyOwner {
        require(_revSharePercentageFees <= 100, "Invalid fee percentage");
        revSharePercentageFees = _revSharePercentageFees;
    }

    /**
     * @dev Calculates the fee amount based on the fee percentage.
     */
    function calculateFee(uint256 amount) public view returns (uint256) {
        return (amount * feePercentage) / 10000;
    }

    /**
     * @dev Swaps exact tokens for ETH.
     * @param amountIn Amount of tokens to swap
     * @param amountOutMin Minimum amount of ETH to receive
     * @param token Token address
     * @param to Address to send ETH to
     * @param deadline Deadline for the swap
     * Take a fee on the swap and send it to the team wallet and the revenue share wallet.
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address token,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts) {
        require(
            IERC20(token).balanceOf(msg.sender) >= amountIn,
            "Insufficient balance"
        );
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= amountIn,
            "Insufficient allowance"
        );

        IERC20(token).transferFrom(msg.sender, address(this), amountIn);
        IERC20(token).approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapV2Router.WETH();

        uint currentBalance = address(this).balance;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        uint balanceAfterSwap = address(this).balance;

        uint amountReceived = balanceAfterSwap - currentBalance;

        uint256 feeAmount = calculateFee(amountReceived);

        payable(to).transfer(amountReceived - feeAmount);

        payable(teamWallet).transfer(
            (feeAmount * (100 - revSharePercentageFees)) / 100
        );
        payable(revShareWallet).transfer(
            (feeAmount * revSharePercentageFees) / 100
        );

        emit FeeTaken(feeAmount);

        return amounts;
    }

    /**
     * @dev Swaps exact ETH for tokens.
     * @param amountOutMin Minimum amount of tokens to receive
     * @param token Token address
     * @param to Address to send tokens to
     * @param deadline Deadline for the swap
     * Take a fee on the swap and send it to the team wallet and the revenue share wallet.
     */
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address token,
        address to,
        uint256 deadline
    ) external payable {
        require(msg.value > 0, "ETH amount must be greater than 0");

        uint256 feeAmount = calculateFee(msg.value);

        uint256 amountInAfterFee = msg.value - feeAmount;

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = token;

        try
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountInAfterFee }(
                amountOutMin, 
                path, 
                address(this), 
                deadline
            )
        {
            IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));

            payable(teamWallet).transfer(
                (feeAmount * (100 - revSharePercentageFees)) / 100
            );
            payable(revShareWallet).transfer(
                (feeAmount * revSharePercentageFees) / 100
            );

            emit FeeTaken(feeAmount);
        } catch {
            revert("Swap failed");
        }
    }
    
    /**
     * The methods withdrawFees and withdrawTokenFees are only used to withdraw stuck tokens and ETH from the contract.
     * They are not supposed to be used in the ThunderBot contract.
     */
    function withdrawFees(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(to).transfer(balance);
    }

    function withdrawTokenFees(address token, address to) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No fees to withdraw");
        IERC20(token).transfer(to, balance);
    }

    receive() external payable {}
}
