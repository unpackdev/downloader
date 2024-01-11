// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeERC20.sol";
import "Ownable.sol";
import "EnumerableSet.sol";
import "ReentrancyGuard.sol";

import "IUniswapV2Router02.sol";
//import "IUniswapV2Router02.sol";


/** @title BridgeLeft
  * @notice user wants to make a payment for an order
  *   orderId: 42
  *   orderUSDAmount: 123
  *
  * call paymentERC20(orderId=42, orderUSDAmount=123, payableToken=XXX, ...) or paymentERC20 or paymentETH
  *       |
  *       |   ~ contract adds serviceFee
  *       |   ~ contract swaps payableToken to stablecoin
  *       |__________________
  *       |                  |
  *       V                  V
  *   destination       serviceFeeTreasury
**/
contract BridgeLeft is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // we always pass USD with 6 decimals
    // in functions: estimateFee, paymentStablecoin, estimatePayableTokenAmount, paymentERC20, paymentETH
    uint256 constant public USD_DECIMALS = 6;

    uint256 internal constant ONE_PERCENT = 100;  // 1%
    uint256 public constant FEE_DENOMINATOR = 100 * ONE_PERCENT;  // 100%
    uint256 public feeNumerator = 5 * ONE_PERCENT;

    address public serviceFeeTreasury;  // this is a service fee for the project support

    bool public whitelistAllTokens;  // do we want to accept all erc20 token as a payment? todo: be careful with deflationary etc
    EnumerableSet.AddressSet internal _whitelistTokens;  // erc20 tokens we accept as a payment (before swap)  //todo gas optimisations
    EnumerableSet.AddressSet internal _whitelistStablecoins;  // stablecoins we accept as a final payment method  //todo gas optimisations
    mapping (address => uint256) public stablecoinDecimals;

    address immutable public router;  // dex router we use todo: maybe make it updateable or just deploy new contract?

    // we need orderId
    // if someone from 2 different browsers will try to make a payment, the backend
    // will not be able to understand which transfer match which order
    // we also need (user -> order -> flag) mapping because if we use (order -> flag) mapping
    // other malicious user may front-run the client and make him sad :-(
    mapping (address /*user*/ => mapping (bytes16 /*orderId*/ => bool)) public userPaidOrders;

    event ServiceFeeTreasurySet(address indexed value);
    event WhitelistAllTokensSet(bool value);
    event TokenAddedToWhitelistStablecoins(address indexed token, uint256 decimals);
    event TokenAddedToWhitelist(address indexed token);
    event TokenRemovedFromWhitelistStablecoins(address indexed token);
    event TokenRemovedFromWhitelist(address indexed token);
    event OrderPaid(
        bytes16 orderId,
        uint256 orderUSDAmount,
        address destination,
        address payer,
        address payableToken,
        uint256 payableTokenAmount,
        address stablecoin,
        uint256 serviceFeeUSDAmount
    );

    constructor(
        address routerAddress,
        address serviceFeeTreasuryAddress
    ) {
        require(routerAddress != address(0), "zero address");
        router = routerAddress;

        require(serviceFeeTreasuryAddress != address(0), "zero address");
        serviceFeeTreasury = serviceFeeTreasuryAddress;
    }

    function setServiceFeeTreasury(address serviceFeeTreasuryAddress) external onlyOwner {
        require(serviceFeeTreasuryAddress != address(0), "zero address");
        serviceFeeTreasury = serviceFeeTreasuryAddress;
        emit ServiceFeeTreasurySet(serviceFeeTreasuryAddress);
    }

    function setWhitelistAllTokens(bool value) external onlyOwner {
        whitelistAllTokens = value;
        emit WhitelistAllTokensSet(value);
    }

    function getWhitelistedTokens() external view returns(address[] memory) {
        uint256 length = _whitelistTokens.length();
        address[] memory result = new address[](length);
        for (uint256 i=0; i < length; ++i) {
            result[i] = _whitelistTokens.at(i);
        }
        return result;
    }

    function getWhitelistedStablecoins() external view returns(address[] memory) {
        uint256 length = _whitelistStablecoins.length();
        address[] memory result = new address[](length);
        for (uint256 i=0; i < length; ++i) {
            result[i] = _whitelistStablecoins.at(i);
        }
        return result;
    }

    function isTokenWhitelisted(address token) external view returns(bool) {
        return _whitelistTokens.contains(token);
    }

    function isWhitelistedStablecoin(address token) public view returns(bool) {
        return _whitelistStablecoins.contains(token);
    }

    modifier onlyWhitelistedTokenOrAllWhitelisted(address token) {
        require(whitelistAllTokens || _whitelistTokens.contains(token), "not whitelisted");
        _;
    }

    function addTokenToWhitelist(address token) external onlyOwner {
        require(_whitelistTokens.add(token), "already whitelisted");
        emit TokenAddedToWhitelist(token);
    }

    function removeTokenFromWhitelist(address token) external onlyOwner {
        require(_whitelistTokens.remove(token), "not whitelisted");
        emit TokenRemovedFromWhitelist(token);
    }

    function addTokenToWhitelistStablecoins(address token, uint256 decimals) external onlyOwner {
        require(_whitelistStablecoins.add(token), "already whitelisted stablecoin");
        stablecoinDecimals[token] = decimals;
        emit TokenAddedToWhitelistStablecoins(token, decimals);
    }

    function removeTokenFromWhitelistStablecoins(address token) external onlyOwner {
        require(_whitelistStablecoins.remove(token), "not whitelisted stablecoin");
        delete stablecoinDecimals[token];
        emit TokenRemovedFromWhitelistStablecoins(token);
    }

    function setFeeNumerator(uint256 newFeeNumerator) external onlyOwner {
        require(newFeeNumerator <= 1000, "Max fee numerator: 1000");
        feeNumerator = newFeeNumerator;
    }

    // ==== payment

    function estimateFee(
        uint256 orderUSDAmount  // 6 decimals
    ) view external returns(uint256) {
        return orderUSDAmount * feeNumerator / FEE_DENOMINATOR;
    }

    // not supporting deflationary or transfer-fee stablecoin (warning: usdt IS transfer-fee stablecoin but fee=0 now)
    function paymentStablecoin(
        bytes16 orderId,
        uint256 orderUSDAmount,  // 6 decimals
        address destination,
        address stablecoin
    ) external nonReentrant {
        require(destination != address(0), "zero address");
        require(!userPaidOrders[msg.sender][orderId], "order already paid");
        require(isWhitelistedStablecoin(stablecoin), "the end path is not stablecoin");
        userPaidOrders[msg.sender][orderId] = true;

        uint256 orderUSDAmountERC20DECIMALS = orderUSDAmount * (10 ** stablecoinDecimals[stablecoin]) / (10 ** USD_DECIMALS);
        uint256 feeStablecoinAmount = orderUSDAmount * feeNumerator / FEE_DENOMINATOR;
        uint256 feeStablecoinAmountERC20DECIMALS = feeStablecoinAmount * (10 ** stablecoinDecimals[stablecoin]) / (10 ** USD_DECIMALS);

        IERC20(stablecoin).safeTransferFrom(msg.sender, destination, orderUSDAmountERC20DECIMALS);
        IERC20(stablecoin).safeTransferFrom(msg.sender, serviceFeeTreasury, feeStablecoinAmountERC20DECIMALS);

        emit OrderPaid({
            orderId: orderId,
            orderUSDAmount: orderUSDAmount,
            destination: destination,
            payer: msg.sender,
            payableToken: stablecoin,
            payableTokenAmount: (orderUSDAmountERC20DECIMALS + feeStablecoinAmountERC20DECIMALS),
            stablecoin: stablecoin,
            serviceFeeUSDAmount: feeStablecoinAmount
        });
    }

    // view method to return how much tokens should be transferred
    function estimatePayableTokenAmount(
        uint256 orderUSDAmount,  // 6 decimals
        address[] calldata path
    ) external view onlyWhitelistedTokenOrAllWhitelisted(path[0]) returns(uint256) {
        require(isWhitelistedStablecoin(path[path.length-1]), "the end path is not stablecoin");
        uint256 orderUSDAmountERC20DECIMALS = orderUSDAmount * (10 ** stablecoinDecimals[path[path.length-1]]) / (10 ** USD_DECIMALS);
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(orderUSDAmountERC20DECIMALS, path);
        return amounts[0];
    }

    // not supporting deflationary tokens (99.9% of cases)
    function paymentERC20(
        bytes16 orderId,
        uint256 orderUSDAmount,  // 6 decimals
        address destination,
        uint256 payableTokenMaxAmount,
        uint256 deadline,
        address[] calldata path
    ) external onlyWhitelistedTokenOrAllWhitelisted(path[0]) nonReentrant {
        require(destination != address(0), "zero address");
        require(!userPaidOrders[msg.sender][orderId], "order already paid");
        require(isWhitelistedStablecoin(path[path.length-1]), "the end path is not stablecoin");
        userPaidOrders[msg.sender][orderId] = true;

        uint256 orderUSDAmountERC20DECIMALS = orderUSDAmount * (10 ** stablecoinDecimals[path[path.length-1]]) / (10 ** USD_DECIMALS);
        uint256 feeStablecoinAmount = orderUSDAmount * feeNumerator / FEE_DENOMINATOR;

        uint256 amountIn;

        {
            uint256 feeStablecoinAmountERC20DECIMALS = feeStablecoinAmount * (10 ** stablecoinDecimals[path[path.length-1]]) / (10 ** USD_DECIMALS);
            uint256 totalAmountERC20DECIMALS = orderUSDAmountERC20DECIMALS + feeStablecoinAmountERC20DECIMALS;
            amountIn = IUniswapV2Router02(router).getAmountsIn(totalAmountERC20DECIMALS, path)[0];  // todo think about 2x cycle
            require(amountIn <= payableTokenMaxAmount, "insufficient payableTokenMaxAmount");
            IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
            IERC20(path[0]).safeApprove(router, amountIn);  // think: approve type(uint256).max once
            IUniswapV2Router02(router).swapExactTokensForTokens({
                amountIn: amountIn,
                amountOutMin: totalAmountERC20DECIMALS,
                path: path,
                to: address(this),
                deadline: deadline
            });
            IERC20(path[path.length-1]).safeTransfer(destination, orderUSDAmountERC20DECIMALS);
            IERC20(path[path.length-1]).safeTransfer(serviceFeeTreasury, feeStablecoinAmountERC20DECIMALS);
        }

        // no dust tokens are rest on the SC balance since we use getAmountsIn

        emit OrderPaid({
            orderId: orderId,
            orderUSDAmount: orderUSDAmount,
            destination: destination,
            payer: msg.sender,
            payableToken: path[0],
            payableTokenAmount: amountIn,
            stablecoin: path[path.length-1],
            serviceFeeUSDAmount: feeStablecoinAmount
        });
    }

    // supporting deflationary tokens (0.1% of cases)
    // todo think about it and test it well!
