// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;

pragma experimental ABIEncoderV2;

import "./ITroyNFT.sol";

interface IGegoRuleProxy  {

    struct Cost721Asset{
        uint256 costErc721Id1;
        uint256 costErc721Id2;
        uint256 costErc721Id3;

        address costErc721Origin;
    }

    struct MintParams{
        address user;
        uint256 amount;
        uint256 ruleId;
    }

    function cost( MintParams calldata params) external returns (
        uint256 mintAmount,
        address mintErc20
    ) ;

    function destroy( address owner, ITroyNFT.Gego calldata gego ) external ;

    function generate( address user,uint256 ruleId, uint256 randomNonce ) external view returns ( ITroyNFT.Gego memory gego );

}