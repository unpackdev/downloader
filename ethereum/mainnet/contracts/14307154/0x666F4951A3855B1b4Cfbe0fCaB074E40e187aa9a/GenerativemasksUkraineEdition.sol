// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract GenerativemasksUkraineEdition is ERC721, ReentrancyGuard, Ownable {

    using Strings for uint256;

    IERC721 public generativemasks = IERC721(0x80416304142Fa37929f8A4Eee83eE7D2dAc12D7c);
    uint256 public constant GMS_SUPPLY_AMOUNT = 10000;
    uint256 public constant MAX_GMs_TOKEN_ID = 9999;
    uint256 public constant METADATA_INDEX = 3799;
    uint256 public constant MIN_DONATION = 0.001 ether;
    string internal __baseURI;

    constructor(string memory baseURI) ERC721("Generativemasks Ukraine Edition", "GMUE") {
        __baseURI = baseURI;
    }

    modifier checkDonation() {
        require(msg.value >= MIN_DONATION, "GenerativemasksUkraineEdition: Invalid value");
        _;
    }

    function _getTokenIdFromMaskNumber(uint256 maskNumber) internal pure returns (uint256) {
        require(maskNumber <= MAX_GMs_TOKEN_ID, "GenerativemasksUkraineEdition: Invalid number");
        return ((maskNumber + GMS_SUPPLY_AMOUNT) - METADATA_INDEX) % GMS_SUPPLY_AMOUNT;
    }

    function _getTokenIdListFromMaskNumbers(uint256[] calldata maskNumbers) internal pure returns (uint256[] memory) {
        uint256[] memory tokenIdList = new uint256[](maskNumbers.length);

        for (uint256 i = 0; i < maskNumbers.length; i++) {
            tokenIdList[i] = _getTokenIdFromMaskNumber(maskNumbers[i]);
        }

        return tokenIdList;
    }

    function donateAndMintWithMaskNumber(
        uint256 maskNumber
    ) public payable nonReentrant checkDonation {
        uint256 tokenId = _getTokenIdFromMaskNumber(maskNumber);
        require(generativemasks.ownerOf(tokenId) == msg.sender, "GenerativemasksUkraineEdition: Invalid owner");
        _safeMint(msg.sender, tokenId);

        _donate();
    }

    function donateAndBatchMintWithMaskNumbers(
        uint256[] calldata maskNumbers
    ) public payable nonReentrant checkDonation {
        uint256[] memory tokenIdList = _getTokenIdListFromMaskNumbers(maskNumbers);

        for (uint256 i; i < tokenIdList.length; i++) {
            uint256 tokenId = tokenIdList[i];
            require(generativemasks.ownerOf(tokenId) == msg.sender, "GenerativemasksUkraineEdition: Invalid owner");
            _safeMint(msg.sender, tokenId);
        }

        _donate();
    }

    function _donate() internal {
        Address.sendValue(payable(0x165CD37b4C644C2921454429E7F9358d18A45e14), msg.value);
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        __baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "GenerativemasksUkraineEdition: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        uint256 metadataId = (tokenId + METADATA_INDEX) % GMS_SUPPLY_AMOUNT;
        return string(abi.encodePacked(baseURI, metadataId.toString(), ".json"));
    }

}
