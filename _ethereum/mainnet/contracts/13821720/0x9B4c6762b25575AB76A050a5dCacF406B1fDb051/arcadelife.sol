// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract ArcadeLife is ERC721, ERC721Enumerable, Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint;

    string private _contractURI;
    string private _tokenBaseURI = "https://nftcontracts.art/api/contracts/arcadelife/tokens/";
    address private _withdrawalAddress = 0x718dA96B896D31588f5e4a07E2c07e78dE8377E1;
    uint256 private _mintPrice = 0.02 ether;

    uint256 public maxSupply = 4200;
    uint256 public txMintLimit = 10;
    uint256 public txGiveAwayLimit = 10;

    constructor() ERC721("Arcade Life", "ARLF") {}
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }
    
    function updateContractURI(string memory updatedContractURI) public onlyOwner {
        _contractURI = updatedContractURI;
    }

    function updateBaseURI(string memory updatedBaseURI) public onlyOwner {
       _tokenBaseURI = updatedBaseURI;
    }

    function updateMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function updateWithdrawalAddress(address updatedAddress) public onlyOwner {
        _withdrawalAddress = updatedAddress;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function mintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function mintLife(uint256 totalLifeNfts) public whenNotPaused payable {        
        require(totalLifeNfts.add(totalSupply()) <= maxSupply, "We're sold out!");
        require(totalLifeNfts <= txMintLimit, "Mint limit per tx exceeded");
        require(msg.value >= _mintPrice.mul(totalLifeNfts), "Insufficient ether for minting");
        
        for (uint256 i = 0; i < totalLifeNfts; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function giveLife(address receiver, uint256 totalLifeNfts) public onlyOwner {
        require(totalLifeNfts.add(totalSupply()) <= maxSupply, "We're sold out!");
        require(totalLifeNfts <= txGiveAwayLimit, "Give away limit per tx exceeded");

        for (uint256 i = 0; i < totalLifeNfts; i++) {
            _safeMint(receiver, totalSupply());
        }
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(_withdrawalAddress).call{value:address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
