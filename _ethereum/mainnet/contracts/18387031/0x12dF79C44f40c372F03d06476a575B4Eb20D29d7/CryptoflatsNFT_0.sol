// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ICryptoflatsNFTGen0.sol";
import "./ERC721RPass.sol";


contract CryptoflatsNFT_0 is 
    ICryptoflatsNFTGen0,
    ERC721rPass,
    Ownable,
    ERC2981 
{
    using Strings for uint256;

    uint96 public constant DEFAULT_ROYALTY = 500; // 5%
    uint256 public constant PUBLIC_SALE_PRICE = 0.015 ether;
    uint256 public constant MAX_SUPPLY = 1_111;
    uint256 public immutable gen;
    address payable public teamWallet;
    bool public isPublicSaleActive;

    constructor(
        address payable teamWallet_,
        uint256 gen_
    ) ERC721rPass("Cryptoflats-Gen0", "CNRS-0", MAX_SUPPLY) {
        gen = gen_;
        teamWallet = teamWallet_;
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTY);
        isPublicSaleActive = false;
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC2981, ERC721rPass) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }


    function getNFTType(uint256 _id) external view returns (Type) 
    {
        require(_exists(_id), "CNRS: Token doesn't exsits");
        return _idToType[_id];
    }


    function setNewTeamWallet(address payable newTeamWallet) 
        external
        onlyOwner 
    {
        emit TeamWalletTransferred(msg.sender, teamWallet, newTeamWallet);
        teamWallet = newTeamWallet;
    }



    function baseURI() 
        public
        pure
        returns (string memory) 
    {
        return "ipfs://QmaswQ5i1CJUcPUY1CmJm5fhVpqPQWoGvZz7pG4WeMMUe6/";
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory) 
    {
        require(_exists(_tokenId), "CNRS-0: URI query for nonexistent token");
        string memory baseUri = baseURI();
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json")) : "";
    }

    function mint() external payable 
    {
        require(isPublicSaleActive == true, "CNRS-0: Public sale is inactive!");
        require(msg.value >= PUBLIC_SALE_PRICE, "CNRS-0: Insufficient funds");

        _mintRandom(msg.sender, 1);
    }


    function setTokenRarityByIds(
        uint256[] calldata tokenIds,
        Type rarity
    ) external onlyOwner
    {
        for(uint256 i = 0; i < tokenIds.length;)
        {
            _idToType[tokenIds[i]] = rarity;
            unchecked { ++i; }
        }
    }


    function activatePublicSale() external onlyOwner
    {
        isPublicSaleActive = true;
    }

    function deactivatePublicSale() external onlyOwner
    {
        isPublicSaleActive = false;
    }

    // withdraw method
    function withdrawBalance()
        external
        onlyOwner
        returns (bool) 
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "CNRS-0: zero balance");
        
        (bool sent, bytes memory data) = teamWallet.call{value: balance}("");
        require(sent, "CNRS-0: Failed to send Ether");
        
        return sent;
    }
}
