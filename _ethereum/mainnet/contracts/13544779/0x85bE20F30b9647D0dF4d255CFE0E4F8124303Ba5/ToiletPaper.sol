// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Context.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

import "./Ownable.sol";

import "./Strings.sol";


contract ToiletPaper is
    Context,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    PaymentSplitter,
    ReentrancyGuard,
    Ownable
{
    string private _baseTokenURI;

    uint256 public costToMint = 50000000000000000;
    uint256 public supply = 10000;
    uint256 public currentTokenId = 1;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address[] memory payees, 
        uint256[] memory shares
    ) ERC721(name, symbol) PaymentSplitter(payees, shares) Ownable() {
        _baseTokenURI = baseTokenURI;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString((tokenId)), '.json'));
    }

    modifier whenNotOutOfTokens() {
        require(currentTokenId < supply, "Out of tokens");
        _;
    }

    /**
     * @dev Allows public to purchase at token
    */
    function mint() payable public virtual nonReentrant whenNotPaused whenNotOutOfTokens {
        require(msg.value >= costToMint, 'Less than costToMint');
        _mint(_msgSender(), currentTokenId);
        currentTokenId++;
    }

    function mintByOwner(address to, uint256 howMany) public nonReentrant whenNotPaused whenNotOutOfTokens onlyOwner{
        require(howMany > 0, 'Have to mint at least 1');

        for(uint256 i=0; i < howMany; i++){
             _mint(to, currentTokenId);
             currentTokenId++;
        } 
    }

    function setSupply(uint256 _supply) public virtual onlyOwner {
        supply = _supply;
    }

    function setCostToMint(uint256 _costToMint) public virtual onlyOwner {
        costToMint = _costToMint;
    }

    function pause() public virtual onlyOwner{
        _pause();
    }

    function unpause() public virtual onlyOwner{
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}