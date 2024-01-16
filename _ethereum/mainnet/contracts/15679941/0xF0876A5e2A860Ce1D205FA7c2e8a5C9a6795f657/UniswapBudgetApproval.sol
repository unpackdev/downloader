// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "./CommonBudgetApproval.sol";
import "./BytesLib.sol";
import "./UniswapSwapper.sol";
import "./Constant.sol";

import "./PriceResolver.sol";
import "./IBudgetApprovalExecutee.sol";

contract UniswapBudgetApproval is CommonBudgetApproval, UniswapSwapper, PriceResolver {

    using BytesLib for bytes;

    event AllowToToken(address token);
    event ExecuteUniswapInTransaction(uint256 indexed id, address indexed executor, address indexed toAddress, address token, uint256 amount);
    event ExecuteUniswapOutTransaction(uint256 indexed id, address indexed executor, address indexed toAddress, address token, uint256 amount);
    event ExecuteWETH9Transaction(uint256 indexed id, address indexed executor, address indexed toAddress, address tokenIn, address tokenOut, uint256 amount);

    string public constant override name = "Uniswap Budget Approval";

    address[] public fromTokens;
    mapping(address => bool) public fromTokensMapping;
    bool public allowAnyAmount;
    uint256 public totalAmount;
    uint8 public amountPercentage;
    bool public allowAllToTokens;
    mapping(address => bool) public toTokensMapping;

    mapping(uint256 => mapping(address => uint256)) private _tokenInAmountOfTransaction;
    mapping(uint256 => address[]) private _tokenInOfTransaction;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(
        InitializeParams calldata params,
        address[] memory _fromTokens,
        bool _allowAllToTokens,
        address[] calldata _toTokens,
        bool _allowAnyAmount,
        uint256 _totalAmount,
        uint8 _amountPercentage,
        address _baseCurrency
    ) external initializer {
        __BudgetApproval_init(params);
        
        for(uint i = 0; i < _fromTokens.length; i++) {
            _addFromToken(_fromTokens[i]);
        }

        allowAllToTokens = _allowAllToTokens;
        for(uint i = 0; i < _toTokens.length; i++) {
            _addToToken(_toTokens[i]);
        }

        allowAnyAmount = _allowAnyAmount;
        totalAmount = _totalAmount;
        amountPercentage = _amountPercentage;

        __PriceResolver_init(_baseCurrency);

    }

    function afterInitialized() external override onlyExecutee {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", Constant.UNISWAP_ROUTER, type(uint256).max);
        address _executee = executee();
        uint _fromTokenLength = fromTokens.length;

        for(uint i = 0; i < _fromTokenLength; i++) {
            address _fromToken = fromTokens[i];

            if(_fromToken != Denominations.ETH) {
                IBudgetApprovalExecutee(_executee).executeByBudgetApproval(_fromToken, data, 0);
            }
        }
    }

    function executeParams() external pure override returns (string[] memory) {
        string[] memory arr = new string[](3);
        arr[0] = "address to";
        arr[1] = "bytes data";
        arr[2] = "uint256 value";
        return arr;
    }

    function _execute(
        uint256 transactionId, 
        bytes memory data
    ) internal override {
        (address to, bytes memory executeData, uint256 value) = abi.decode(data,(address, bytes, uint256));
        
        if (to == Constant.UNISWAP_ROUTER) {
            _executeUniswapCall(transactionId, to, executeData, value);
        } else if (to == WETH9()) {
            _executeWETH9Call(transactionId, to, executeData, value);
        } else {
            revert("Invalid target address");
        }
    }

    function _executeUniswapCall(uint256 transactionId, address to, bytes memory executeData, uint256 value) private {
        uint256 priceBefore = _fromTokensPrice();
        address __executee = executee();

        bytes memory response = IBudgetApprovalExecutee(__executee).executeByBudgetApproval(to, executeData, value);
        MulticallData[] memory mDataArr = this.decodeUniswapMulticall(executeData, value, response);

        address[] storage _tokenIn = _tokenInOfTransaction[transactionId];
        mapping(address => uint256) storage _tokenInAmountMapping = _tokenInAmountOfTransaction[transactionId];

        for (uint i = 0; i < mDataArr.length; i++) {
            MulticallData memory mData = mDataArr[i];

            require(mData.recipient == address(0) || 
                mData.recipient == RECIPIENT_EXECUTEE || 
                mData.recipient == RECIPIENT_UNISWAP_ROUTER || 
                mData.recipient == __executee, "Recipient not whitelisted");

            uint256 _tokenInAmount = _tokenInAmountMapping[mData.tokenIn];

            if (mData.amountIn > 0) {
                require(fromTokensMapping[mData.tokenIn], "Source token not whitelisted");

                if (_tokenInAmount == 0) {
                    _tokenIn.push(mData.tokenIn);
                }
                _tokenInAmountMapping[mData.tokenIn] = _tokenInAmount + mData.amountIn;

                emit ExecuteUniswapInTransaction(transactionId, msg.sender, Constant.UNISWAP_ROUTER, mData.tokenIn, mData.amountIn);
            }

            if (mData.amountOut > 0 && (mData.recipient == RECIPIENT_EXECUTEE || mData.recipient == __executee)) {
                require(allowAllToTokens || toTokensMapping[mData.tokenOut], "Target token not whitelisted");

                emit ExecuteUniswapOutTransaction(transactionId, msg.sender, Constant.UNISWAP_ROUTER, mData.tokenOut, mData.amountOut);
            }
        }

        bool _allowAnyAmount = allowAnyAmount;
        uint256 _totalAmount = totalAmount;

        if (!_allowAnyAmount || amountPercentage < 100) {
            uint256 amountInPrice;
            uint _tokenInLength = _tokenIn.length;

            for (uint i = 0; i < _tokenInLength; i++) {
                address tokenIn = _tokenIn[i];
                amountInPrice += assetBaseCurrencyPrice(tokenIn, _tokenInAmountMapping[tokenIn]);
            }
            require(amountInPrice > 0 , "Swap amount should not be zero");
            require(_allowAnyAmount || amountInPrice <= _totalAmount, "Exceeded max amount");
            require(_checkAmountPercentageValid(priceBefore, amountInPrice), "Exceeded percentage");     
                        
            if(!allowAnyAmount) {
                totalAmount = _totalAmount - amountInPrice;
            }           
        }

    }

    function _executeWETH9Call(uint256 transactionId, address to, bytes memory executeData, uint256 value) private {
        uint256 priceBefore = _fromTokensPrice();
        bool _allowAnyAmount = allowAnyAmount;
        uint256 _totalAmount = totalAmount;

        IBudgetApprovalExecutee(executee()).executeByBudgetApproval(to, executeData, value);
        (
            address tokenIn,
            address tokenOut,
            uint256 amount
        ) = this.decodeWETH9Call(executeData, value);

        uint256 amountInPrice = assetBaseCurrencyPrice(tokenIn, amount);
        require(fromTokensMapping[tokenIn], "Source token not whitelisted");
        require(allowAllToTokens || toTokensMapping[tokenOut], "Target token not whitelisted");
        require(amountInPrice > 0 , "Transfer amount should not be zero");
        require(_allowAnyAmount || amountInPrice <= _totalAmount, "Exceeded max amount");
        require(_checkAmountPercentageValid(priceBefore, amountInPrice), "Exceeded percentage");
        
        if(!_allowAnyAmount) {
            totalAmount = _totalAmount - amountInPrice;
        }

        emit ExecuteWETH9Transaction(transactionId, msg.sender, WETH9(), tokenIn, tokenOut, amount);
    }

    function _fromTokensPrice() private view returns (uint256 totalBalance) {
        uint _fromTokenLength = fromTokens.length;
        address _executee = executee();

        for (uint i = 0; i < _fromTokenLength; i++) {
            address _fromToken = fromTokens[i];
            if (_fromToken == Denominations.ETH) {
                totalBalance += assetBaseCurrencyPrice(Denominations.ETH, _executee.balance);
            } else {
                totalBalance += assetBaseCurrencyPrice(_fromToken, IERC20(_fromToken).balanceOf(_executee));
            }
        }
    }

    function _checkAmountPercentageValid(uint256 totalBalance, uint256 amount) private view returns (bool) {
        uint8 _amountPercentage = amountPercentage;

        if (_amountPercentage == 100) return true;

        if (totalBalance == 0) return false;

        return amount <= totalBalance * _amountPercentage / 100;
    }

    function _addFromToken(address token) private {
        require(!fromTokensMapping[token], "Duplicated token");
        require(canResolvePrice(token), "Unresolvable token");
        fromTokens.push(token);
        fromTokensMapping[token] = true;
        emit AllowToken(token);
    }

    function _addToToken(address token) private {
        require(!toTokensMapping[token], "Duplicated token");
        toTokensMapping[token] = true;
        emit AllowToToken(token);
    }

}