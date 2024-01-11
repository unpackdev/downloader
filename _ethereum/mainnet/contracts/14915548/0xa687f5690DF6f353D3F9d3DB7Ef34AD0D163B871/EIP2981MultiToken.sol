// SPDX-License-Identifier: MIT

/**
*   @title EIP 2981 base contract
*   @notice EIP 2981 implementation for differing royalties based on token number
*   @author Transient Labs, LLC
*/

/*
   ___                            __  __          ______                  _          __    __        __     
  / _ \___ _    _____ _______ ___/ / / /  __ __  /_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / ___/ _ \ |/|/ / -_) __/ -_) _  / / _ \/ // /   / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/   \___/__,__/\__/_/  \__/\_,_/ /_.__/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/
                                        /___/                                                               
*/

pragma solidity ^0.8.9;

import "ERC165.sol";
import "IEIP2981.sol";

contract EIP2981MultiToken is IEIP2981, ERC165 {

    mapping(uint256 => address) internal royaltyAddr;
    mapping(uint256 => uint256) internal royaltyPerc; // percentage in basis (out of 10,000)

    /**
    *   @notice EIP 2981 royalty support
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view virtual override returns (address receiver, uint256 royaltyAmount) {
        return (royaltyAddr[_tokenId], royaltyPerc[_tokenId] * _salePrice / 10000);
    }

    /**
    *   @notice override ERC 165 implementation of this function
    *   @dev if using this contract with another contract that suppports ERC 165, will have to override in the inheriting contract
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    *   @notice function to set royalty information for a token
    *   @dev to be called by inheriting contract
    *   @param _tokenId is the token id
    *   @param _addr is the royalty payout address for this token id
    *   @param _perc is the royalty percentage (out of 10,000) to set for this token id
    */
    function setRoyaltyInfo(uint256 _tokenId, address _addr, uint256 _perc) internal virtual {
        require(_addr != address(0), "EIP2981MultiToken: Cannot set royalty receipient to the zero address");
        require(_perc < 10000, "EIP2981MultiToken: Cannot set royalty percentage above 10000");
        royaltyAddr[_tokenId] = _addr;
        royaltyPerc[_tokenId] = _perc;
    }
}