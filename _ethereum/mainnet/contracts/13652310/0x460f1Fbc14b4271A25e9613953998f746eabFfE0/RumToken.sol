/**
 *
 * Copyright Notice: User must include the following signature.
 *
 * Smart Contract Developer: www.QambarRaza.com
 *
 * ..#######.....###....##.....##.########.....###....########.
 * .##.....##...##.##...###...###.##.....##...##.##...##.....##
 * .##.....##..##...##..####.####.##.....##..##...##..##.....##
 * .##.....##.##.....##.##.###.##.########..##.....##.########.
 * .##..##.##.#########.##.....##.##.....##.#########.##...##..
 * .##....##..##.....##.##.....##.##.....##.##.....##.##....##.
 * ..#####.##.##.....##.##.....##.########..##.....##.##.....##
 * .########.....###....########....###...
 * .##.....##...##.##........##....##.##..
 * .##.....##..##...##......##....##...##.
 * .########..##.....##....##....##.....##
 * .##...##...#########...##.....#########
 * .##....##..##.....##..##......##.....##
 * .##.....##.##.....##.########.##.....##
 */

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract RumToken is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IERC721Enumerable token;
    
    uint256 private MAX_NFT = 3333;
    address public PIRACY_CONTRACT_ADDRESS;

    mapping(uint256 => bool) public tokensMinted;

    string private baseURI;

    constructor( 
            string memory name,
            string memory symbol, 
            address piracyPunkContractAddress
        ) ERC721(name, symbol) {
        PIRACY_CONTRACT_ADDRESS = piracyPunkContractAddress;
        token = IERC721Enumerable(PIRACY_CONTRACT_ADDRESS);
    }

    function setSaleLimit(uint256 limit) public onlyOwner {
        MAX_NFT = limit;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _mint(uint256 tokenOwnerTokenIndex) private {
        try token.tokenOfOwnerByIndex(msg.sender, tokenOwnerTokenIndex) {
            
            uint256 tokenId = token.tokenOfOwnerByIndex(msg.sender, tokenOwnerTokenIndex);

            uint256 mintIndex = totalSupply();

            require(mintIndex < MAX_NFT, "Sold Out!");

            require(!tokensMinted[tokenId], "You cannot claim against this PiracyPunk twice");

            _safeMint(msg.sender, mintIndex);

            tokensMinted[tokenId] = true;

        
        } catch (bytes memory) {
            revert();
        }
    }

    function mint()
        external payable {
        
        require(token.balanceOf(msg.sender) > 0, "You need to buy PiracyPunks first.");

        uint256 totalOwned = token.balanceOf(msg.sender);
        uint256 numberOfTokensMinted = 0;

        for (uint256 i = 0; i < totalOwned; i++) {
            if (!tokensMinted[token.tokenOfOwnerByIndex(msg.sender, i)]) {
                _mint(i);
                numberOfTokensMinted++;
            }
        }
        require(numberOfTokensMinted > 0, "Not allowed!");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
}