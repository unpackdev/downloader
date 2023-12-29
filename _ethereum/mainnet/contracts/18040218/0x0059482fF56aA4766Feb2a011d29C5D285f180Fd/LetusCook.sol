// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";

contract LetUsCook is DefaultOperatorFilterer, Ownable, ERC721A, ReentrancyGuard {
    event Mint(address indexed account, uint256 indexed num);
    uint256 public mintStartTime;
    uint256 public mintEndTime;
    string private _internalBaseURI;
    mapping(address => bool) public nftMinted;

    constructor(string memory baseuri) ERC721A("LET'S COOK-KBW2023", "LET'S COOK") {
        _internalBaseURI = baseuri;
        mintStartTime = 1693526400;
        mintEndTime = 1694390400;
    }

    function mint() external callerIsUser nonReentrant {
        require(block.timestamp >= mintStartTime && block.timestamp <= mintEndTime, "not time");
        require(!nftMinted[_msgSender()], "minted");
        nftMinted[_msgSender()] = true;
        super._safeMint(_msgSender(), 1);
        emit Mint(_msgSender(), 1);
    }

    function setMintTimes(uint256 mintStartTime_, uint256 mintEndTime_) external onlyOwner {
        require(mintStartTime_ < mintEndTime_);
        mintStartTime = mintStartTime_;
        mintEndTime = mintEndTime_;
    }
    
    function setBaseURI(string memory internalBaseURI_) external onlyOwner {
        _internalBaseURI = internalBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _internalBaseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);

        TokenOwnership memory ownership;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
            ownership = _ownershipAt(i);

            if (ownership.burned) {
                continue;
            }

            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }

            if (currOwnershipAddr == owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }
        return tokenIds;
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
}

