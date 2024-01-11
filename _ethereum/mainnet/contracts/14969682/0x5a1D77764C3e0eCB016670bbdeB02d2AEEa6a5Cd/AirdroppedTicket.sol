//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract AirdroppedTicket is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    mapping(uint256 => string) public tokenUris;

    constructor() ERC1155() {}

    // minting

    function ownerMint(uint256 tokenId, uint256 amount) external onlyOwner {
        mint(msg.sender, tokenId, amount);
    }

    function ownerGiftMints(address[] memory addrs, uint256 tokenId, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            mint(addrs[i], tokenId, amount);
        }
    }

    function mint(address addr, uint256 tokenId, uint256 amount) private {
        _mint(addr, tokenId, amount, '');
    }

    // getters

    function uri(uint256 id) public view override returns (string memory) {
        return tokenUris[id];
    }

    // setters

    function setTokenURI(uint256 tokenId, string memory tokenUri) external onlyOwner {
        tokenUris[tokenId] = tokenUri;
    }

    receive() external payable nonReentrant {}

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}
