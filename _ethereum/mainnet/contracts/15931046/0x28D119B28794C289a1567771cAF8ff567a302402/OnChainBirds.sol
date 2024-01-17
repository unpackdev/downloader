// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12 <0.9.0;
import "./ERC721A.sol";
import "./Base64.sol";
import "./Ownable.sol";

contract OnChainBirds is ERC721A, Ownable {
    /*
     ____       _______        _      ___  _        __  
    / __ \___  / ___/ /  ___ _(_)__  / _ )(_)______/ /__
    / /_/ / _ \/ /__/ _ \/ _ `/ / _ \/ _  / / __/ _  (_-<
    \____/_//_/\___/_//_/\_,_/_/_//_/____/_/_/  \_,_/___/
    */
    // nesting
    mapping(uint256 => uint256) private nestingTotal;
    mapping(uint256 => uint256) private nestingStarted;
    uint256 private nestingTransfer;
    bool public nestingIsOpen = true;

    constructor() ERC721A("OnChainBirds", "OCBIRD") {_mint(msg.sender, 12);}

    function mint(uint256 quantity) external {
            _mint(msg.sender, quantity);
    }

    function expelFromNest(uint256 tokenId) external onlyOwner {
        require(nestingStarted[tokenId] != 0);
        nestingTotal[tokenId] += block.timestamp - nestingStarted[tokenId];
        delete nestingStarted[tokenId];
    }

    function setNestingOpen() external onlyOwner {
        nestingIsOpen = !nestingIsOpen;
    }

    /**
        Nesting Functions
     */
    
    function nestingPeriod(uint256 tokenId) external view returns (bool nesting, uint256 current, uint256 total) {
        uint256 start = nestingStarted[tokenId];
        if (start != 0) {
            nesting = true;
            current = block.timestamp - start;
        }
        total = 7776006;
    }

    function transferWhileNesting(address from, address to, uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender);
        nestingTransfer = 1;
        transferFrom(from, to, tokenId);
        delete nestingTransfer;
    }

    function _beforeTokenTransfers(address, address, uint256 startTokenId, uint256 quantity) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(nestingStarted[tokenId] == 0 || nestingTransfer != 0, "Nesting");
        }
    }

    function toggleNesting(uint256[] calldata tokenIds) external {
        bool nestOpen = nestingIsOpen;
        for (uint256 i; i < tokenIds.length; ++i) {
            require(ownerOf(tokenIds[i]) == msg.sender);
            uint256 start = nestingStarted[tokenIds[i]];
            if (start == 0) {
                require(nestOpen);
                nestingStarted[tokenIds[i]] = block.timestamp;
            } else {
                nestingTotal[tokenIds[i]] += block.timestamp - start;
                nestingStarted[tokenIds[i]] = 0;
            }
        }
    }

    // tokensOfOwner function: MIT License
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
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
    } 
}
