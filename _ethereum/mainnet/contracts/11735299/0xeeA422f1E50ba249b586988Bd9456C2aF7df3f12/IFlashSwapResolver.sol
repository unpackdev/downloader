pragma solidity >=0.6.0 <0.8.0;

interface IFlashSwapResolver{

    /**
    @param sender The address who calls IUniswapV2Pair.swap.
    @param tokenRequested The address of the token that was requested to IUniswapV2Pair.swap.
    @param tokenToReturn The address of the token that should be returned to IUniswapV2Pair(msg.sender).
    @param amountRecived The ammount recived of tokenRequested.
    @param amountToReturn The ammount recived of tokenRequested.
    @param _data dataForResolveUniswapV2Call: check FlashSwapProxy.uniswapV2Call documentation
     */
    function resolveUniswapV2Call(
            address sender,
            address tokenRequested,
            address tokenToReturn,
            uint256 amountRecived,
            uint256 amountToReturn,
            bytes calldata _data
            ) external payable;
}
