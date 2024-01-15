pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./UniSushiV2Library.sol";
import "./AddressArrayUtils.sol";
import "./IWETH.sol";

contract SOFIProxy is Ownable {
    using AddressArrayUtils for address[];

    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant private MAX_UINT96 = 2**96 - 1;

    address public WETH;

    address[] public RouterList;
    mapping(address => bool) public isRouter;

    event TradeInfo(
        address indexed _router, 
        address indexed _sender,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOut,
        address indexed _to
    );

    constructor(
        address _weth
    )
        public
    {
        WETH = _weth;
    }



    receive() external payable {
        require(msg.sender == WETH, "SOFIProxy: Direct deposits not allowed");
    }

    function _safeApprove(IERC20 _token, address _spender, uint256 _requiredAllowance) internal {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _requiredAllowance) {
            _token.safeIncreaseAllowance(_spender, MAX_UINT96 - allowance);
        }
    }

    function _swapExactTokensForTokens(address _router, address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin) internal returns (uint256) {
        if (_tokenIn == _tokenOut) {
            return _amountIn;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return IUniswapV2Router02(_router).swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), block.timestamp)[1];
    }


    function tradeTokenByExactETH(address _router, address _tokenOut, uint256 _amountOutMin, address _to) external payable returns (uint256) {
        require(isRouter[_router], "Router does not exist");
        require(msg.value > 0 && _amountOutMin >= 0, "INVALID INPUTS");
        uint256 _amountOut;
        IWETH(WETH).deposit{value: msg.value}();

        if (_tokenOut == WETH) {
            _amountOut = msg.value;
        } else {
            _safeApprove(IERC20(WETH), _router, msg.value);
            _amountOut = _swapExactTokensForTokens(_router, WETH, _tokenOut, msg.value, _amountOutMin);
        }

        IERC20(_tokenOut).safeTransfer(_to, _amountOut);

        emit TradeInfo(_router, msg.sender, address(0), _tokenOut, msg.value, _amountOut, _to);
        return _amountOut;
    }


    function tradeETHByExactToken(address _router, address _tokenIn, uint256 _amountIn, uint256 _amountOutMin, address _to) external payable returns (uint256) {
        require(isRouter[_router], "Router does not exist");
        require(_amountIn > 0 && _amountOutMin >= 0, "INVALID INPUTSS");
        uint256 _amountOut;
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        
        if (_tokenIn == WETH) {
            _amountOut = _amountIn;
        } else {
            _safeApprove(IERC20(_tokenIn), _router, _amountIn);
            _amountOut = _swapExactTokensForTokens(_router, _tokenIn, WETH, _amountIn, _amountOutMin);
        }

        IWETH(WETH).withdraw(_amountOut);
        (payable(_to)).sendValue(_amountOut);

        emit TradeInfo(_router, msg.sender, _tokenIn, address(0), _amountIn, _amountOut, _to);
        return _amountOut;
    }


    function tradeTokenByExactToken(address _router, address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin,address _to) external returns (uint256) {
        require(isRouter[_router], "Router does not exist");
        require(_tokenIn != _tokenOut && _amountOutMin >= 0, "INVALID INPUTS");

        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);

        _safeApprove(IERC20(_tokenIn), _router, _amountIn);

        uint256 _amountOut = _swapExactTokensForTokens(_router, _tokenIn, _tokenOut, _amountIn, _amountOutMin);

        IERC20(_tokenOut).safeTransfer(_to, _amountOut);

        emit TradeInfo(_router, msg.sender, _tokenIn, _tokenOut, _amountIn, _amountOut, _to);
        return _amountOut;
    }
    

    function _swapTokensForExactTokens(address _router, address _tokenIn, address _tokenOut, uint256 _amountOut, uint256 _amountInMax) internal returns (uint256) {
        if (_tokenIn == _tokenOut) {
            return _amountOut;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return IUniswapV2Router02(_router).swapTokensForExactTokens(_amountOut, _amountInMax, path, address(this), block.timestamp)[0];
    }


    function tradeExactTokenByToken(address _router, address _tokenIn, address _tokenOut, uint256 _amountOut, uint256 _amountInMax, address _to) external returns (uint256) {
        require(isRouter[_router], "Router does not exist");
        require(_tokenIn != _tokenOut, "Same token In && Out");

        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountInMax);

        _safeApprove(IERC20(_tokenIn), _router, _amountInMax);

        uint256 _amountInSpent = _swapTokensForExactTokens(_router, _tokenIn, _tokenOut, _amountOut, _amountInMax);

        IERC20(_tokenOut).safeTransfer(_to, _amountOut);

        uint256 _amountInReturn = _amountInMax.sub(_amountInSpent);
        if (_amountInReturn > 0) {
            IERC20(_tokenIn).safeTransfer(msg.sender,  _amountInReturn);
        }

        emit TradeInfo(_router, msg.sender, _tokenIn, _tokenOut, _amountInSpent, _amountOut, _to);
        return _amountInSpent;
    }

    
    function addRouter(address _routerAddress) external onlyOwner {
        require(!isRouter[_routerAddress], "Router already exists");

        isRouter[_routerAddress] = true;

        RouterList.push(_routerAddress);
    }


    function removeRouter(address _routerAddress) external onlyOwner {
        require(isRouter[_routerAddress], "Router does not exist");

        RouterList = RouterList.remove(_routerAddress);

        isRouter[_routerAddress] = false;
    }


    function getRouters() external view returns (address[] memory) {
        return RouterList;
    }
    

    function getUniV2Routers(uint256 _amountIn, address _tokenIn, address _tokenOut) public view returns (address[] memory, uint256[] memory) {
        require(_tokenIn != _tokenOut, '_tokenIn should not equal _tokenOut');
        require(_amountIn > 0, '_amountIn should > 0');

        
        uint256 routerCount = RouterList.length;
        uint256[] memory amountOutList  = new uint256[](routerCount);

        for (uint i = 0; i < routerCount; i++) {
            address _pair = _getPair(RouterList[i], _tokenIn, _tokenOut);

            if(_pair != address(0)) {
                (uint256 _reserveIn, uint256 _reserveOut) = UniSushiV2Library.getReserves(_pair, _tokenIn, _tokenOut);
                uint256 _amountOut = UniSushiV2Library.getAmountOut(_amountIn, _reserveIn, _reserveOut);
                amountOutList[i] = _amountOut;
            }
        }
        return (RouterList, amountOutList);
    }


    function getMaxAmountOut(uint256 _amountIn, address _tokenIn, address _tokenOut) external view returns (uint256, address, address) {
        require(_amountIn > 0, '_amountIn should > 0');
        if (_tokenIn == _tokenOut) {
            return (_amountIn, address(0), address(0));
        }

        uint256 _maxAmountOut = 0;
        address _maxRouter = address(0);
        address _maxPair = address(0);


        uint256 routerCount = RouterList.length;
        for (uint i = 0; i < routerCount; i++) {

            address _pair = _getPair(RouterList[i] , _tokenIn, _tokenOut);


            if(_pair != address(0)) {
                (uint256 _reserveIn, uint256 _reserveOut) = UniSushiV2Library.getReserves(_pair, _tokenIn, _tokenOut);
                uint256 _amountOut = UniSushiV2Library.getAmountOut(_amountIn, _reserveIn, _reserveOut);
                
                _maxRouter = (_amountOut > _maxAmountOut) ? RouterList[i] : _maxRouter;
                _maxPair = (_amountOut > _maxAmountOut) ? _pair : _maxPair;
                _maxAmountOut = (_amountOut > _maxAmountOut) ? _amountOut : _maxAmountOut;
            }
        }

        return (_maxAmountOut, _maxRouter, _maxPair);
    }


    function getMinAmountIn(uint256 _amountOut, address _tokenIn, address _tokenOut) external view returns (uint256, address, address) {
        require(_amountOut > 0, '_amountOut should > 0');
        if (_tokenIn == _tokenOut) {
            return (_amountOut, address(0), address(0));
        }

        uint256 _minAmountIn = MAX_UINT96;
        address _minRouter = address(0);
        address _minPair = address(0);


        uint256 routerCount = RouterList.length;
        for (uint i = 0; i < routerCount; i++) {

            address _pair = _getPair(RouterList[i] , _tokenIn, _tokenOut);


            if(_pair != address(0)) {
                (uint256 _reserveIn, uint256 _reserveOut) = UniSushiV2Library.getReserves(_pair, _tokenIn, _tokenOut);
    
                if (_reserveOut > _amountOut) {
                uint256 _amountIn = UniSushiV2Library.getAmountIn(_amountOut, _reserveIn, _reserveOut);
                
                _minRouter = (_amountIn < _minAmountIn) ? RouterList[i] : _minRouter;
                _minPair = (_amountIn < _minAmountIn) ? _pair : _minPair;
                _minAmountIn = (_amountIn < _minAmountIn) ? _amountIn : _minAmountIn;
                }
            }
        }

        require(_minAmountIn < MAX_UINT96 && _minAmountIn > 0, "SOFIProxy: LIQUID_INVALID");
        return (_minAmountIn, _minRouter, _minPair);
    }

    
    function _getPair(address _router, address _tokenIn, address _tokenOut) internal view returns (address) {
        address _factory = IUniswapV2Router02(_router).factory();
        return IUniswapV2Factory(_factory).getPair(_tokenIn, _tokenOut);
    }
}