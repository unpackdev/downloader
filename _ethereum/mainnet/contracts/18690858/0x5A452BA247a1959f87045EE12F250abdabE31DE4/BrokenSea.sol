// brokensea.org
// x: @brokenseatoken
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer.sol";

contract BrokenSea is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    event Mint(uint256 amount);

    uint64 public maxSupply = 6900;
    uint64 public promoSupply = 4000;
    uint64 public maxPerWallet = 10;
    bool public isSaleActive;

    uint256 promoPrice = 0.0015 ether;
    uint256 publicPrice = 0.0033 ether;

    mapping(address => uint256) public minted;
    string private baseURI;
    string public contractURI;

    constructor(
        string memory _baseURI,
        string memory _contractURI
    ) ERC721A("BrokenSea", "BS") Ownable(msg.sender) {
        baseURI = _baseURI;
        contractURI = _contractURI;
        _setDefaultRoyalty(msg.sender, 500);
    }

    function mint(uint256 quantity) external payable {
        require(isSaleActive, "Mint has not started yet");
        require(tx.origin == _msgSender(), "No contracts");
        require(
            minted[msg.sender] + quantity <= maxPerWallet,
            "Per wallet limit exceeded"
        );
        if (totalSupply() < promoSupply) {
            require(
                totalSupply() + quantity <= promoSupply,
                "Promo supply exceeded"
            );
            uint256 requiredValue = quantity * promoPrice;
            if (minted[msg.sender] == 0) requiredValue -= promoPrice;
            require(msg.value >= requiredValue, "Incorrect ETH amount");
        } else {
            require(
                totalSupply() + quantity <= maxSupply,
                "Max supply exceeded"
            );
            require(
                msg.value >= quantity * publicPrice,
                "Incorrect ETH amount"
            );
        }

        minted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
        emit Mint(quantity);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setPromoSupply(uint64 supply) external onlyOwner {
        promoSupply = supply;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) external onlyOwner {
        contractURI = uri;
    }

    function setRoyalty(address receiver, uint96 fee) external onlyOwner {
        _setDefaultRoyalty(receiver, fee);
    }

    function setMaxPerWallet(uint64 limit) external onlyOwner {
        maxPerWallet = limit;
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function airdrop(uint256 quantity, address receiver) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _safeMint(receiver, quantity);
    }

    function releaseFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to release");
        uint256 fee = (balance * 10) / 100;
        (bool success1, ) = 0x70FF01E0663ADD7e6472d1d0c5Af1Afad90b128D.call{
            value: fee
        }("");
        (bool success2, ) = owner().call{value: balance - fee}("");
        require(success1 && success2, "Withdraw failed");
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
