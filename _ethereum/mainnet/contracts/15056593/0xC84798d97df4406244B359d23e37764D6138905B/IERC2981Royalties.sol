// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC2981Royalties {

///@dev returns royaltyInfo as defined in EIP2981
///@param _tokenId defines royalties at the token level
///@param _value defines the price that the token has been sold for (regardless of it being ETH or an ERC20)
    function royaltyInfo(uint256 _tokenId, uint256 _value) external view
        returns (address _receiver, uint256 _royaltyAmount);
    
}