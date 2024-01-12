//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ZkSyncBridgeSwapper.sol";
import "./IYearnVault.sol";

/**
* @notice Exchanges tokens for their respective Yearn vault tokens.
* NOTE: to add a new vault, put the underlying token at the even index,
* immediately followed by the vault token at the odd index.
* Example indexes:
* 0: DAI
* 1: yvDAI
* 2: USDC
* 3: yvUSDC
*/
contract YearnBridgeSwapper is ZkSyncBridgeSwapper {

    address[] public tokens;

    event VaultAdded(address yvToken);

    constructor(address _zkSync, address _l2Account, address[] memory _yvTokens) ZkSyncBridgeSwapper(_zkSync, _l2Account) {
        for (uint i = 0; i < _yvTokens.length; i++) {
            addVault(_yvTokens[i]);
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
            amountOut = IYearnVault(outputToken).deposit(_amountIn);
        } else { // withdrawal
            require(_indexOut == _indexIn - 1, "invalid output token");

            amountOut = IYearnVault(inputToken).withdraw(_amountIn);
        }

        require(amountOut >= _minAmountOut, "slippage");
        transferToZkSync(outputToken, amountOut);
        emit Swapped(inputToken, _amountIn, outputToken, amountOut);
    }

    function addVault(address _yvToken) public onlyOwner {
        require(_yvToken != address(0), "null yvToken");
        address token = IYearnVault(_yvToken).token();
        require(token != address(0), "null token");

        tokens.push(token);
        tokens.push(_yvToken);
        assert(tokens.length % 2 == 0);

        emit VaultAdded(_yvToken);
    }
}
