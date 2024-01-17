// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AccessControlUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Initializable.sol";

import "./console.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract VoltichangeP2pETH is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant deadAddress =
        0x000000000000000000000000000000000000dEaD;
    address private constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant VOLT = 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;

    address public WETH;
    uint256 public fee; // default to 50 bp
    address public wallet;
    mapping(address => bool) public whitelisted_tokens;

    struct p2pOrder {
        address _from;
        address _to;
        address _tokenIn;
        uint256 _amountIn;
        address _tokenOut;
        uint256 _amountOut;
        uint256 _expires;
    }

    p2pOrder[] public p2pOrders;
    event p2pOrderCreated(
        address _from,
        address _to,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut,
        uint256 _arrayIndex,
        uint256 _expires
    );

    event p2pOrderDeleted(uint256 _orderIndex);

    function initialize(uint256 _fee, address _addr) public initializer {
        fee = _fee;
        wallet = _addr;
        WETH = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
        // whitelisted_tokens[WETH] = true;
        // whitelisted_tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; //USDT
        // whitelisted_tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; //USDC
    }

    function createPath(address _tokenIn, address _tokenOut)
        internal
        view
        returns (address[] memory)
    {
        address[] memory path;
        if (
            IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut) !=
            address(0)
        ) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        return path;
    }

    // requires that msg.sender approves this contract to move his tokens
    // _amountIn may be reduced if token has fees on transfer
    function sendP2POffer(
        address _to,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut,
        uint256 _expires
    ) external payable {
        require(_expires > block.timestamp, "_expires");
        p2pOrder memory order;
        if (msg.value > 0) {
            IWETH(WETH).deposit{value: msg.value}();
            order = p2pOrder(
                msg.sender,
                _to,
                WETH,
                msg.value,
                _tokenOut,
                _amountOut,
                _expires
            );
            p2pOrders.push(order);
            emit p2pOrderCreated(
                msg.sender,
                _to,
                _tokenIn,
                msg.value,
                _tokenOut,
                _amountOut,
                p2pOrders.length > 0 ? p2pOrders.length - 1 : 0,
                _expires
            );
        } else {
            uint256 prev_balance = IERC20Upgradeable(_tokenIn).balanceOf(
                address(this)
            );
            IERC20Upgradeable(_tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                _amountIn
            );
            uint256 curr_balance = IERC20Upgradeable(_tokenIn).balanceOf(
                address(this)
            );
            order = p2pOrder(
                msg.sender,
                _to,
                _tokenIn,
                curr_balance - prev_balance, // I do this to take into consideration fees on transfers
                // which can make the amountIn less than the real amount exchanged
                _tokenOut,
                _amountOut,
                _expires
            );
            p2pOrders.push(order);
            emit p2pOrderCreated(
                msg.sender,
                _to,
                _tokenIn,
                curr_balance - prev_balance,
                _tokenOut,
                _amountOut,
                p2pOrders.length > 0 ? p2pOrders.length - 1 : 0,
                _expires
            );
        }
    }

    // requires that msg.sender approves this contract to move his tokens
    // token out may be reduced if token has fees on transfer
    function acceptP2Porder(uint256 _orderIndex, bool _orderAccepted) external {
        p2pOrder memory order = p2pOrders[_orderIndex];
        require(order._to == msg.sender, "not sender");
        if (_orderAccepted && order._expires >= block.timestamp) {
            IERC20Upgradeable(order._tokenOut).safeTransferFrom(
                msg.sender,
                order._from,
                order._amountOut
            );

            uint256 _feeAmount = (order._amountIn * fee) / 10000;
            uint256 _amountInSub = order._amountIn - _feeAmount;
            if (order._tokenIn == WETH) {
                IWETH(WETH).withdraw(order._amountIn);
                (bool sent, ) = msg.sender.call{value: _amountInSub}("");
                require(sent, "Failed to send Ether");
            } else {
                IERC20Upgradeable(order._tokenIn).safeTransfer(
                    msg.sender,
                    _amountInSub
                );
            }
            burn(order._tokenIn, order._tokenOut, _feeAmount);
        } else {
            IERC20Upgradeable(order._tokenIn).safeTransfer(
                order._from,
                order._amountIn
            );
        }
        p2pOrders[_orderIndex] = p2pOrders[p2pOrders.length - 1];
        p2pOrders.pop();
        emit p2pOrderDeleted(_orderIndex);
    }

    function getP2PordersCount() public view returns (uint256) {
        return p2pOrders.length;
    }

    function burn(
        address _tokenIn,
        address _tokenOut,
        uint256 _feeAmount
    ) internal {
        address[] memory path = createPath(_tokenIn, _tokenOut);
        if (_tokenIn == WETH) {
            if (_tokenOut != VOLT) {
                uint256 _firstFeeAmount = _feeAmount / 2;
                // console.log("starting second swap");
                IUniswapV2Router02(UNISWAP_V2_ROUTER)
                    .swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: _firstFeeAmount
                }(0, path, deadAddress, block.timestamp);
                // console.log("second swap done");
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                (bool sent, ) = wallet.call{value: _secondFeeAmount}("");
                require(sent, "transfer ETH failed.");
            } else {
                (bool sent, ) = wallet.call{value: _feeAmount}("");
                require(sent, "transfer ETH failed.");
            }
        } else if (_tokenOut == WETH) {
            if (_tokenIn == VOLT) {
                IERC20Upgradeable(_tokenIn).safeTransfer(
                    deadAddress,
                    _feeAmount
                );
            } else {
                IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
                    UNISWAP_V2_ROUTER,
                    _feeAmount
                );
                uint256 prev_balance = address(this).balance; // prev_balance should be always == 0
                uint256 _firstFeeAmount = _feeAmount / 2;
                // console.log("starting second swap");
                IUniswapV2Router02(UNISWAP_V2_ROUTER)
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _firstFeeAmount,
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );
                (bool sent, ) = wallet.call{
                    value: address(this).balance - prev_balance
                }("");
                require(sent, "Failed to send Ether");
                // console.log("second swap done");
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                if (!whitelisted_tokens[_tokenIn]) {
                    IERC20Upgradeable(_tokenIn).safeTransfer(
                        deadAddress,
                        _secondFeeAmount
                    );
                } else {
                    prev_balance = address(this).balance; // prev_balance should be always == 0
                    // console.log("starting third swap");
                    IUniswapV2Router02(UNISWAP_V2_ROUTER)
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            _secondFeeAmount,
                            0,
                            path,
                            address(this),
                            block.timestamp
                        );
                    (sent, ) = wallet.call{
                        value: address(this).balance - prev_balance
                    }("");
                    require(sent, "Failed to send Ether");
                    // console.log("third swap done");
                }
            }
        } else {
            if (_tokenIn == VOLT) {
                IERC20Upgradeable(_tokenIn).safeTransfer(
                    deadAddress,
                    _feeAmount
                );
            } else {
                IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
                    UNISWAP_V2_ROUTER,
                    _feeAmount
                );
                uint256 _firstFeeAmount = _feeAmount / 2;
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                uint256 prev_balance = address(this).balance; // prev_balance should be always == 0
                path = createPath(_tokenIn, WETH);
                // console.log("starting second swap");
                IUniswapV2Router02(UNISWAP_V2_ROUTER)
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _firstFeeAmount,
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );
                (bool sent, ) = wallet.call{
                    value: address(this).balance - prev_balance
                }("");
                require(sent, "Failed to send Ether");
                // console.log("second swap done");
                if (
                    !whitelisted_tokens[_tokenIn] &&
                    whitelisted_tokens[_tokenOut]
                ) {
                    IERC20Upgradeable(_tokenIn).safeTransfer(
                        deadAddress,
                        _secondFeeAmount
                    );
                } else if (!whitelisted_tokens[_tokenOut]) {
                    path = createPath(_tokenIn, _tokenOut);
                    prev_balance = IERC20Upgradeable(_tokenOut).balanceOf(
                        address(this)
                    ); //prev_balance should always be equal to 0;
                    // console.log("starting third swap");
                    IUniswapV2Router02(UNISWAP_V2_ROUTER)
                        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                            _secondFeeAmount,
                            0,
                            path,
                            address(this),
                            block.timestamp
                        );
                    // console.log("third swap done");
                    uint256 curr_balance = IERC20Upgradeable(_tokenOut)
                        .balanceOf(address(this));
                    IERC20Upgradeable(_tokenOut).safeTransfer(
                        deadAddress,
                        curr_balance - prev_balance
                    );
                }
            }
        }
    }

    receive() external payable {}
}
