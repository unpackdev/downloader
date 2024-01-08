//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import "./IAdapter.sol";
import "./Whitelistable.sol";

import "./IUniswapV2Router.sol";
import "./IUniswapV3Router.sol";
import "./IQuoter.sol";

interface IGenericRouter {
    function settleTransfer(address token, address to) external;

    function settleSwap(
        address adapter,
        address tokenIn,
        address tokenOut,
        address from,
        address to
    ) external;
}

/// @title Token Sets Vampire Attack Contract
/// @author Enso.finance (github.com/EnsoFinance)
/// @notice Adapter for redeeming the underlying assets from Token Sets

abstract contract AbstractAdapter is IAdapter, Whitelistable {
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant SUSHI = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant UNI_V2 = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    address public constant UNI_V3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    /**
    * @dev Require exchange registered
    */
    modifier onlyExchange(address _exchange) {
        require(isExchange(_exchange), "AbstractAdapter#buy: should be exchanges");
        _;
    }

    constructor(address owner_) {
        _setOwner(owner_);
    }

    function outputTokens(address _lp)
        public
        view
        override
        virtual
        returns (address[] memory outputs);

    function encodeMigration(address _genericRouter, address _strategy, address _lp, uint256 _amount)
        public
        override
        virtual
        view
        returns (Call[] memory calls);

    function encodeWithdraw(address _lp, uint256 _amount)
        public
        override
        virtual
        view
        returns (Call[] memory calls);

    function buy(address _lp, address _exchange, uint256 _minAmountOut, uint256 _deadline)
        public
        override
        virtual
        payable
        onlyExchange(_exchange)
        onlyWhitelisted(_lp)
    {
        if (_exchange == UNI_V3) {
            _buyV3(_lp, _minAmountOut, _deadline);
        } else {
            _buyV2(_lp, _exchange, _minAmountOut, _deadline);
        }
    }

    function getAmountOut(
        address _lp,
        address _exchange,
        uint256 _amountIn
    )
        external
        override
        virtual
        onlyExchange(_exchange)
        onlyWhitelisted(_lp)
        returns (uint256)
    {
        if (_exchange == UNI_V3) {
            return _getV3(_lp, _amountIn);
        } else {
            return _getV2(_lp, _exchange, _amountIn);
        }
    }

    function _buyV2(
        address _lp,
        address _exchange,
        uint256 _minAmountOut,
        uint256 _deadline
    )
        internal
    {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _lp;
        IUniswapV2Router(_exchange).swapExactETHForTokens{value: msg.value}(
            _minAmountOut,
            path,
            msg.sender,
            _deadline
        );
    }

    function _buyV3(
        address _lp,
        uint256 _minAmountOut,
        uint256 _deadline
    )
        internal
    {
        IUniswapV3Router(UNI_V3).exactInputSingle{value: msg.value}(IUniswapV3Router.ExactInputSingleParams(
          WETH,
          _lp,
          3000,
          msg.sender,
          _deadline,
          msg.value,
          _minAmountOut,
          0
        ));
    }

    function _getV2(address _lp, address _exchange, uint256 _amountIn)
        internal
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _lp;
        return IUniswapV2Router(_exchange).getAmountsOut(_amountIn, path)[1];
    }

    function _getV3(address _lp, uint256 _amountIn)
        internal
        returns (uint256)
    {

        return IQuoter(QUOTER).quoteExactInputSingle(
            WETH,
            _lp,
            3000,
            _amountIn,
            0
        );
    }

    /**
    * @param _lp to view pool token
    * @return if token in whitelist
    */
    function isWhitelisted(address _lp)
        public
        view
        override
        returns(bool)
    {
        return whitelisted[_lp];
    }

    function isExchange(address _exchange)
        public
        pure
        returns (bool)
    {
        return(_exchange == SUSHI || _exchange == UNI_V2 || _exchange == UNI_V3);
    }
}
