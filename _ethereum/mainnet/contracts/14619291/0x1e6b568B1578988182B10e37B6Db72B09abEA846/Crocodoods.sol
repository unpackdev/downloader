// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./ERC721A.sol";
import "./VerifySignature.sol";

error ExceedsMaxSupply();
error ExceedsMaxPerTransaction();
error SignatureNotValid();
error SenderMustBeOrigin();
error WrongEtherAmountSent();
error TokenDoesNotExist();
error SaleNotOpen();
error ArraysDifferentLength();


contract Crocodoods is ERC721A, IERC2981, VerifySignature, ReentrancyGuard {
    using Strings for uint256;

    uint256 public immutable MAX_SUPPLY = 6000;
    uint256 public ROYALTY_PERCENT = 7;
    uint256 public immutable PRICE_PER_NFT = .08 ether;
    uint256 public immutable MAX_PER_TRANSACTION_PRESALE = 2; 
    uint256 public immutable MAX_PER_TRANSACTION_PUBLIC = 3;

    enum ContractState { PAUSED, PRESALE, PUBLIC, REVEALED }
    ContractState public currentState = ContractState.PAUSED;

    string private baseURI;
    string private baseURISuffix;

    address public royaltyAddress;

    constructor(string memory _base, string memory _suffix) 
        ERC721A("Crocodoods", "DOODS")
        VerifySignature("cd-v1", msg.sender)
    {
        baseURI = _base;
        baseURISuffix = _suffix;
        royaltyAddress = msg.sender;
    }

    function claim(uint256 quantity, uint256 maxMintAmount, bytes memory signature) external payable nonReentrant {
        if(currentState == ContractState.PAUSED || 
            currentState == ContractState.REVEALED) revert SaleNotOpen();
        if(getNFTPrice(quantity) != msg.value) revert WrongEtherAmountSent();
        if(totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();
        if(!_verify(msg.sender, maxMintAmount, signature)) revert SignatureNotValid();
        // The project has decided not to limit wl members to a quanitity
        // Members can mint as many nft's as they would like, limit 2 per transaction.
        if(quantity > MAX_PER_TRANSACTION_PRESALE) revert ExceedsMaxPerTransaction();

        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable nonReentrant {
        if(currentState != ContractState.PUBLIC) revert SaleNotOpen();
        if(totalSupply() + quantity  > MAX_SUPPLY) revert ExceedsMaxSupply();
        if(getNFTPrice(quantity) != msg.value) revert WrongEtherAmountSent();
        if(quantity > MAX_PER_TRANSACTION_PUBLIC) revert ExceedsMaxPerTransaction();

        _safeMint(msg.sender, quantity);
    }

    function getNFTPrice(uint256 quantity) public pure returns (uint256) {
        return PRICE_PER_NFT * quantity;
    }


    /****************************************\
    *             ADMIN FUNCTIONS            *
    *****************************************/

    function changeContractState(ContractState _state) external onlyOwner {
        currentState = _state;
    }

    function airdrop(address to, uint256 quantity) external onlyOwner {
        if(totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();

        _safeMint(to, quantity);
    }

    function setBaseURI(string calldata _base, string calldata _suffix) external onlyOwner {
        baseURI = _base;
        baseURISuffix = _suffix;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function setRoyalties(address _royaltyAddress, uint256 _royaltyPercent) public onlyOwner {
        royaltyAddress = _royaltyAddress;
        ROYALTY_PERCENT = _royaltyPercent;
    }


    /****************************************\
    *           OVERRIDES & EXTRAS           *
    *****************************************/

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        if(currentState != ContractState.REVEALED) {
            return string(abi.encodePacked(baseURI, "pre", baseURISuffix));
        }
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseURISuffix));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // EIP-2981: NFT Royalty Standard
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256 royaltyAmount) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        royaltyAmount = (salePrice / 100) * ROYALTY_PERCENT;
        return (royaltyAddress, royaltyAmount);
    }
}