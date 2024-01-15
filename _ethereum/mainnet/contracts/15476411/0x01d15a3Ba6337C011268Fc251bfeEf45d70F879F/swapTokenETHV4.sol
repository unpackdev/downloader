// SPDX-License-Identifier: MIT
// Author: Luca Di Domenico: twitter.com/luca_dd7
pragma solidity ^0.8.9;

import "./AccessControlUpgradeable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract Voltichange is AccessControlUpgradeable {
    uint256[100] private __gap;
    IUniswapV2Factory factory;
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address public wallet;

    // address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    uint256 public fee; // default to 500 bp
    address public VOLT;
    mapping(address => bool) public whitelisted_tokens;

    event PathCreated(address[] path);
    event Swap(address tokenIn, address tokenOut, address receiver, uint256 amountIn);

    function initialize(uint256 _fee, address _addr) public initializer {
        __AccessControl_init();
        fee = _fee;
        wallet = _addr;
        // whitelisted_tokens[IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()] = true;
        // whitelisted_tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; //USDT
        // whitelisted_tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; //USDC
        VOLT = 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;
        _grantRole(
            DEFAULT_ADMIN_ROLE,
            msg.sender
        );
        _grantRole(ADMIN, msg.sender);
        _grantRole(DEVELOPER, msg.sender);
    }

    // TODO to calculate the price of exchange we have to use a secure method: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/trading-from-a-smart-contract
    function swapTokenForToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external {
        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;

        require(IERC20(_tokenIn).transferFrom(msg.sender, wallet, feeAmount), "transferFrom failed.");
        require(IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountInSub), "transferFrom failed.");
        require(IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountInSub), "approve failed.");

        address[] memory path = createPath(_tokenIn, _tokenOut);
        uint256 prev_balance = IERC20(_tokenOut).balanceOf(address(this));
        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountInSub,
                _amountOutMin,
                path,
                address(this),
                block.timestamp
            );
        uint256 curr_balance = IERC20(_tokenOut).balanceOf(address(this));
        // IERC20(_tokenOut).transfer(msg.sender, curr_balance - prev_balance);
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, ) = _tokenOut.call(abi.encodeWithSelector(0xa9059cbb, msg.sender, curr_balance - prev_balance));
        require(success, "transfer failed");
        emit Swap(_tokenIn, _tokenOut, msg.sender,_amountIn);
    }

    function swapTokenForETH(address _tokenIn, uint256 _amountIn, uint256 _amountOutMin) external {
        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;
        require(IERC20(_tokenIn).transferFrom(msg.sender, wallet, feeAmount), "transferFrom failed.");
        require(IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountInSub), "transferFrom failed.");

        address[] memory path = createPath(_tokenIn, IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH());
        if(_tokenIn == IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()) {
            IWETH(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()).withdraw(_amountIn);
            (bool sent, ) = msg.sender.call{value: _amountInSub}("");
            require(sent, "Failed to send Ether");
        } else {
            require(IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountInSub), "approve failed.");
            uint256 prev_balance = address(this).balance;
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _amountInSub,
                    _amountOutMin,
                    path,
                    address(this),
                    block.timestamp
                );
            (bool sent, ) = msg.sender.call{value: address(this).balance - prev_balance}("");
            require(sent, "Failed to send Ether");
        }
        emit Swap(_tokenIn, IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH(), msg.sender, _amountIn);
    }

    function swapETHforToken(
        address _tokenOut,
        uint256 _amountOutMin
    ) external payable {
        uint256 feeAmount = (msg.value * fee) / 10000;
        uint256 _amountInSub = msg.value - feeAmount;

        (bool sent,) = wallet.call{value: feeAmount}("");
        require(sent, "transferFrom failed.");

        if(_tokenOut == IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()) {
            IWETH(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()).deposit{value: _amountInSub}();
            IERC20(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH()).transfer(msg.sender, _amountInSub);
        } else {
            address[] memory path;
            path = new address[](2);
            path[0] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
            path[1] = _tokenOut;
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
                .swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amountInSub}(
                    _amountOutMin,
                    path,
                    msg.sender,
                    block.timestamp
                );
        }
        emit Swap(IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH(), _tokenOut, msg.sender, msg.value);
    }

    function getPair(address _tokenIn, address _tokenOut)
        external
        view 
        returns (address)
    {
        return IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut);
    }

    function getAmountOutMin(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint256) {

        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 _amountInSub = _amountIn - feeAmount;

        address[] memory path = createPath(_tokenIn, _tokenOut);

        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountInSub, path);
        return amountOutMins[path.length - 1];
    }

    function getAmountOutMinWithoutFees(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view onlyRole(DEVELOPER) returns (uint256) {
        address[] memory path = createPath(_tokenIn, _tokenOut);
        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);

        return amountOutMins[path.length - 1];
    }

    function createPath(address _tokenIn, address _tokenOut) internal view returns (address[] memory) {
        address[] memory path;
        if (IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut) != address(0)) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
            path[2] = _tokenOut;
        }
        return path;
    }

    /* this function can be used to:
     * - withdraw
     * - send refund to users in case something goes
     */
    function sendEthToAddr(uint256 _amount, address payable _to) external payable onlyRole(ADMIN)
    {
        require(
            _amount <= address(this).balance,
            "amount must be <= than balance."
        );
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function sendTokenToAddr(uint256 _amount, address _tokenAddress, address _to) external onlyRole(ADMIN) {
        require(IERC20(_tokenAddress).transferFrom(address(this), _to, _amount), "transferFrom failed.");
    }

    function setWallet(address _wallet) external onlyRole(ADMIN) {
        wallet = _wallet;
    }

    // function addWhitelistAddr(address _addr) public onlyRole(DEVELOPER) {
    //     whitelisted_tokens[_addr] = true;
    // }

    // function removeWhitelistAddr(address _addr) public onlyRole(DEVELOPER) {
    //     delete whitelisted_tokens[_addr];
    // }

    function setFees(uint256 _fee) external onlyRole(DEVELOPER) {
        fee = _fee;
    }

    function setVoltAddr(address _addr) external onlyRole(DEVELOPER) {
        VOLT = _addr;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() payable external {}
}
