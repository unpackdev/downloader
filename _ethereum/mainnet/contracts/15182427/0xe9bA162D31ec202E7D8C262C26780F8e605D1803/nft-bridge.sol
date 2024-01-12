// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract NFTBridge is Ownable, ReentrancyGuard {
    IERC1155 public refractions;
    address public vault;

    mapping(bytes32 => uint256) public assets;

    function bridge(IERC721[] calldata contractAddresses, uint256[] calldata userTokenIds) external nonReentrant 
    {
        for (uint i=0; i < contractAddresses.length; i++) {
            require(assets[multikey(address(contractAddresses[i]),userTokenIds[i])] != 0, "Invalid asset");
            require(contractAddresses[i].ownerOf(userTokenIds[i]) == msg.sender, "Insufficent ballance");
            require(refractions.balanceOf(vault, assets[multikey(address(contractAddresses[i]),userTokenIds[i])]) >= 1, "Asset not found in vault");

            contractAddresses[i].safeTransferFrom(msg.sender, address(0xDEAD), userTokenIds[i]);
            refractions.safeTransferFrom(vault, msg.sender, assets[multikey(address(contractAddresses[i]),userTokenIds[i])], 1, "");
        }
    }

    function setRefractions(IERC1155 _refractions) external onlyOwner {
        refractions = _refractions;
    }

    function setVault(address _vault) external onlyOwner {
        require(refractions.isApprovedForAll(_vault, address(this)), "Do approve all first");
        vault = _vault;
    }

    function addBridgableAsset(address contractAddress, uint256 originalTokenId, uint256 newTokenId) external onlyOwner
    {
        _addBridgableAsset(contractAddress, originalTokenId, newTokenId);
    }

    function addMultipleBridgableAsset(address[] calldata contractAddress, uint256[] calldata originalTokenId, uint256[] calldata newTokenId) external onlyOwner 
    {
        for (uint i=0; i < contractAddress.length; i++) {
            _addBridgableAsset(contractAddress[i], originalTokenId[i], newTokenId[i]);
        }
    }

    function _addBridgableAsset(address contractAddress, uint256 originalTokenId, uint256 newTokenId) private
    {
        assets[multikey(contractAddress, originalTokenId)] = newTokenId;
    }

    function multikey(address contractAddress, uint256 tokenId) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(contractAddress, tokenId));
    }
}