// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract HyperNFT_HOS is ERC721, Ownable {
    string public baseURI;
    uint256 public currentTokenId;

    constructor() ERC721("HyperNFT_HOS_1.0", "HHOS1") {}

    function mint(address to, uint256 amount) external onlyOwner {
        uint256 curId = currentTokenId;
        for (uint256 i; i < amount; ++i) {
            _mint(to, curId + i);
        }
        currentTokenId += amount;
    }

    function bulkMint(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(recipients.length == amounts.length, "length not match");
        uint256 curId = currentTokenId;
        uint256 total;
        for (uint256 i; i < recipients.length; ++i) {
            for (uint256 j = 0; j < amounts[i]; ++j) {
                _mint(recipients[i], curId);
                ++curId;
                ++total;
            }
        }
        currentTokenId += total;
    }

    function batchTransfer(address recipient, uint256[] calldata tokenIds)
        external
    {
        for (uint256 i; i < tokenIds.length; ++i) {
            _transfer(msg.sender, recipient, tokenIds[i]);
        }
    }

    function batchTransfer2(
        address[] calldata recipients,
        uint256[] calldata amountPerRecipient,
        uint256[] calldata tokenIds
    )
        external
    {
        require(recipients.length == amountPerRecipient.length, "length not match");
        uint256 tokenIdOffset;
        for (uint256 i; i < recipients.length; ++i) {
            for (uint256 k; k < amountPerRecipient[i]; ++k) {
                _transfer(msg.sender, recipients[i], tokenIds[tokenIdOffset]);
                ++tokenIdOffset;
            }
        }
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token id not exist");
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, Strings.toString(tokenId))
                : "";
    }
}