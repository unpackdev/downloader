// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./IERC20.sol";

interface Sushi {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

library SushiSwapExchange {
    address public constant DEX = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function _approve(address _token, uint256 _amount) internal {
        if (IERC20(_token).allowance(address(this), DEX) < _amount) {
            IERC20(_token).approve(DEX, ~uint256(0));
        }
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function swapExactERC20ForERC20(
        address _from,
        address _to,
        address _recipient,
        uint256 _fromAmount,
        uint256 _toAmount
    ) external {
        // approve tokens to the DEX 
        _approve(_from, _fromAmount);

        address[] memory _path = new address[](3);
        _path[0] = _from;
        _path[1] = WETH;
        _path[2] = _to;

        Sushi(DEX).swapExactTokensForTokens(
            IERC20(_from).balanceOf(address(this)),
            _toAmount,
            _path,
            _recipient,
            block.timestamp + 1800
        );
    }

    function swapERC20ForExactERC20(
        address _from,
        address _to,
        address _recipient,
        uint256 _fromAmount,
        uint256 _toAmount
    ) external {
        // approve tokens to the DEX
        _approve(_from, _fromAmount);

        address[] memory _path = new address[](3);
        _path[0] = _from;
        _path[1] = WETH;
        _path[2] = _to;

        Sushi(DEX).swapTokensForExactTokens(
            _toAmount,
            _fromAmount,
            _path,
            _recipient,
            block.timestamp + 1800
        );
    }

    function swapERC20ForExactETH(
        address _from,
        address _recipient,
        uint256 _fromAmount,
        uint256 _toAmount
    ) external {
        // approve tokens to the DEX
        _approve(_from, _fromAmount);

        address[] memory _path = new address[](2);
        _path[0] = _from;
        _path[1] = WETH;

        Sushi(DEX).swapTokensForExactETH(
            _toAmount,
            _fromAmount,
            _path,
            _recipient,
            block.timestamp + 1800
        );
    }

    function swapExactERC20ForETH(
        address _from,
        address _recipient,
        uint256 _fromAmount,
        uint256 _toAmount
    ) external {
        // approve tokens to the DEX
        _approve(_from, _fromAmount);

        address[] memory _path = new address[](2);
        _path[0] = _from;
        _path[1] = WETH;

        Sushi(DEX).swapExactTokensForETH(
            IERC20(_from).balanceOf(address(this)),
            _toAmount,
            _path,
            _recipient,
            block.timestamp + 1800
        );
    }

    function swapETHForExactERC20(
        address _to,
        address _recipient,
        uint256 _fromAmount,
        uint256 _toAmount
    ) external {        
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = _to;

        bytes memory _data = abi.encodeWithSelector(Sushi.swapETHForExactTokens.selector, _toAmount, _path, _recipient, block.timestamp + 1800);

        (bool success, ) = DEX.call{value:_fromAmount}(_data);
        _checkCallResult(success);
    }

    function swapExactETHForERC20(
        address _to,
        address _recipient,
        uint256 _toAmount
    ) external {
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = _to;

        bytes memory _data = abi.encodeWithSelector(Sushi.swapExactETHForTokens.selector, _toAmount, _path, _recipient, block.timestamp + 1800);

        (bool success, ) = DEX.call{value:address(this).balance}(_data);
        _checkCallResult(success);
    }
}