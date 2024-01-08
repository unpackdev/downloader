// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

import "./TreasuryNode.sol";

/**
 * @title Faktura NFTs implemented using the ERC-721 standard.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract FakturaMintableV2 is
Initializable,
TreasuryNode,
OwnableUpgradeable,
ERC721Upgradeable,
ERC721EnumerableUpgradeable,
ERC721BurnableUpgradeable,
UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Metadata {
        uint256 id;
        uint256 amount;
        CountersUpgradeable.Counter counter;
    }

    // if a token's URI has been locked or not
    mapping(uint256 => bool) public tokenURILocked;
    // Mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    // Mint allowed per address
    mapping (address => uint) private mintCnt;
    // Mapping for token Metadata
    Metadata[] private _tokenMetadata;
    // gets incremented to placehold for tokens not minted yet
    uint256 public expectedTokenSupply;
    // Max mint per Address
    uint256 public maxMintPerAddress;
    // Counter for mint
    CountersUpgradeable.Counter public _tokenIdCounter;
    // Mint Price
    uint256 public mintPrice;
    // Mint Price
    uint256 private mintReserve;
    //Metadata URI
    string private metadataURI;
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 _mintPrice,
        uint256 _maxMintPerAddress,
        uint256 _mintReserve,
        uint256[] memory _metadataAmount,
        string memory _metadataURI,
        address payable _fakturaPaymentAddress,
        address payable _creatorPaymentAddress,
        uint256 _secondaryFakturaFeeBasisPoints,
        uint256 _secondaryCreatorFeeBasisPoints
    ) public initializer {
        __TreasuryNode_init(_fakturaPaymentAddress, _creatorPaymentAddress, _secondaryFakturaFeeBasisPoints, _secondaryCreatorFeeBasisPoints);
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        // set the initial mint mintPrice
        mintPrice = _mintPrice;
        // set the initial mint mintPrice
        maxMintPerAddress = _maxMintPerAddress;
        // set the metadata URI
        metadataURI = _metadataURI;
        // set the reserve
        mintReserve = _mintReserve;

        for (uint256 i = 0; i < _metadataAmount.length; i++) {
            Metadata memory newMetadata = Metadata({
                id: i,
                amount: _metadataAmount[i],
                counter: _tokenIdCounter
            });
            expectedTokenSupply += _metadataAmount[i];
            _tokenMetadata.push(newMetadata);
        }

        require(expectedTokenSupply > 0);
        require(mintPrice >= 0);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(_revealed) {
            return string(abi.encodePacked(_tokenBaseURI, StringsUpgradeable.toString(tokenId), ".json"));
        } else {
            return "ipfs://QmPfkgV2j4abi8yCiaEGDUpkPTKZhcZ3CANVWp3LSwUxEd/unrevealed.json";
        }
    }

    function totalSupply() public view virtual override returns (uint256) {
        return expectedTokenSupply;
    }

    modifier limited {
        require(_tokenIdCounter.current() < totalSupply() - mintReserve, "There's no token to mint.");
        _;
    }

    function safeMint(address to) public payable limited {
        require(mintCnt[msg.sender] < maxMintPerAddress, "One address can mint 10 tickets.");
        if(mintPrice > 0) require(mintPrice == msg.value, "Mint price is not correct.");
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        mintCnt[msg.sender]++;
    }

    function safeBatchMint(address to, uint256 amount) public payable {
        require(_tokenIdCounter.current() + amount <= totalSupply() - mintReserve, "There's no token to mint.");
        require(mintCnt[msg.sender] + amount <= maxMintPerAddress, "One address can mint 10 tickets.");
        if(mintPrice > 0) require(mintPrice * amount == msg.value, "Mint price is not correct.");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            mintCnt[msg.sender]++;
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
        uint256[46] private __gap;

    // ** - ADMIN - ** //

    //TokenBase URI
    string private _tokenBaseURI;
    //TokenBase Reveal
    bool private _revealed;

    function withdraw() external onlyOwner {
        (uint256 secondaryFakturaFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = getFeeConfig();
        uint256 balance = address(this).balance;
        //Pay to Treasury
        payable(getTreasury()).transfer((balance * secondaryFakturaFeeBasisPoints) / 100);
        //Pay to Creator
        payable(getTokenCreatorPaymentAddress()).transfer((balance * secondaryCreatorFeeBasisPoints) / 100);
    }

    function reveal(string memory uri) public onlyOwner {
        require(_revealed == false, "Already revealed.");
        _tokenBaseURI = uri;
        _revealed = true;
    }

    function safeReserveMint(address to, uint256 amount) public onlyOwner {
        require(_tokenIdCounter.current() + amount < totalSupply(), "There's no token to mint.");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            mintCnt[msg.sender]++;
        }
    }

    function setReserve(uint256 _mintReserve) public onlyOwner {
        mintReserve = _mintReserve;
    }
}