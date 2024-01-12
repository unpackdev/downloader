// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC2981.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ERC721A.sol";

error ExceedsMaxSupply();
error WrongEtherAmountSent();
error TokenDoesNotExist();
error SaleNotOpen();

contract Neighbears is ERC721A, IERC2981, Ownable {
    using Address for address;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public pricePerNft = .055 ether; // Changes for public
    uint256 public royaltyPercent = 700;

    enum ContractState { PAUSED, PRESALE, PUBLIC, REVEALED }
    ContractState public currentState = ContractState.PAUSED;

    string private baseURI;
    string private baseURISuffix;

    address public royaltyAddress;

    constructor(string memory _base, string memory _suffix) 
        ERC721A("Neighbears", "BEAR")
    {
        baseURI = _base;
        baseURISuffix = _suffix;
        royaltyAddress = msg.sender;
        // minting 1 to make an OS profile.
        _mint(msg.sender, 1);
    }

    function mint(uint256 quantity) external payable {
        if(currentState != ContractState.PRESALE &&
            currentState != ContractState.PUBLIC) revert SaleNotOpen();
        if(totalSupply() + quantity  > MAX_SUPPLY) revert ExceedsMaxSupply();
        if(getNFTPrice(quantity) != msg.value) revert WrongEtherAmountSent();
        // Users can mint as many NFT's as they would like.

        _safeMint(msg.sender, quantity);
    }

    function getNFTPrice(uint256 quantity) public view returns (uint256) {
        return pricePerNft * quantity;
    }

    function changeContractState(ContractState _state) external onlyOwner {
        currentState = _state;
        if(currentState == ContractState.PUBLIC){
            pricePerNft = .077 ether;
        } else {
            pricePerNft = .055 ether;
        }
    }

    function setPriceManually(uint256 price) external onlyOwner {
        pricePerNft = price;
    }

    function setBaseURI(string calldata _base, string calldata _suffix) external onlyOwner {
        baseURI = _base;
        baseURISuffix = _suffix;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function setRoyalties(address _royaltyAddress, uint256 _royaltyPercent) public onlyOwner {
        royaltyAddress = _royaltyAddress;
        royaltyPercent = _royaltyPercent;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        if(currentState != ContractState.REVEALED) {
            return string(abi.encodePacked(baseURI, "pre", baseURISuffix));
        }
        return string(abi.encodePacked(baseURI, _toString(tokenId), baseURISuffix));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // EIP-2981: NFT Royalty Standard
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256 royaltyAmount) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        royaltyAmount = (salePrice * royaltyPercent) / 10000;
        return (royaltyAddress, royaltyAmount);
    }
}