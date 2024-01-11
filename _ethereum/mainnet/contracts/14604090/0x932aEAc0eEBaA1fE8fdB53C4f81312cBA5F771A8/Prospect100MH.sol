// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "ERC721.sol";
import "Ownable.sol";
import "ISimpleLimitedMinter.sol";

contract Prospect100MH is ERC721, Ownable, ISimpleLimitedMinter {
    string internal baseURI;
    bool internal isLockedURI;

    uint256 public nextTokenId;
    uint256 public maxTokens;

    address public minterAddress;

    constructor(uint max_, string memory name_, string memory symbol_,
        string memory baseURI_, uint256 instantAirdrop) payable ERC721(name_, symbol_) {
        maxTokens = max_;
        baseURI = baseURI_;
        require(instantAirdrop <= maxTokens, "Too many tokens to airdrop");
        for (uint256 i = 1; i <= instantAirdrop; i++) _mint(msg.sender, i);
        nextTokenId = instantAirdrop + 1;
    }

    modifier onlyMinter() {
        require(msg.sender == minterAddress, "Not a minter");
        _;
    }

    function changeMinterAddress(address minterAddress_) external onlyOwner {
        minterAddress = minterAddress_;
    }

    // lock metadata forever
    function lockURI() external onlyOwner {
        isLockedURI = true;
    }

    // modify the base URI
    function changeBaseURI(string memory newBaseURI) onlyOwner external
    {
        require(!isLockedURI, "URI change has been locked");
        baseURI = newBaseURI;
    }

    // return Base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //only minter - mints next token to address
    function tryMint(address to) external onlyMinter override returns (bool minted, uint256 tokenId) {
        if (nextTokenId > maxTokens) return (false, 0);
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        nextTokenId++;
        return (true, tokenId);
    }
}
