// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./ILendFacet.sol";
interface ILendModule {
    enum ReplacementLiquidityType{
         Default,
         Stake
    }
    event SubmitOrder(address indexed submitor, ILendFacet.LendInfo lendInfo);
    event LiquidateOrder(address indexed liquidator, ILendFacet.LendInfo lendInfo);
    event ReplacementLiquidity(ReplacementLiquidityType _type,address _debtor,uint24 _fee,int24 _tickLower,int24 _tickUpper,uint256 _tokenId,uint128 _newLiquidity);
    function submitOrder(
        ILendFacet.LendInfo memory _lendInfo,
        bytes calldata _debtorSignature,
        bytes calldata _loanerSignature
    ) external;
    function liquidateOrder(address _debtor,bool _type) external;
    function replacementLiquidity(address _holder,ReplacementLiquidityType _type,uint24 _fee,int24 _tickLower,int24 _tickUpper) external;
}
