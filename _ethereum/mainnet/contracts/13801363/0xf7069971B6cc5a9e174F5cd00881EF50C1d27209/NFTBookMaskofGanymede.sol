// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./INCT.sol";

/// @custom:security-contact robbie@wippublishing.com
contract NFTBMaskofGanymede is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    IERC721Enumerable private _goldenTicket;
    IERC721Enumerable private _relic;
    
    uint256 _price;
    uint256 public constant NAME_CHANGE_PRICE = 2000 * (10 ** 18);
    uint256 public constant MAX_SUPPLY = 1024;
    
    mapping(uint256 => bool) private _usedGoldenTickets;
    mapping(uint256 => string) private _tokenName;

    // the NCT contract pointer
    INCT private _nct;

    string _BaseNFTBookURI = "ipfs://QmbDuYt6NwMbULwVtJWr71EiL5DBAatEYCHjFWgj52TFuR";

    // Events
    event NameChange (uint256 indexed tokenId, string newName);

    constructor(address gtAddress, address rlAddress, address nctAddress, uint256 price) ERC721("NFTBookMaskofGanymede", "NFTBA") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        
        _goldenTicket = IERC721Enumerable(gtAddress);
        _relic = IERC721Enumerable(rlAddress);
        _nct = INCT(nctAddress);
        _price = price;
    }

    /**
    * @dev Update the token URI
    */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyRole(MINTER_ROLE) {
        _setTokenURI(tokenId, _tokenURI);
    }
    
    /**
    * @dev Returns true if the caller can claim.
    * In this case the second returned parameter contains a valid Golden Ticket token ID
    */
    function canClaim() public view returns (bool, uint256) {
        uint256 goldenTicketId  = 0;
        bool    claimFlag = false;
        uint256 numTokens = (_relic.balanceOf(_msgSender()) > 0)
                          ? _goldenTicket.balanceOf(_msgSender())
                          : 0;

        for(uint256 i = 0; (!claimFlag) && (i < numTokens); i++){
            goldenTicketId  = _goldenTicket.tokenOfOwnerByIndex(_msgSender(), i);
            claimFlag = ! _usedGoldenTickets[goldenTicketId];
        }
        
        return (claimFlag, goldenTicketId);
    }

    /**
     * @dev Mint a new ticket by providing the token ID (limited to max supply of golden tickets)
     */
    function claim(uint256 goldenTicketId) public whenNotPaused {
        require(_goldenTicket.ownerOf(goldenTicketId) == _msgSender(), "Caller does not own this Golden Ticket");
        require(_relic.balanceOf(_msgSender()) > 0,                    "Caller does not own a relic");
        require(!_usedGoldenTickets[goldenTicketId],                   "Golden Ticket already used");

        uint256 tokenID = totalSupply();
        _usedGoldenTickets[goldenTicketId] = true;
        _safeMint(_msgSender(), tokenID);
        _setTokenURI(tokenID, _BaseNFTBookURI);
    }

    function Mint() payable public whenNotPaused {
        require(totalSupply() < MAX_SUPPLY);
        require(_price == msg.value, "Ether value sent is not correct");
        
        uint256 tokenID = totalSupply();
        _safeMint(_msgSender(), tokenID);
        _setTokenURI(tokenID, _BaseNFTBookURI);
    }
    
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

      /**
     * @dev Changes the name for Hashmask tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");

        _nct.transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);

        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    function withdrawNCT(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 nctBalance = _nct.balanceOf(address(this));
        _nct.transfer(to, nctBalance);
    }

    function withdraw(address _destination) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        uint balance = address(this).balance;
        (bool success, ) = _destination.call{value:balance}("");
        return success;
    }
    
    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyRole(MINTER_ROLE)
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        // remove storage variables for that token - how?
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}