//    function paymentERC20SupportingFeeOnTransfer(
//        bytes16 orderId,
//        uint256 orderUSDAmount,
//        address destination,
//        uint256 payableTokenMaxAmount,
//        uint256 deadline,
//        address[] calldata path,
//        uint256 minTokensRestAmountToReturn
//    ) external onlyWhitelistedTokenOrAllWhitelisted(path[0]) nonReentrant {
//        address stablecoin = path[path.length-1];
//
//        require(destination != address(0), "zero address");
//        require(!userPaidOrders[msg.sender][orderId], "order already paid");
//        require(isWhitelistedStablecoin(stablecoin), "the end path is not stablecoin");
//        userPaidOrders[msg.sender][orderId] = true;
//
//        uint256 feeStablecoinAmount = orderUSDAmount * feeNumerator / FEE_DENOMINATOR;
//
//        uint256 contractStablecoinBalanceBefore = IERC20(stablecoin).balanceOf(address(this));
//        uint256 payableTokenReceivedAmount;
//
//        {
//            uint256 contractPayableTokenBalanceBefore = IERC20(path[0]).balanceOf(address(this));
//            IERC20(path[0]).safeTransferFrom(msg.sender, address(this), payableTokenMaxAmount);
//            uint256 contractPayableTokenBalanceAfterTransfer = IERC20(path[0]).balanceOf(address(this));
//            payableTokenReceivedAmount = contractPayableTokenBalanceAfterTransfer - contractPayableTokenBalanceBefore;
//        }
//
//        IERC20(path[0]).safeApprove(router, payableTokenReceivedAmount);
//
//        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens({
//            amountIn: payableTokenReceivedAmount,
//            amountOutMin: orderUSDAmount + feeStablecoinAmount,
//            path: path,
//            to: address(this),
//            deadline: deadline
//        });
//
//        IERC20(stablecoin).safeTransfer(destination, orderUSDAmount);
//        IERC20(stablecoin).safeTransfer(serviceFeeTreasury, feeStablecoinAmount);
//
//        // send rest of stablecoins to msg.sender
//        {
//            uint256 stablecoinTokenRestAmount = IERC20(path[0]).balanceOf(address(this)) - contractStablecoinBalanceBefore;
//            if (stablecoinTokenRestAmount >= minTokensRestAmountToReturn) {  // do not return dust
//                IERC20(stablecoin).safeTransfer(msg.sender, stablecoinTokenRestAmount);
//            }
//        }
//
//        emit OrderPaid({
//            orderId: orderId,
//            orderUSDAmount: orderUSDAmount,
//            destination: destination,
//            payer: msg.sender,
//            payableToken: path[0],
//            payableTokenAmount: payableTokenReceivedAmount,
//            stablecoin: stablecoin,
//            serviceFeeUSDAmount: feeStablecoinAmount
//        });
//    }

    function paymentETH(
        bytes16 orderId,
        uint256 orderUSDAmount,  // 6 decimals
        address destination,
        uint256 deadline,
        address[] calldata path,
        uint256 minETHRestAmountToReturn
    ) external payable onlyWhitelistedTokenOrAllWhitelisted(path[0]) nonReentrant {
        address stablecoin = path[path.length-1];

        require(destination != address(0), "zero address");
        require(!userPaidOrders[msg.sender][orderId], "order already paid");
        require(isWhitelistedStablecoin(stablecoin), "the end path is not stablecoin");
        userPaidOrders[msg.sender][orderId] = true;

        uint256 feeStablecoinAmount = orderUSDAmount * feeNumerator / FEE_DENOMINATOR;

        _paymentETHProcess(
            orderUSDAmount,  // 6 decimals
            destination,
            deadline,
            path,
            minETHRestAmountToReturn,
            feeStablecoinAmount
        );

        emit OrderPaid({
            orderId: orderId,
            orderUSDAmount: orderUSDAmount,
            destination: destination,
            payer: msg.sender,
            payableToken: address(0),
            payableTokenAmount: msg.value,
            stablecoin: stablecoin,
            serviceFeeUSDAmount: feeStablecoinAmount
        });
    }

    function _paymentETHProcess(
        uint256 orderUSDAmount,  // 6 decimals
        address destination,
        uint256 deadline,
        address[] calldata path,
        uint256 minETHRestAmountToReturn,
        uint256 feeStablecoinAmount
    ) internal {
        uint256 orderUSDAmountERC20DECIMALS = orderUSDAmount * (10 ** stablecoinDecimals[path[path.length-1]]) / (10 ** USD_DECIMALS);
        uint256 feeStablecoinAmountERC20DECIMALS = feeStablecoinAmount * (10 ** stablecoinDecimals[path[path.length-1]]) / (10 ** USD_DECIMALS);
        uint256 totalAmountERC20DECIMALS = orderUSDAmountERC20DECIMALS + feeStablecoinAmountERC20DECIMALS;
        uint256[] memory amounts = IUniswapV2Router02(router).swapETHForExactTokens{value: msg.value}(
            totalAmountERC20DECIMALS,
            path,
            address(this),
            deadline
        );

        // send rest of tokens to msg.sender
        {
            uint256 ethRest = msg.value - amounts[0];
            if (ethRest >= minETHRestAmountToReturn) {
                (bool sent, /*bytes memory data*/) = payable(msg.sender).call{value: ethRest}("");
                require(sent, "Failed to send Ether");
            }
        }

        IERC20(path[path.length-1]).safeTransfer(destination, orderUSDAmountERC20DECIMALS);
        IERC20(path[path.length-1]).safeTransfer(serviceFeeTreasury, feeStablecoinAmountERC20DECIMALS);
    }

    // ==== withdraw occasionally transferred tokens from the contract (or dust)

    fallback() external payable { }  // we need it to receive eth on the contract from uniswap
    
    function withdrawERC20To(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        token.safeTransfer(recipient, amount);
    }

    function withdrawETHTo(address recipient, uint256 amount) external onlyOwner {
        // https://solidity-by-example.org/sending-ether/
        (bool sent, /*bytes memory data*/) = payable(recipient).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
