//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ZkSyncBridgeSwapper.sol";
import "./IStaticATokenLM.sol";

/**
* @notice Exchanges tokens for their respective static Aave tokens.
* NOTE: to add a new pool, put the underlying token at the even index,
* immediately followed by the static aToken at the odd index.
* Example indexes:
* 0: DAI
* 1: stataDAI
* 2: USDC
* 3: stataUSDC
*/
contract AaveBridgeSwapper is ZkSyncBridgeSwapper {

    address[] public tokens;

    event PoolAdded(address stataToken);

    constructor(
        address _zkSync,
        address _l2Account,
        address[] memory _stataTokens
    )
        ZkSyncBridgeSwapper(_zkSync, _l2Account)
    {
        for (uint i = 0; i < _stataTokens.length; i++) {
            addPool(_stataTokens[i]);
        }
    }

    function exchange(
        uint256 _indexIn,
        uint256 _indexOut,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) 
        onlyOwner
        external 
        override 
        returns (uint256 amountOut) 
    {
        require(_indexIn < tokens.length, "invalid input index");
        require(_indexOut < tokens.length && _indexOut != _indexIn, "invalid output index");

        address inputToken = tokens[_indexIn];
        address outputToken = tokens[_indexOut];

        transferFromZkSync(inputToken);

        if (_indexIn % 2 == 0) { // deposit
            require(_indexOut == _indexIn + 1, "invalid output token");

            IERC20(inputToken).approve(outputToken, _amountIn);
            amountOut = IStaticATokenLM(outputToken).deposit(
                address(this),
                _amountIn,
                0,
                true
            );
        } else { // withdrawal
            require(_indexOut == _indexIn - 1, "invalid output token");

            (, amountOut) = IStaticATokenLM(inputToken).withdraw(
                address(this),
                _amountIn,
                true
            );
        }

        require(amountOut >= _minAmountOut, "slippage");
        transferToZkSync(outputToken, amountOut);
        emit Swapped(inputToken, _amountIn, outputToken, amountOut);
    }

    function addPool(address _stataToken) public onlyOwner {
        require(_stataToken != address(0), "null stataToken");
        address token = address(IStaticATokenLM(_stataToken).ASSET());
        require(token != address(0), "null token");

        tokens.push(token);
        tokens.push(_stataToken);
        assert(tokens.length % 2 == 0);

        emit PoolAdded(_stataToken);
    }
}
