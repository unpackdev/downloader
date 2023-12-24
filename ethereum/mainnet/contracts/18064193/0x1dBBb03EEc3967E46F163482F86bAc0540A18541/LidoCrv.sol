// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";

interface ICurve{ 
    function add_liquidity(uint256[2] calldata amounts,uint256 min_mint_amount) external payable returns(uint256);   

    function lp_token() external view returns(address);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns(uint256);

}
interface ILido {
    function submit(address _referral) external payable returns(uint256);

    function approve(address _spender, uint256 _amount) external ;
}
interface IERC20 {
    function transfer(address receipient, uint256 amount) external returns(bool);

}

contract LidoCrvStaker is Ownable{
    address constant public lido = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address constant public crv = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    uint256 slippageCoeficient = 99;

    function setCoeficient(uint256 _slippageCoeficient) external onlyOwner{
        slippageCoeficient = _slippageCoeficient;
    }

    receive() external payable {
        uint256 depositEthAmount =  msg.value / 2;

        uint256 stEthAmount = ILido(lido).submit{value:depositEthAmount}(0x0000000000000000000000000000000000000000);

        uint256 slippage = ICurve(crv).calc_token_amount([depositEthAmount, stEthAmount],true) * slippageCoeficient / 100;

        ILido(lido).approve(crv, type(uint).max);
               
        uint256 depositEthAmountCopy = depositEthAmount;

        uint256 res = ICurve(crv).add_liquidity{value:depositEthAmount}([depositEthAmountCopy, stEthAmount],slippage);
        address lp_token = ICurve(crv).lp_token();

        IERC20(lp_token).transfer(msg.sender, res);
        
    }
}
