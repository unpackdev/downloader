// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./Unwindooor.sol";
import "./IUniV2Factory.sol";

/// @notice Contract for selling received tokens into weth. Deploy on secondary networks.
contract WethMaker is Unwindooor {

    event SetBridge(address indexed token, address bridge);

    address public immutable weth;
    IUniV2Factory public immutable factory;

    mapping(address => address) public bridges;

    constructor(address _owner, address _user, address _factory, address _weth) Unwindooor(_owner, _user) {
        factory = IUniV2Factory(_factory);
        weth = _weth;
    }

    function setAllowedBridge(address _token, address _bridge) external onlyOwner {
        bridges[_token] = _bridge;
        emit SetBridge(_token, _bridge);
    }

    // Exchange token for weth or its bridge token (which gets converted into weth in subsequent transactions).
    function buyWeth(
        address[] calldata tokens,
        uint256[] calldata amountsIn,
        uint256[] calldata minimumOuts
    ) external onlyTrusted {
        for (uint256 i = 0; i < tokens.length; i++) {

            address tokenIn = tokens[i];
            address outToken = bridges[tokenIn] == address(0) ? weth : bridges[tokenIn];
            if (_swap(tokenIn, outToken, amountsIn[i], address(this)) < minimumOuts[i]) revert SlippageProtection();
            
        }
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to
    ) internal returns (uint256 outAmount) {
        
        IUniV2 pair = IUniV2(factory.getPair(tokenIn, tokenOut));
        IERC20(tokenIn).transfer(address(pair), amountIn);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (tokenIn < tokenOut) {

            outAmount = _getAmountOut(amountIn, reserve0, reserve1);
            pair.swap(0, outAmount, to, "");

        } else {

            outAmount = _getAmountOut(amountIn, reserve1, reserve0);
            pair.swap(outAmount, 0, to, "");

        }

    }

    // Allow the owner to withdraw the funds and bridge them to mainnet.
    function withdraw(address _token, address _to, uint256 _value) onlyOwner virtual external {
        if (_token != address(0)) {
            _safeTransfer(_token, _to, _value);
        } else {
            (bool success, ) = _to.call{value: _value}("");
            require(success);
        }
    }

}
