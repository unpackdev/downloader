// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./ERC721A.sol";
import "./VerifySignature.sol";

error ExceedsMaxSupply();
error ExceedsMaxPerAddress();
error SignatureNotValid();
error SenderMustBeOrigin();
error WrongEtherAmountSent();
error TokenDoesNotExist();
error SaleNotOpen();
error ArraysDifferentLength();


contract PictographStomachAche is ERC721A, IERC2981, VerifySignature, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 6666;
    uint256 public MAX_PER_WALLET = 10;
    uint256 public ROYALTY_PERCENT = 10;
    uint256 public PRICE_PER_NFT = 0.012 ether;

    enum ContractState { PAUSED, PUBLIC, REVEALED }
    ContractState public currentState = ContractState.PAUSED;

    string private baseURI;
    string private baseURISuffix;

    address public royaltyAddress;

    constructor() 
        ERC721A("Pictograph Stomach Ache", "PSA")
        VerifySignature("xx-v1", msg.sender)
    {
        royaltyAddress = msg.sender;
    }

    function mint(uint256 quantity) external payable nonReentrant {
        if(currentState != ContractState.PUBLIC) revert SaleNotOpen();
        if(_numberMinted(msg.sender) + quantity > MAX_PER_WALLET) revert ExceedsMaxPerAddress();
        if(totalSupply() + quantity  > MAX_SUPPLY) revert ExceedsMaxSupply();
        if(getNFTPrice(quantity) != msg.value) revert WrongEtherAmountSent();

        _safeMint(msg.sender, quantity);
    }

    function getNFTPrice(uint256 quantity) public view returns (uint256) {
        return PRICE_PER_NFT * quantity;
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }


    /****************************************\
    *             ADMIN FUNCTIONS            *
    \****************************************/

    function changeContractState(ContractState _state) external onlyOwner {
        currentState = _state;
    }

    function setBaseURI(string calldata _base, string calldata _suffix) external onlyOwner {
        baseURI = _base;
        baseURISuffix = _suffix;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawTest() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function setMintPrice(uint256 _setMintPrice) external onlyOwner {
        PRICE_PER_NFT = _setMintPrice;
    }

    function setMaxSupply(uint256 _setMaxSupply) external onlyOwner {
        MAX_SUPPLY = _setMaxSupply;
    }

    function setMaxPerWallet(uint256 _setMaxPerWallet) external onlyOwner {
        MAX_PER_WALLET = _setMaxPerWallet;
    }

    function mintForMarketingPurpose(uint256 quantity) external payable nonReentrant onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    function setRoyalties(address _royaltyAddress, uint256 _royaltyPercent) public onlyOwner {
        royaltyAddress = _royaltyAddress;
        ROYALTY_PERCENT = _royaltyPercent;
    }


    /****************************************\
    *           OVERRIDES & EXTRAS           *
    \****************************************/

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        if(currentState != ContractState.REVEALED) {
            return string(abi.encodePacked(baseURI, "before-reveal", baseURISuffix));
        }
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseURISuffix));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // EIP-2981: NFT Royalty Standard
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256 royaltyAmount) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        royaltyAmount = ((salePrice / 100) * ROYALTY_PERCENT);
        return (royaltyAddress, royaltyAmount);
    }
}