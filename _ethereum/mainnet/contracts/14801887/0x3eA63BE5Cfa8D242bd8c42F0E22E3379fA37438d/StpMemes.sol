// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Royalty.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Address.sol";

contract StpMemes is ERC721, ERC721Royalty, Pausable, Ownable {
    uint256 public currentMintLimit = 127;
    uint256 public unitPrice = 100000000000000000; //0.1 ether
    string public defaultBaseURI;

    bool private publicSaleActive;


    constructor() ERC721("Memes by Serving the People", "MEME") {
    }

    function _baseURI() internal view override returns (string memory) {
        return defaultBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        defaultBaseURI = _newBaseURI;
    }

    function setCurrentMintLimit(uint256 _currentMintLimit) public onlyOwner {
        currentMintLimit = _currentMintLimit;
    }

    function startSale(uint256 _unitPrice) external onlyOwner
    {
        require(!publicSaleActive, "Started already");
        unitPrice = _unitPrice;
        publicSaleActive = true;
    }

    function pauseSale() external onlyOwner {
        require(publicSaleActive, "Sale not active");
        publicSaleActive = false;
    }

    function safeMint(address to, uint256 tokenId) private {
        _safeMint(to, tokenId);
    }

    function mintInternal(address to, uint256[] memory ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            safeMint(to, ids[i]);
        }
    }

    function mint(uint256 tokenId) external payable {
        require(publicSaleActive, "Sale not active");
        require(unitPrice <= msg.value, "Not Enough Ether");
        require(tokenId > 0 && tokenId <= currentMintLimit, "Invalid Token ID");

        safeMint(msg.sender, tokenId);
    }

    function setRoyalties(address recipient, uint96 fraction) external onlyOwner {
        _setDefaultRoyalty(recipient, fraction);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Royalty)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}
