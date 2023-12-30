pragma solidity ^0.5.17;

contract ERC20
{
    function balanceOf(address _holder) public returns (uint);
    function burn(uint _balanceToBurn) public;
}

contract BurnBot
{
    function burnTotalBalance(ERC20 erc20)
        public
    {
        uint balance = erc20.balanceOf(address(this));
        erc20.burn(balance);
    }
}