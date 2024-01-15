// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

error ClaimNotEligible();
error ExceedsTotalSupply();
error ClaimInactive();
error IncorrectOwner();

interface MetakamiInterface {
    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);
}

contract MetakamiManga is ERC1155Supply, ERC1155Burnable, ReentrancyGuard, Ownable {
    bool public isClaimActive = false;
    address public immutable METAKAMI_CONTRACT;
    uint256 public chapter;
    uint256 public maxSupply;
    string private baseURI;

    mapping(uint256 => mapping(uint256 => bool)) public isChapterClaimedByTokenId; // Chapter -> Token ID -> True/False

    event ChapterPublished(uint256 chapterID);
    event Minted(uint256 metakamiID, address recipient, uint256 chapter);

    constructor(address _metakamiContract) ERC1155("") {
        METAKAMI_CONTRACT = _metakamiContract;
        maxSupply = 3333;
        chapter = 1;
        emit ChapterPublished(1);
    }

    function claimManga(uint256[] calldata tokenIds) public nonReentrant {
        if (!isClaimActive) revert ClaimInactive();

        uint256 counter;

        /// Loop through all the token ID inputs and check if already claimed
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; ) {
                address owner = getOwnerOfMetakami(tokenIds[i]);
                if (msg.sender != owner) revert ClaimNotEligible();

                if (!isChapterClaimedByTokenId[chapter][tokenIds[i]]) {
                    counter++;
                    isChapterClaimedByTokenId[chapter][tokenIds[i]] = true;

                    emit Minted(tokenIds[i], msg.sender, chapter);
                }
                ++i;
            }
            if (counter == 0) revert ClaimNotEligible();
            if (totalSupply(chapter) + counter > maxSupply) revert ExceedsTotalSupply();
        }

        _mint(msg.sender, chapter, counter, "");
    }

    function airdrop(address recipient, uint256 amount) external onlyOwner {
        if (totalSupply(chapter) + amount > maxSupply) revert ExceedsTotalSupply();
        _mint(recipient, chapter, amount, "");
    }

    function toggleIsClaimActive() external onlyOwner {
        isClaimActive = !isClaimActive;
    }

    function setURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 chapterId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(chapterId))) : baseURI;
    }

    function setChapter(uint256 chapterId) external onlyOwner {
        chapter = chapterId;
        emit ChapterPublished(chapterId);
    }

    function updateMaxSupply() external onlyOwner {
        maxSupply = MetakamiInterface(METAKAMI_CONTRACT).totalSupply();
    }

    function getOwnerOfMetakami(uint256 tokenId) public view returns (address) {
        return MetakamiInterface(METAKAMI_CONTRACT).ownerOf(tokenId);
    }

    /*  
        @dev Derived contract must override function "_beforeTokenTransfer". 
        Two or more base classes define function with same name and parameter types.solidity(6480)
    */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
