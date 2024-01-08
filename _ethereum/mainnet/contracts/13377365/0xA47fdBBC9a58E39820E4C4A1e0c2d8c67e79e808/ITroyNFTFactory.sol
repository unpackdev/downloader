// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;

pragma experimental ABIEncoderV2;

import "./ITroyNFT.sol";

interface ITroyNFTFactory {

    function getGego(uint256 tokenId)
        external view
        returns (
            uint256 grade,
            uint256 quality,
            uint256 amount,
            uint256 resBaseId,
            uint256 tLevel,
            uint256 ruleId,
            uint256 nftType,
            address author,
            address erc20,
            uint256 createdTime,
            uint256 blockNum,
            uint256 lockedDays
        );


    function getGegoStruct(uint256 tokenId)
        external view
        returns (ITroyNFT.Gego memory gego);

    function burn(uint256 tokenId) external returns ( bool );
    
    function isRulerProxyContract(address proxy) external view returns ( bool );
}