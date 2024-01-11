pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract WL_NFT is ERC1155, Ownable {
    address marketplace;
    uint256 maxTokens;
    string public baseUri;

    mapping(address => bool) isApprovedFully;
    constructor() ERC1155("") {
        setBaseUri('ipfs://QmZzz3rixyoCmpumMoSvFrXtJb4tBA4HFZkgQD1LwY5cPb/');
        _mint(0x1B3FEA07590E63Ce68Cb21951f3C133a35032473, 1, 100, '');
        _mint(0xd4B4Fad08c5710f2E9F86D9c71EdeBF9c72D8354, 2, 100, '');
    }

    function marketplaceMint(address user, uint256 tokenId, uint256 count) external {
        require(msg.sender == marketplace, "not marketplace");
        require(tokenId < maxTokens, "Not in range");
        _mint(user, tokenId, count, '');
    }

    function uri(uint256 tokenId) public override view returns (string memory) {
        require(tokenId < maxTokens, "Not in range");
        return string(abi.encodePacked(baseUri, toString(tokenId), ".json"));
    }

    function ownerMint(address user, uint256 tokenId, uint256 count) external {
        require(msg.sender == owner(), "not owner");

        _mint(user, tokenId, count, '');
    }

    function setMarketplace(address newMarketplace) public onlyOwner {
        marketplace = newMarketplace;
    }

    function setBaseUri(string memory newBaseURI) public onlyOwner {
        baseUri = newBaseURI;
    }
    function setApprovalFor(address operator, bool state) public onlyOwner {
        isApprovedFully[operator] = state;
    }
    function setMaxTokens(uint256 _maxTokens) external onlyOwner {
        maxTokens = _maxTokens;
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function isApprovedForAll(address account, address operator) public override view returns (bool) {
        if (isApprovedFully[operator]) { return true; }
        return ERC1155.isApprovedForAll(account, operator);
    }
}