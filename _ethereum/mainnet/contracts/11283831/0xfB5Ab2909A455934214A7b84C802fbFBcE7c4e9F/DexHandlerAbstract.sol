// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./IDexHandler.sol";
/*
 * DexHandlerAbstract 
 */

abstract
contract DexHandler is IDexHandler {
    using SafeMath for uint256;
    using Address for address;

    address public dex;

    constructor(address _dex) public {
        require(_dex.isContract(), 'dex-handler::constructor:dex-is-not-a-contract');
        dex = _dex;
    }

    function isDexHandler() external override view returns (bool) {
        return true;
    }
    
    function swap(bytes memory _data, uint256 _amount) public virtual override returns (uint256 _amountOut) {}
    function getAmountOut(bytes memory _data, uint256 _amount) public virtual override view returns (uint256 _amountOut) {}
    function swapData() external virtual override pure returns (bytes memory) {}
    function decodeData(bytes memory _data) public virtual pure;
}
