// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./INFTLight.sol";

contract Vault {
    using SafeMath for uint256;

    mapping(uint256 => uint256) public tokenBalances;

    address public erc20TokenAddress;
    address public nftTokenAddress;

    // Define the constructor
    constructor(address _erc20TokenAddress, address _nftTokenAddress) {
        erc20TokenAddress = _erc20TokenAddress;
        nftTokenAddress = _nftTokenAddress;
    }

    function balanceOf(uint256 _nftId) public view returns (uint256) {
        return tokenBalances[_nftId];
    }

    function deposit(uint256 _nftId, uint256 _tokenAmount) public {
        require(INFTLight(nftTokenAddress).exists(_nftId), "NFT DOES NOT EXIST");
        IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
        tokenBalances[_nftId] = tokenBalances[_nftId].add(_tokenAmount);
    }

    function bulkDeposit(uint256[] memory _nftIds, uint256[] memory _tokenAmounts) public returns (bool) {
        require(_nftIds.length == _tokenAmounts.length, "ARRAY SIZE MISMATCH");

        for (uint256 i = 0; i < _nftIds.length; i++) {
            deposit(_nftIds[i], _tokenAmounts[i]);
        }

        return true;
    }

    function withdrawAll(uint256 _nftId) public returns (bool) {
        address ownerOfNft = INFTLight(nftTokenAddress).ownerOf(_nftId);
        require(msg.sender == ownerOfNft, "NOT OWNER");

        INFTLight(nftTokenAddress).burn(_nftId);

        if (tokenBalances[_nftId] > 0) {
            IERC20(erc20TokenAddress).transfer(ownerOfNft, tokenBalances[_nftId]);
        }

        tokenBalances[_nftId] = 0;

        return true;
    }
}
