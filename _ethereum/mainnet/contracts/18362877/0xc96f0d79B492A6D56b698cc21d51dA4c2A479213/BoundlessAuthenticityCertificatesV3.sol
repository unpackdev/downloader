// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BoundlessAuthenticityCertificatesV2.sol";
import "./BoundlessAuthenticityCertificates.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";
import "./Base64.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906  {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

contract BoundlessAuthenticityCertificatesV3 is
    BoundlessAuthenticityCertificates,
    BoundlessAuthenticityCertificatesV2,
    IERC4906
{

    bytes private constant HTML_START  = '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>Image Display</title><style>body{margin:0;padding:0}#container{position:relative;width:100vw;height:auto}#loadedImage,#boundlessId,#size,#tokenId{position:absolute;color:white;font-family:sans-serif}#loadedImage{top:36%;left:50%;transform:translate(-50%,-50%);width:50vw;height:auto}#boundlessId{top:56.5%;left:32.6%;font-size:4vmin}#size,#tokenId{font-size:2.1vmin}#size{top:65.45%;left:12.7%}#tokenId{top:76.6%;left:17.7%}</style></head><body><script>const boundlessId=';
    bytes private constant HTML_MID = ',tokenId=boundlessId+1000000,printSize="';
    bytes private constant HTML_END = '",printSizeString=printSize==="small"?"20 x 25 cm (7.87 x 9.84 in)":"40 x 45 cm (15.74 x 17.71 in)";async function loadImage(){try{const response=await fetch(`https://v2-liveart.mypinata.cloud/ipfs/QmajnUwwipscPeqH9s8BvJBrNCuEWc2VMJa1YZiQj998A5/${tokenId}`),data=await response.json();document.getElementById("loadedImage").src=data.image;document.getElementById("boundlessId").textContent=boundlessId;document.getElementById("tokenId").textContent=boundlessId;document.getElementById("size").textContent=printSizeString}catch(error){console.error("Error:",error)}}loadImage();</script><div id="container"><h2 id="boundlessId"></h2><h3 id="size">the size will go here</h3><h3 id="tokenId">Token ID</h3><img id="baseCertificate" width="100%" src="https://v2-liveart.mypinata.cloud/ipfs/QmRREMtjb8AMnDjbQgd21v5eiwVK9SVABVyg4VXs6abHUk" alt="Boundless Preview"><img id="loadedImage" alt="Loaded Image"></div></body></html>';

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, BoundlessAuthenticityCertificatesV2) returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenNotFound();
        }
        string memory printSize = getCertificatePrintSize(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "Certificate of Authenticity for Boundless NFT ',
                        Strings.toString(tokenId),
                        '",',
                        '"image": ""',
                        '"animation_url": "',
                        HTML_START,
                        Strings.toString(tokenId),
                        HTML_MID,
                        printSize,
                        HTML_END,
                        '",',
                        '"properties": { "artistName": "Yue Minjun" },',
                        '"description": "Yue Minjun\'s NFT Boundless collection transitions from digital to physical with a unique collection of signed prints backed by an NFT Certificate of Authenticity",',
                        '"nft_contract_address": "0x8A27d3f7F42C7B43051e12C150e2A75E9181bFF3"',
                        "}"
                    )
                )
            )
            
        );

        return metadata;
    }

    function updateMetadata() external onlyAdmin {
        emit BatchMetadataUpdate(1, 999);
    }
}
