//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC2981.sol";

contract ShortLifeOfTommy is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant ORIGINAL_MAX_SUPPLY = 4000;
    uint256 public constant WALLET_MAX = 10;
    string public constant PROVENANCE = "840FE336B85CEED275AC08DAB440E1ACF929B5DB63727F3D33096E97A6187D04";

    uint256 public MaxSupply = ORIGINAL_MAX_SUPPLY;
    uint256 public RevealTimestamp;
    bool public SaleIsActive = false;

    uint256 public IndexOffset;

    string _unrevealedUri = "ipfs://bafkreieyfstpeqk2keka3efueigcxhyw7vrzczdihgnjom3cvar4cbkt74";
    string _revealedUri = "ipfs://bafybeie5x5zbcgjxniqgzpkypmi4t6zquowx5eygj42cgieug7wlglhuya/";
    uint16 _royaltyBasisPoints = 600; // 6%

    mapping(address => uint256) private _totalClaimed;

    constructor() ERC721A("ShortLifeOfTommy", "SLOT") {
        RevealTimestamp = block.timestamp + 48 hours;
    }

    function mint(uint256 amount) external payable nonReentrant {
        require(SaleIsActive, "Sale must be active to mint");
        require(_totalClaimed[msg.sender] + amount <= WALLET_MAX, "Purchase exceeds max allowed per wallet");
        require(totalSupply() + amount <= MaxSupply, "Minting would exceed max supply");
        _safeMint(msg.sender, amount);
        if (IndexOffset == 0 && (totalSupply() == MaxSupply || block.timestamp >= RevealTimestamp)) {
            _setIndexOffset(block.number);
        }
        _totalClaimed[msg.sender] += amount;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory tokenUri;
        if (IndexOffset == 0) {
            tokenUri = bytes(_unrevealedUri).length > 0 ? string(abi.encodePacked(_unrevealedUri)) : '';
        }
        else {
            uint256 actualTokenId = _shiftedIndex(tokenId);
            return bytes(_revealedUri).length > 0 ? string(abi.encodePacked(_revealedUri, actualTokenId.toString(),'.json')) : '';
        }
        return tokenUri;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        tokenId;
        return (address(this), (salePrice * _royaltyBasisPoints) / 10000);
    }

    function flipSale() external onlyOwner {
        SaleIsActive = !SaleIsActive;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        require(totalSupply() <= newSupply, "Cannot lower max supply under what has already been minted");
        require(newSupply <= ORIGINAL_MAX_SUPPLY, "Cannot raise max supply over the original minting limit");
        MaxSupply = newSupply;
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        RevealTimestamp = revealTimeStamp;
    }

    function setUnrevealedUri(string memory unrevealedUri) public onlyOwner {
        _unrevealedUri = unrevealedUri;
    }

    function setRevealedUri(string memory revealedUri) public onlyOwner {
        _revealedUri = revealedUri;
    }

    function emergencySetIndexOffset() public onlyOwner {
        require(IndexOffset == 0, "IndexOffset is already set");
        _setIndexOffset(block.number);
    }

    function setRoyaltyBasisPoints(uint16 royaltyBasisPoints) external onlyOwner {
        _royaltyBasisPoints = royaltyBasisPoints;
    }

    function _setIndexOffset(uint256 blockNumber) private {
        if (IndexOffset == 0) {
            uint256 tokenBlocksHash = uint256(blockhash(blockNumber - 1));
            if (tokenBlocksHash == 0) {
                tokenBlocksHash = uint256(blockhash(block.number - 1));
            }
            IndexOffset = (tokenBlocksHash % ORIGINAL_MAX_SUPPLY) + 1;
        }
    }

    function _shiftedIndex(uint256 tokenId) private view returns (uint256) {
        uint256 offsetId = tokenId + IndexOffset - 1;
        uint256 newTokenId = offsetId % ORIGINAL_MAX_SUPPLY;
        return newTokenId;
    }
}