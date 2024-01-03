// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "./IERC20.sol";
import "./SafeMath.sol";

import "./DexHandlerAbstract.sol";
import "./IUniswapV2Router.sol";
/*
 * UniswapV2 Handler 
 */

contract UniswapV2DexHandler is DexHandler { // TODO Add dust collection
    using SafeMath for uint256;

    IUniswapV2Router public uniswapV2Router;

    constructor(address _uniswapV2Router) DexHandler(_uniswapV2Router) public {
        uniswapV2Router = IUniswapV2Router(_uniswapV2Router);
    }


    function swap(bytes memory _data) public returns (uint256 _amountOut) {
        return swap(_data, 0);
    }

    function swap(bytes memory _data, uint256 _amount) public override returns (uint256 _amountOut) {
        return customSwap(_data, _amount);
    }

    function customSwap(bytes memory _data, uint256 _amount) public returns (uint256 _amountOut) {
        (, uint256 _min, address[] memory _path,,) = customDecodeData(_data);
        // Transfer _in tokens to self
        require(IERC20(_path[0]).transferFrom(msg.sender, address(this), _amount), 'uniswapv2-dex-handler::custom-swap:transfer-from-failed');

        IERC20(_path[0]).approve(address(uniswapV2Router), _amount);

        uint[] memory _amounts = uniswapV2Router.swapExactTokensForTokens(
            _amount,
            _min,
            _path,
            msg.sender,
            now.add(1 hours)
        );

        return _amounts[_amounts.length.sub(1)];
    }

    function getAmountOut(bytes memory _data, uint256 _amount) public override view returns (uint256 _amountOut) {
        (,, address[] memory _path,,) = customDecodeData(_data);

        uint256[] memory _amounts = uniswapV2Router.getAmountsOut(_amount, _path);

        return _amounts[_amounts.length.sub(1)];
    }
 
    function decodeData(bytes memory _data) public override pure {
        _data; // silence warning
        require(false, 'use customDecodeData(bytes memory _data) returns (uint256 _amount, uint256 _min, address[] memory _path, address _to, uint256 _expire)');
    }
    function customDecodeData(bytes memory _data) public pure returns (uint256 _amount, uint256 _min, address[] memory _path, address _to, uint256 _expire) {
        return abi.decode(_data, (uint256, uint256, address[], address, uint256));
    }

    function swapData() external override pure returns (bytes memory) {
        require(false, 'use customSwapData(uint256 _amount, uint256 _min, address[] memory _path, address _to, uint256 _expire) returns (bytes memory)');
    }
    function customSwapData(
        uint256 _amount,
        uint256 _min,
        address[] memory _path,
        address _to,
        uint256 _expire
    ) public pure returns (bytes memory) {
        return abi.encode(
            _amount,
            _min,
            _path,
            _to,
            _expire
        );
    }
}