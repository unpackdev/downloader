//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Zen is ERC721Enumerable, Ownable {

    using Strings for uint256;

    uint256 public constant SALE_MAX = 9999;
    ///@dev Max mint limit per purchase
    uint256 public constant MAX_MINT = 20;
    /// @dev NFT price
    uint256 public constant PRICE = 0.02 ether;
    /// @dev For calculate remain available.
    uint256 public totalPublicSupply;

    /// @dev Sale active flag
    bool public saleActive = false;

    /// @dev proof of hash
    string public proof;

    string private _contractUri;
    string private _tokenBaseUri;
    string private _tokenRevealedBaseUri = '';

    event TotalMinted(uint256 totalPublicSupply);

    constructor(string memory name, string memory symbol, string memory baseUri, string memory conUri) ERC721(name, symbol) {
        _tokenBaseUri = baseUri;
        _contractUri = conUri;
        _safeMint(msg.sender, 1);
        totalPublicSupply = 1;
    }

    function purchase(uint256 tokenQuantity) external payable {
        require(saleActive, 'Sale is not active');
        require(totalSupply() < SALE_MAX, 'Sold Out');
        require(tokenQuantity > 0, 'Purchase Quantity must be greater than 0');
        require(tokenQuantity <= MAX_MINT, 'Purchase limit exceed');

        require(PRICE * tokenQuantity <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < tokenQuantity; i++) {

            if (totalPublicSupply < SALE_MAX) {
                /**
                * @dev Public token numbering starts at 1.
                */
                uint256 tokenId = totalPublicSupply + 1;

                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }

        emit TotalMinted(totalPublicSupply);

    }

    function setSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function setProof(string calldata proofHash) external onlyOwner {
        proof = proofHash;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setContractUri(string calldata uri) external onlyOwner {
        _contractUri = uri;
    }

    function setBaseUri(string calldata uri) external onlyOwner {
        _tokenBaseUri = uri;
    }

    function setRevealedBaseUri(string calldata uri) external onlyOwner {
        _tokenRevealedBaseUri = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function getSaleMax() external pure returns (uint256) {
        return SALE_MAX;
    }

    function getProof() external view returns (string memory) {
        return proof;
    }

    function getBaseUri() external view returns (string memory) {
        return _tokenBaseUri;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token not found');

        /// @dev Convert string to bytes check if it's empty or not.
        string memory revealedBaseURI = _tokenRevealedBaseUri;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
        string(abi.encodePacked(_tokenBaseUri, tokenId.toString()));
        
    }
}
