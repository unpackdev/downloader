pragma solidity ^0.5.16;

interface IDfWallet {

    function claimComp(address[] calldata cTokens) external;

    function borrow(address _cTokenAddr, uint _amount) external;

    function setDfFinanceClose(address _dfFinanceClose) external;

    function deposit(
        address _tokenIn, address _cTokenIn, uint _amountIn, address _tokenOut, address _cTokenOut, uint _amountOut
    ) external payable;

    function withdraw(
        address _tokenIn, address _cTokenIn, address _tokenOut, address _cTokenOut
    ) external payable;

    function withdraw(
        address _tokenIn, address _cTokenIn, uint256 amountRedeem, address _tokenOut, address _cTokenOut, uint256 amountPayback
    ) external payable returns(uint256);

    function withdrawToken(address _tokenAddr, address to, uint256 amount) external;

    function redeem(address _tokenAddr, address _cTokenAddr, uint256 amount) external; 

}
