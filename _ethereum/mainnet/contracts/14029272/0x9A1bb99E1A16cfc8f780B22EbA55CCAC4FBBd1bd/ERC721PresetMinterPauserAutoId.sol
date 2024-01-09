// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";

/**
* NiftyZoo Elephants!
*
* First 500 mints are free + gas!
* Remaining only 0.025 ETH + gas each!
*
* Delayed reveal after 8888 elephants have been minted!
*
* Mint on: https://niftyzoo.art/
* Discord: https://discord.gg/8e7vXVpZkj
* Twitter: https://twitter.com/niftyzooart
*/
contract NiftyZooElephants is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable
{

    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public price = 25000000000000000; // the price per NFT after free minting
    uint256 public mint_max = 15; // amount of max. NFTs that may be minted with one wallet in one tx
    uint256 public free_minted = 0; // amount of NFTs that have been minted for free
    uint256 public free_mint_max = 500; // amount of max. free NFTs that may be minted
    uint256 public total_max = 8888; // the total target supply of this collection
    address public project = 0x992be68778663A415da230E3E647f7E3E1B806dC; // the project's share address

    Counters.Counter private _tokenIdTracker;
    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {

        _baseTokenURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
    * MINT FUNCTION:
    *
    * 1 to 15 mints per wallet and transaction.
    * First 500 mints are free + gas.
    * Remaining mints 0.025 ETH each + gas.
    *
    * Delayed reveal after 8888 elephants have been minted.
    */
    function mint(uint256 _amount) public virtual payable {
        
        require(_amount > 0 && _amount <= mint_max, "mint(): max. allowed mint per wallet and transaction reached.");
        require(totalSupply() + _amount <= total_max, "mint(): max. supply reached.");

        if(free_minted >= free_mint_max) {

            require(msg.value == price * _amount, "mint(): please send the exact amount of ETH.");

        } else {

            require(msg.value == 0, "mint(): minting is free.");
            require(free_minted + _amount <= free_mint_max, "mint(): max. free mints reached.");

            free_minted += _amount;
        }
        
        for(uint256 i = 0; i < _amount; i++) {

            _mint(_msgSender(), _tokenIdTracker.current() + 1);
            _tokenIdTracker.increment();
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
          
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
    
        return _baseTokenURI;
    }
    
    function setBaseUri(string calldata baseTokenURI) public virtual {

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setBaseUri: must have admin role to set base uri.");

        _baseTokenURI = baseTokenURI;
    }

    function withdraw() public virtual {
        
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "withdraw(): must have admin role to withdraw.");

        (bool success, ) = payable(project).call{value:address(this).balance}("");
        require(success, "withdraw(): eth transfer to project failed.");
    }

    function setProject(address _project) public virtual{

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setProject(): must have admin role.");

        project = _project;
    }

    function _beforeTokenTransfer (
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
