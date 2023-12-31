//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IAuroxBridge.sol";
import "./EIP712MetaTransaction.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";


contract AuroxBridge is 
    Ownable,
    ReentrancyGuard,
    IAuroxBridge,
    EIP712MetaTransaction {
    using SafeERC20 for IERC20;

    address public immutable usdcAddress;
    IUniswapV2Router02 public immutable uniRouter;
    address public nodeAddress;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public assetsOf;
    mapping(bytes32 => bool) public transactions;

    modifier onlyNode() {
        require(EIP712MetaTransaction.msgSender() == nodeAddress, "only node allowed!");
        _;
    }

    event Withdraw(address indexed token, address indexed recipient, uint256 amount);

    constructor(
        address usdcAddress_,
        address routerAddress_,
        address nodeAddress_) EIP712MetaTransaction("AuroxBridge", "1") {
        usdcAddress = usdcAddress_;
        uniRouter = IUniswapV2Router02(routerAddress_);
        nodeAddress = nodeAddress_;
    }

    receive() external payable {}

    function setNode(address nodeAddress_) external onlyOwner {
        require(nodeAddress_ != address(0), "bad input");
        nodeAddress = nodeAddress_;
    }

    function withdrawETH(address recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "insufficient funds");
        (bool success, ) = recipient.call{value: balance}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED'); 
        emit Withdraw(address(0), recipient, balance);
    }

    function withdraw(IERC20 token, address recipient) external onlyOwner {
        _withdraw(token, recipient);
    }

    function batchWithdraw(IERC20[] calldata tokens, address recipient) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            _withdraw(tokens[i], recipient);
        }
    }

    /**
    * @notice Register the swap request from user
    * @dev thisTokenPath[0] = inputToken,
    *   thisTokenPath[last] = stableToken
    */
    function registerSwap(
        address[] calldata thisTokenPath,
        address[] calldata targetTokenPath,
        uint256 amountIn,
        uint256 minAmountOut) external override nonReentrant {       
        require(
            thisTokenPath.length > 1 &&
            targetTokenPath.length > 0 &&
            amountIn > 0 &&
            minAmountOut > 0,
            "bad inputs"
        );
        require(
            thisTokenPath[thisTokenPath.length-1] == usdcAddress,
            "path not usdc ended"
        );

        address sender = EIP712MetaTransaction.msgSender();
        IERC20 token = IERC20(thisTokenPath[0]);
        token.safeTransferFrom(sender, address(this), amountIn);
        token.safeApprove(address(uniRouter), amountIn);

        IERC20 usdc = IERC20(usdcAddress);
        uint256 usdcBalanceBefore = usdc.balanceOf(address(this));

        uniRouter.swapExactTokensForTokens(
            amountIn,
            minAmountOut,
            thisTokenPath,
            address(this),
            block.timestamp);
        
        uint256 amountUsd = usdc.balanceOf(address(this)) - usdcBalanceBefore;
        require(amountUsd > 0, "bad swap");

        uint256 balanceUsd = balanceOf[sender] + amountUsd;
        balanceOf[sender] = balanceUsd;

        emit RegisterSwap(
            sender,
            thisTokenPath,
            targetTokenPath,
            amountIn,
            amountUsd,
            balanceUsd);
    }

    /**
     * @notice Register the usdc swap request from user
     */
    function registerUsdcSwap(
        address[] calldata targetTokenPath,
        uint256 amountIn) external override nonReentrant {       
        require(
            targetTokenPath.length > 0 &&
            amountIn > 0,
            "bad inputs"
        );

        address sender = EIP712MetaTransaction.msgSender();
        IERC20 usdc = IERC20(usdcAddress);
        usdc.safeTransferFrom(sender, address(this), amountIn);

        uint256 balanceUsd = balanceOf[sender] + amountIn;
        balanceOf[sender] = balanceUsd;

        address[] memory thisTokenPath = new address[](1);
        thisTokenPath[0] = usdcAddress;

        emit RegisterSwap(
            sender,
            thisTokenPath,
            targetTokenPath,
            amountIn,
            amountIn,
            balanceUsd);
    }

    /**
    * @notice Purchase asset on behalf of user
    * @dev thisTokenPath should be generated by user
    */
    function buyAssetOnBehalf(
        address[] calldata thisTokenPath,
        address userAddress,
        uint256 usdAmount,
        uint256 usdBalance,
        bytes32 hash) external override onlyNode {
        require(
            userAddress != address(0) &&
            !transactions[hash],
            "bad inputs"
        );
        require(
            usdAmount <= usdBalance - balanceOf[userAddress],
            "bad user balance"
        );
        require(
            thisTokenPath[0] == usdcAddress,
            "path not usdc started"
        );

        transactions[hash] = true;

        IERC20 usdc = IERC20(usdcAddress);
        usdc.safeApprove(address(uniRouter), usdAmount);

        IERC20 token = IERC20(thisTokenPath[thisTokenPath.length - 1]);
        uint256 tokenBalanceBefore = token.balanceOf(userAddress);

        uniRouter.swapExactTokensForTokens(
            usdAmount,
            1,
            thisTokenPath,
            userAddress,
            block.timestamp);

        uint256 amountOut = token.balanceOf(userAddress) - tokenBalanceBefore;
        require(amountOut > 0, "bad swap");
        assetsOf[userAddress][address(token)] += amountOut;
        uint256 _usdBalance = balanceOf[userAddress] + usdAmount;
        balanceOf[userAddress] = _usdBalance;

        emit BuyAssetOnBehalf(
            userAddress,
            address(token),
            amountOut,
            usdAmount,
            _usdBalance,
            hash);
    }

    /**
    * @notice Purchase usdc on behalf of user
    */
    function buyUsdcOnBehalf(
        address userAddress,
        uint256 usdAmount,
        uint256 usdBalance,
        bytes32 hash) external override onlyNode {
        require(
            userAddress != address(0) &&
            !transactions[hash],
            "bad inputs"
        );
        require(
            usdAmount <= usdBalance - balanceOf[userAddress],
            "bad user balance"
        );

        transactions[hash] = true;

        IERC20(usdcAddress).safeTransfer(userAddress, usdAmount);

        assetsOf[userAddress][usdcAddress] += usdAmount;
        uint256 _usdBalance = balanceOf[userAddress] + usdAmount;
        balanceOf[userAddress] = _usdBalance;

        emit BuyAssetOnBehalf(
            userAddress,
            usdcAddress,
            usdAmount,
            usdAmount,
            _usdBalance,
            hash);
    }

    function _withdraw(IERC20 token, address recipient) internal {
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.safeTransfer(recipient, amount);
            emit Withdraw(address(token), recipient, amount);
        }
    }
}
