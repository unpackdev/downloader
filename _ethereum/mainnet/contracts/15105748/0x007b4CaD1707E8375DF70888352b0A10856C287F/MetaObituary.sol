// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Ownable.sol";

contract MetaObituary is ERC721, Ownable
{
    using SafeMath for uint256;
    using Strings for uint256;
    using Strings for uint16;

    uint256 public publicPrice = 0;
    uint256 public minted = 0;                      // minted of nft

    modifier validNFToken(uint256 _tokenId) {
        require(_exists(_tokenId), "Invalid token.");
        _;
    }

    constructor () public ERC721("MetaObituary", "MO") {}

    // Public sale minting
    function mint(string memory tokenURI) external payable {
        require(publicPrice <= msg.value, "Ether value sent is not correct");
        mintTo(msg.sender, tokenURI);
    }

    // mint with tokenURI
    function mintTo(address _to, string memory tokenURI) internal returns (uint) {
        require(_to != address(0), "Cannot mint to 0x0.");
        uint id = minted;
        _safeMint(msg.sender, id);
        _setTokenURI(id, tokenURI);
        minted = minted + 1;
        return id;
    }

    function withdraw() external onlyOwner {
        payable(owner()).send(address(this).balance);
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

}