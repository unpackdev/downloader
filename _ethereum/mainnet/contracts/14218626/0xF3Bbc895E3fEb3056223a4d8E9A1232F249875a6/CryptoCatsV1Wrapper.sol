// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./CryptoCatsV1Contract.sol";

/**
 * @title CryptoCatsV1Wrapper contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation.
 * based on the V1 wrapper of @author @foobar, but optimised to work with our MarketPlace contract.
 * @author @cryptotato
 */
contract CryptoCatsV1Wrapper is Ownable, ERC721 {

    address payable public catAddress = payable(0x19c320b43744254ebdBcb1F1BD0e2a3dc08E01dc);
    string private _baseTokenURI;
    uint256 private _tokenSupply;


    constructor() ERC721("V1 CryptoCats (Wrapped)", "WCCAT") {
        _baseTokenURI = "ipfs://QmRKVBdB77hmrbJtbHq44RXDfP52V7u3UP8EzSNT4d2cc5/";
    }

    /**
     * @dev Accepts an offer from the cats contract and assigns a wrapped token to msg.sender
     */
    function wrap(uint _catId) external payable {
        // Prereq: owner should call `offerCatForSaleToAddress` with price 0 (or higher if they wish)
        (bool isForSale, , address seller, uint minPrice, address sellOnlyTo) = CryptoCatsV1Contract(catAddress).catsForSale(_catId);
        require(isForSale == true);
        require(seller == msg.sender);
        require(minPrice == 0);
        require((sellOnlyTo == address(this)) || (sellOnlyTo == address(0x0)));
        // Buy the punk
        CryptoCatsV1Contract(catAddress).buyCat{value: msg.value}(_catId);
        _tokenSupply +=1;
        // Mint a wrapped punk
        _mint(msg.sender, _catId);
    }

    /**
     * @dev Burns the wrapped token and transfers the underlying cat to the owner
     **/
    function unwrap(uint256 _catId) external {
        require(_isApprovedOrOwner(msg.sender, _catId));
        _burn(_catId);
        _tokenSupply -=1;
        CryptoCatsV1Contract(catAddress).transfer(msg.sender, _catId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Set a new base token URI
     */
    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }
    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _tokenSupply;
    }
}