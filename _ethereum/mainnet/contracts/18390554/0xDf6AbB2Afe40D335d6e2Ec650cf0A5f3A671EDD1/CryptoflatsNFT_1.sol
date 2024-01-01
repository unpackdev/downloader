// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ICryptoflatsNFTGen.sol";
import "./ERC721R.sol";

contract CryptoflatsNFT_1 is 
    ICryptoflatsNFTGen,
    ERC721r,
    Ownable,
    ERC2981 
{
    using Strings for uint256;

    IERC721 immutable _WL_BOX;
    uint96 public constant DEFAULT_ROYALTY = 500; // 5%
    uint256 public constant EARLY_ACCESS_PRICE = 0.02 ether;
    uint256 public constant PUBLIC_SALE_PRICE = 0.04 ether;
    uint256 public constant MAX_SUPPLY = 5_555;
    uint256 public immutable gen;
    address payable public teamWallet;
    bytes32 public whitelistFreePurchaseRoot;
    bytes32 public whitelistEarlyAccessRoot;
    mapping(address => bool) public isWhitelistFreePurchaseUserMintedOnce;
    mapping(address => uint256) public getMintCountForEarlyAccessUser;
    mapping(uint256 => bool) public isWlBoxIdUsed;
    
    bool public isPublicSaleActive;

    constructor(
        address payable teamWallet_,
        uint256 gen_,
        IERC721 wlBox
    ) ERC721r("Cryptoflats-Gen1", "CNRS-1", MAX_SUPPLY) {
        gen = gen_;
        teamWallet = teamWallet_;
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTY);
        isPublicSaleActive = false;

        _WL_BOX = wlBox;
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC2981, ERC721r) 
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    function getNFTType(uint256 _id) external view returns (Type) {
        require(_exists(_id), "CNRS-1: Token doesn't exsits");
        return _idToType[_id];
    }


    function setNewTeamWallet(address payable newTeamWallet) 
        external
        onlyOwner {
        emit TeamWalletTransferred(msg.sender, teamWallet, newTeamWallet);
        teamWallet = newTeamWallet;
    }

    function setNewFreePurchaseWhitelistRoot(bytes32 newFreePurchaseWhitelistRoot) 
        external
        onlyOwner {
        emit WhitelistRootChanged(
            msg.sender,
            whitelistFreePurchaseRoot,
            newFreePurchaseWhitelistRoot,
            "Free Purchase"
        );
        whitelistFreePurchaseRoot = newFreePurchaseWhitelistRoot;
        
    }

    function setNewEarlyAccessWhitelistRoot(bytes32 newEarlyAccessWhitelistRoot) external onlyOwner {
        emit WhitelistRootChanged(
            msg.sender,
            whitelistFreePurchaseRoot,
            newEarlyAccessWhitelistRoot,
            "Early Access"
        );
        whitelistEarlyAccessRoot = newEarlyAccessWhitelistRoot;
    }


    function baseURI() 
        public
        pure
        returns (string memory) {
        return "ipfs://Qmdcu9B98EAATgc1i9c1qADRJf6ucPrnQ5iW6PGCY9masq/";
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory) {
        require(_exists(_tokenId), "CNRS-1: URI query for nonexistent token");
        string memory baseUri = baseURI();
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json")) : "";
    }

    function mint(
        bytes32[] calldata whitelistFreePurchaseProof,
        bytes32[] calldata whitelistEarlyAccessProof,
        uint256 wlBoxId
    ) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (isUserFreePurchaseWhitelist(whitelistFreePurchaseProof, msg.sender, wlBoxId) == true) {
            if(wlBoxId < MAX_SUPPLY) {
                require(_WL_BOX.ownerOf(wlBoxId) == msg.sender, "CNRS-1: not wl box owner");
                isWlBoxIdUsed[wlBoxId] = true;
            }

            isWhitelistFreePurchaseUserMintedOnce[msg.sender] = true;
        } else if (isUserEarlyAccessWhitelist(whitelistEarlyAccessProof, msg.sender) == true) {
            require(msg.value >= EARLY_ACCESS_PRICE, "CNRS-1: Insufficient funds");
            getMintCountForEarlyAccessUser[msg.sender]++;
        } else {
            require(isPublicSaleActive == true, "CNRS-1: Public sale is inactive!");
            require(msg.value >= PUBLIC_SALE_PRICE, "CNRS-1: Insufficient funds");
        }

        _mintRandom(msg.sender, 1);
    }


    function isUserFreePurchaseWhitelist(
        bytes32[] calldata whitelistMerkleProof,
        address account,
        uint256 wlBoxId
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        
        if(isWhitelistFreePurchaseUserMintedOnce[account] == true) {
            return false;
        }

        uint256 balanceWlBox = _WL_BOX.balanceOf(msg.sender);
        if(isWlBoxIdUsed[wlBoxId] == true)
        {
            return false;
        }
        
        if(isWhitelistFreePurchaseUserMintedOnce[account] == false && balanceWlBox > 0){
            return true;
        }

        return MerkleProof.verify(
            whitelistMerkleProof,
            whitelistFreePurchaseRoot,
            leaf
        );
    }

    function isUserEarlyAccessWhitelist(
        bytes32[] calldata whitelistMerkleProof,
        address account
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));

        if(getMintCountForEarlyAccessUser[account] >= 2) {
            return false;
        }

        return MerkleProof.verify(
            whitelistMerkleProof,
            whitelistEarlyAccessRoot,
            leaf
        );
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
        returns (bool) {
        uint256 balance = address(this).balance;
        require(balance > 0, "CNRS-1: zero balance");
        
        (bool sent, bytes memory data) = teamWallet.call{value: balance}("");
        require(sent, "CNRS-1: Failed to send Ether");
        
        return sent;
    }
}
