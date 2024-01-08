/**
* @title MonsterMobs contract
* @dev Extends ERC721Enumerable Non-Fungible Token Standard
*/

/**
*  SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.0;

/*
   _____                          __                    _____        ___.           
  /     \   ____   ____   _______/  |_  ___________    /     \   ____\_ |__   ______
 /  \ /  \ /  _ \ /    \ /  ___/\   __\/ __ \_  __ \  /  \ /  \ /  _ \| __ \ /  ___/
/    Y    (  <_> )   |  \\___ \  |  | \  ___/|  | \/ /    Y    (  <_> ) \_\ \\___ \ 
\____|__  /\____/|___|  /____  > |__|  \___  >__|    \____|__  /\____/|___  /____  >
        \/            \/     \/            \/                \/           \/     \/ 
*/

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Strings.sol";

contract MonsterMobsERC721 is ERC721Enumerable, Ownable, AccessControl
{
    using Strings for uint256;

    // =======================================================
    // ROLES
    // =======================================================
    bytes32 public constant PROJECT_OWNERS_ROLE = keccak256("PROJECT_OWNERS_ROLE");

    // =======================================================
    // EVENTS
    // =======================================================
    event TokenUriUpdated(uint256 tokenId, string uri);
    event TokenMinted(uint256 tokenIndex, address minter);
    event MintPriceChanged(uint256 newPrice);

    // =======================================================
    // STATE
    // =======================================================
    bool public saleIsActive = false;

    // supply and reservation
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant NUM_RESERVED_MOBS = 100;
    uint8 public constant MAX_MOBS_PER_PURCHASE = 5;

    // accounting
    uint256 public mintPrice = 0.08 ether;
    
    // general vars, counter, etc
    string private _baseURIExtended;
    mapping (uint256 => string) private _tokenURIs;
    uint8 private numTeamMobsReserved = 0;

    // =======================================================
    // CONSTRUCTOR
    // =======================================================
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _fsgAdmin
    )
        ERC721(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PROJECT_OWNERS_ROLE, msg.sender);
        _setupRole(PROJECT_OWNERS_ROLE, _fsgAdmin);
        
        _baseURIExtended = _baseUri;
    }

    // =======================================================
    // ADMIN
    // =======================================================
    function toggleSaleState()
        public
        onlyRole(PROJECT_OWNERS_ROLE)
    {
        saleIsActive = !saleIsActive;
    }

    function changeMintPrice(uint256 _newPrice)
        public
        onlyRole(PROJECT_OWNERS_ROLE)
    {
        mintPrice = _newPrice;
        emit MintPriceChanged(_newPrice);
    }

    function setBaseUri(string memory _newBaseUri)
        public
        onlyRole(PROJECT_OWNERS_ROLE)
    {
        _baseURIExtended = _newBaseUri;
    }

    function reserveMobs(uint8 numRequestedReservations)
        public
        onlyRole(PROJECT_OWNERS_ROLE)
    {
        require((numTeamMobsReserved + numRequestedReservations) <= NUM_RESERVED_MOBS, "Reservation requests exceeds reservation cap");
        
        uint8 i;
        for (i = 0; i < numRequestedReservations; i++) {
            numTeamMobsReserved ++;
            _safeMint(msg.sender, totalSupply());
            emit TokenMinted(totalSupply() - 1, msg.sender);
        }
    }

    function updateTokenURI(uint256 _tokenId, string memory _newTokenURI)
        public
        onlyRole(PROJECT_OWNERS_ROLE)
    {
        _tokenURIs[_tokenId] = _newTokenURI;
        emit TokenUriUpdated(_tokenId, _newTokenURI);
    }

    function withdrawFunds(address payable recipient, uint256 amount)
        public
        onlyOwner
    {
        require(recipient != address(0), "Invalid recipient address");
        recipient.transfer(amount);
    }

    // =======================================================
    // INTERNAL UTILS
    // =======================================================
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // =======================================================
    // PUBLIC API
    // =======================================================
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // if a custom tokenURI has not been set, return base + tokenId
        if(bytes(_tokenURI).length == 0) {
            return string(abi.encodePacked(base, tokenId.toString()));
        }

        // a custom tokenURI has been set - likely after metadata IPFS migration
        return _tokenURI;
    }

    function getSupplyData()
        public
        view
        returns(
            uint256 _maxSupply,
            uint256 _totalSupply,
            uint256 _mintPrice,
            bool _saleIsActive)
    {
        _maxSupply = MAX_SUPPLY;
        _totalSupply = totalSupply();
        _mintPrice = mintPrice;
        _saleIsActive = saleIsActive;
    }

    function mint(uint numberOfMobs)
        public
        payable
    {
        require(saleIsActive, "Sale is not active at the moment");
        require(numberOfMobs > 0, "Number of mobs must be larger than 0");
        require(totalSupply() + numberOfMobs <= MAX_SUPPLY, "Purchase would exceed max supply of Mobs");
        require(numberOfMobs <= MAX_MOBS_PER_PURCHASE,"Can only mint up to 5 per purchase");
        require(msg.value >= mintPrice * numberOfMobs, "Insufficient ether sent");

        // mint mobs
        for (uint i = 0; i < numberOfMobs; i++) {
            _safeMint(msg.sender, totalSupply());
            emit TokenMinted(totalSupply() - 1, msg.sender);
        }
    }
}