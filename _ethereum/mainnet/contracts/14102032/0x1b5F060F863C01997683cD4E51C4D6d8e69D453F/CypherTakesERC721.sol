// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";

contract CypherTakesERC721 is
  ERC721,
  ERC721Enumerable,
  Ownable,
  Pausable,
  ContextMixin,
  NativeMetaTransaction
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    // The current count will be used to give a new mint it's ID.
    Counters.Counter private _tokenIdCounter;
    // The maximum amount of NFTs which can be minted. Remember that this is actually 6, as all integers start at 0.
    uint256 public maxSupply = 1024;
    // Initial BASE_TOKEN_URI
    string private BASE_TOKEN_URI;
    // Initial Contract URI
    string private CONTRACT_URI;
    // Mapping Token Burned
    mapping (uint256 => address) private _burned;
    // Proxy Regiter Address
    address private _proxyRegistry;

    constructor(
      string memory name_,
      string memory symbol_,
      address proxyRegistry_
    ) public ERC721(name_, symbol_) {
        BASE_TOKEN_URI = "https://api.cypherverse.io/os/collections/cyphertakes/";
        CONTRACT_URI = "https://api.cypherverse.io/os/collections/cyphertakes";
        _proxyRegistry = proxyRegistry_;
        _tokenIdCounter.increment();
    }


    // The Metadata uri, containing all the json files for this contract's NFTs.
    function _baseURI() internal view override returns (string memory){
        return BASE_TOKEN_URI;
    }

    // Returns the json file of the corresponding token ID.
    // Used for getting things like the NFT's name, properties, description etc.
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    return string(abi.encodePacked(
        _baseURI(),
        Strings.toString(_tokenId)
        ));
    }

    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(_proxyRegistry)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * @notice Method for reduce the friction with openSea allows to map the `tokenId`
     * @dev into our NFT Smart contract and handle some metadata offchain in OpenSea
    */
    function baseTokenURI() public view returns (string memory) {
        return BASE_TOKEN_URI;
    }

    /**
     * @notice Method for reduce the friction with openSea allows update the Base Token URI
     * @dev This method is only available for the owner of the contract
     * @param _baseTokenURI The new base token URI
     */

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner() {
        BASE_TOKEN_URI = _baseTokenURI;
    }

    /**
     * @notice Method for reduce the friction with openSea allows to map the `tokenId`
     * @dev into our NFT Smart contract and handle some metadata offchain in OpenSea
    */
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC721.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC721Pausable}.
     */
    function pause(bool status) public onlyOwner() {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }


    // The minting function, needed to create an NFT
    function safeMint(address to) public onlyOwner() {
        // Checks if the maximum supply is greater than the current amount of NFTs that have been minted so far.
        // If it is greater, then anyone can mint. But if it isn't greater then that means the maximum amount of NFTs which can be minted has been reached.
        require(maxSupply > totalSupply(), "CypherTakes: Exceed Max Supply");
        // Gives the to be minted NFT it's ID.
        uint256 tokenId = _tokenIdCounter.current();
        // Increases the tokenID counter so that the next NFT to be minted doesn't have the same ID as the one that is about to be minted.
        _tokenIdCounter.increment();
        // Mints the NFT
        _safeMint(to, tokenId);
    }

    // The minting function, needed to create an NFT
    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "CypherTakesERC721: token must be exist");
        _burned[tokenId] = msg.sender;
        _burn(tokenId);
    }

    // The minting function, needed to create an NFT
    function safeMintAfterBurn(address to, uint256 tokenId) public onlyOwner() {
        require(!_exists(tokenId), "CypherTakesERC721: token don't must be exist");
        require(_burned[tokenId] != address(0), "CypherTakesERC721: token must had been burned");
        // Mints the NFT
        _safeMint(to, tokenId);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override(Context)
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        require(!paused(), "CypherTakesERC721: token transfer while paused");
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
