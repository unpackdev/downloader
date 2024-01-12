// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC1155.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

abstract contract BFContract {
    function walletOfOwner(address _owner) public view virtual returns(uint256[] memory);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract BFSP is ERC1155, ERC2981, Ownable, ReentrancyGuard {

    // attributes
    string private tokenUri;
    address public operator;

    mapping(address => uint256) public mintedPerAddress;

    bool public claimableActive = true; 
    
    address public botsContractAddress; 
    mapping(uint256 => bool) public nftClaimed;
    
    // constants
    uint256 constant public MAX_MINT_PER_BLOCK = 150;

    // modifiers
    modifier whenClaimableActive() {
        require(claimableActive, "Claimable state is not active");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender , "Only operator can call this method");
        _;
    }
    
    // events
    event ClaimableStateChanged(bool indexed claimableActive);

    struct NftData {
        uint tokenId;
        bool hasMinted;
    }

    constructor(
        address addresses,        
        address royalty_,
        uint96 royaltyFee_,
        string memory tokenBaseURI_
    ) ERC1155(""){
        botsContractAddress = addresses;
        operator = msg.sender;
        tokenUri = tokenBaseURI_;
        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return tokenUri;
    }
    
    function setBaseURI(string memory newUri) external onlyOperator {
        tokenUri = newUri;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // Methods
    function flipClaimableState() external onlyOperator {
        claimableActive = !claimableActive;
        emit ClaimableStateChanged(claimableActive);
    }

    function checkNftClaimed(address _owner) public view returns( bool[] memory,uint256[] memory) {
        BFContract botsContract = BFContract(botsContractAddress);
        uint256[] memory tokensId = botsContract.walletOfOwner(_owner);

        bool[] memory list = new bool[](tokensId.length);
        uint256[] memory id = new uint256[](tokensId.length);
        for(uint256 i; i < list.length; ++i){
           list[i] = nftClaimed[tokensId[i]];
           id[i] = tokensId[i];
        }
        return (list,id);
    }

    function nftOwnerClaim(uint256[] calldata tokenIds) external whenClaimableActive {
        require(tokenIds.length > 0, "Should claim at least one");
        require(tokenIds.length <= MAX_MINT_PER_BLOCK, "Input length should be <= MAX_MINT_PER_BLOCK");

        claimNFT(tokenIds);
    }

    function claimNFT(uint256[] calldata tokenIds) private {
        for(uint256 i; i < tokenIds.length; ++i){
            uint256 tokenId = tokenIds[i];
            require(!nftClaimed[tokenId], "NFT already claimed");
            require(ERC721(botsContractAddress).ownerOf(tokenId) == msg.sender, "Must own all of the defined by tokenIds");
            
            claimNFTByTokenId(tokenId);    
        }
        claimNFT(tokenIds.length);
    }

    function claimNFTByTokenId(uint256 tokenId) private {
        nftClaimed[tokenId] = true;
    }

    function claimNFT(uint256 amount) private {
        _mint(msg.sender,1, amount,"");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}