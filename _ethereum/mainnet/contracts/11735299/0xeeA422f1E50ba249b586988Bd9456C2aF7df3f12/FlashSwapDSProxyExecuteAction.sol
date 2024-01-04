//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

import "./IFlashSwapResolver.sol";

interface IDSProxy{

    function execute(address _target, bytes calldata _data)
        external
        payable;

}

contract FlashSwapDSProxyExecuteAction is IFlashSwapResolver{

    function resolveUniswapV2Call(
        address sender,
        address tokenRequested,
        address tokenToReturn,
        uint256 amountRecived,
        uint256 amountToReturn,
        bytes calldata _data
        ) external payable override{

        ( address dsProxy, address target, bytes memory datacall ) = abi.decode(_data, (address, address, bytes));

        IDSProxy(dsProxy).execute(
            target,
            datacall
        );
    }
}