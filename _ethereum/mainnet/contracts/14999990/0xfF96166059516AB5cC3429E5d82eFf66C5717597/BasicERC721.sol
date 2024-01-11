//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Context.sol";

/**
Powered by
  _____      _       ____      _____   
 |_ " _| U  /"\  uU |  _"\ u  |_ " _|  
   | |    \/ _ \/  \| |_) |/    | |    
  /| |\   / ___ \   |  _ <     /| |\   
 u |_|U  /_/   \_\  |_| \_\   u |_|U   
 _// \\_  \\    >>  //   \\_  _// \\_  
(__) (__)(__)  (__)(__)  (__)(__) (__)   . cafe      
 
 * 
 */

contract BasicERC721 is
    Context,
    Ownable,
    Pausable,
    ERC721Enumerable,
    ERC721URIStorage
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _nextTokenId;
    uint256 public mintPrice = 0.0 ether;
    string public baseURI = "";

    event TokenMinted(uint256 newItemId, address to, string tokenURI);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        _nextTokenId.increment();
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function mint(string memory _tokenURI) public payable {
        require(
            mintPrice <= msg.value,
            "Not enough value sent to mint. Please check current mint price."
        );

        uint256 newItemId = _nextTokenId.current();
        _safeMint(msg.sender, newItemId);
        _nextTokenId.increment();
        _setTokenURI(newItemId, _tokenURI);

        emit TokenMinted(newItemId, msg.sender, _tokenURI);
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
        @dev Witdraws all the balance from the contract. 
     */
    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    /**
        @dev Returns the total tokens minted so far.
     */
    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev Get Ids of NFT by the given address.
     */
    function getNftByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /**
     * [override] functions
     */

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "Pausable: token transfer/minting while paused");
    }
}
