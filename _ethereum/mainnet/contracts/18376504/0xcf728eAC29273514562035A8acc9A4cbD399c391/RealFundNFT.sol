// contracts/RealFundNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract RealFundNFT is ERC721, Pausable, Ownable, ERC721Burnable {

    string private _suffix;
    string private _myBaseURI;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        string memory _uri
    ) ERC721(_name, _symbol) {
      _transferOwnership(_owner);
      _myBaseURI = _uri;
      _suffix = '';
    }

 
    function setBaseURI(string memory baseURI, string memory suffix) external onlyOwner {
       _myBaseURI = baseURI;
       _suffix = suffix;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token Id must exist");
        string memory baseURI = _myBaseURI;
        baseURI = string(abi.encodePacked(baseURI, Strings.toString(tokenId)));

        string memory suffix = _suffix;
        if (bytes(suffix).length > 0) {
            baseURI = string(abi.encodePacked(baseURI, suffix));
        }
        return baseURI;
    }

   /**
     * @dev pauses the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpauses the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param to address of the future owner of the token
     * @param tokenId new token ID
     */
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
}
