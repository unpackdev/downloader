// SPDX-License-Identifier: LicenseRef-StarterLabs-Business-Source
/*
-----------------------------------------------------------------------------
The Licensed Work is (c) 2022 Starter Labs, LLC
Licensor:             Starter Labs, LLC
Licensed Work:        OpenStarter v1
Effective Date:       2022 March 1
Full License Text:    https://github.com/StarterXyz/LICENSE
-----------------------------------------------------------------------------
 */
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC2981PerTokenRoyalties.sol";

/**
 * @title OpenStarterNft
 * OpenStarterNft - ERC721 contract that has minting functionality.
 */
contract OpenStarterNft is ERC721, ERC2981PerTokenRoyalties, Ownable {
    using SafeMath for uint256;
    struct Attributes {
        string sName;
        uint256 uMin;
        uint256 uMax;
        uint256 uType;
    }
    /// @dev Events of the contract
    event Minted(uint256 tokenId, address beneficiary, address minter);

    string public logo; // Preview Logo File
    string public collection; // Collection Name
    string public description; // Description
    string public utility; // Description
    uint256 public royalty; // royalty percentage
    address public royaltyReceiver; // royalty receiver address

    uint256 public maxQuantityMinted; // total maxQuantityMinted of NFTs

    bytes32 public website; // url of website
    bytes32 public discord; // url of discord
    bytes32 public twitter; // url of twitter
    bytes32 public medium; // url of medium
    bytes32 public telegram; // url of telegram
    string public logoUrl; // url of Logo
    string public unlockable; // Unlockable content
    bool public isExplicit; // is Explicit Content

    mapping(uint256 => Attributes) public levels;

    uint256 private _nextTokenId = 0;

    address public nftFactory; // nftFactory address
    address public saleFactory; // saleFactory address
    address public creator; // creator address

    mapping(address => bool) public minters; // minter addresses
    string public baseUri;

    modifier onlyMinter() {
        require(owner == msg.sender || minters[msg.sender], "1");
        _;
    }

    modifier onlyFactory() {
        require(
            owner == msg.sender ||
                nftFactory == msg.sender ||
                saleFactory == msg.sender,
            "2"
        );
        _;
    }

    /// @notice Contract constructor
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxQuantityMinted
    ) public ERC721(_name, _symbol, _maxQuantityMinted, _maxQuantityMinted) {
        maxQuantityMinted = _maxQuantityMinted;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981PerTokenRoyalties)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981PerTokenRoyalties.supportsInterface(interfaceId);
    }

    function setAddressInfo(
        address _creator,
        address _nftFactory,
        address _saleFactory,
        address _owner
    ) external onlyOwner {
        creator = _creator;
        nftFactory = _nftFactory;
        saleFactory = _saleFactory;
        owner = _owner;
    }

    /**
     *  @dev Set Preview Infos (Logo, Collection Name, Description and Utility)
     *
     */
    function setPreviewInfo(
        string memory _logo,
        string memory _collection,
        string memory _description,
        string memory _utility,
        uint256 _royalty,
        address _royaltyReceiver
    ) external onlyFactory {
        logo = _logo;
        collection = _collection;
        description = _description;
        utility = _utility;
        royalty = _royalty;
        royaltyReceiver = _royaltyReceiver;
    }

    /**
     *  @dev Set Social Information
     *
     */
    function setSocialInfo(
        bytes32 _website,
        bytes32 _discord,
        bytes32 _twitter,
        bytes32 _medium,
        bytes32 _telegram,
        string calldata _logoUrl,
        string calldata _unlockable,
        bool _isExplicit
    ) external onlyFactory {
        website = _website;
        discord = _discord;
        twitter = _twitter;
        medium = _medium;
        telegram = _telegram;
        logoUrl = _logoUrl;
        unlockable = _unlockable;
        isExplicit = _isExplicit;
    }

    /**
     *  @dev Set Level Information
     *
     */
    function setLevelInfo(
        uint256 _level,
        string memory _name,
        uint256 _min,
        uint256 _max,
        uint256 _type
    ) external onlyFactory {
        levels[_level].sName = _name;
        levels[_level].uMin = _min;
        levels[_level].uMax = _max;
        levels[_level].uType = _type;
    }

    /**
     * @dev Set Minter Address
     */

    function setMinter(address _newMinter) external onlyFactory {
        minters[_newMinter] = true;
    }

    function removeMinter(address _minter) external onlyFactory {
        minters[_minter] = false;
    }

    function setBaseUrl(string memory _baseUrl) external onlyFactory {
        super._setBaseURI(_baseUrl);
        baseUri = _baseUrl;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mint(address _to) external onlyMinter returns (uint256) {
        uint256 newTokenId = getNextTokenId();
        _safeMint(_to, 1);
        if (royalty > 0) {
            _setTokenRoyalty(newTokenId, royaltyReceiver, royalty); // royalty = percentage of minting price
        }
        _incrementTokenId();
        emit Minted(newTokenId, _to, _msgSender());

        return newTokenId;
    }

    /**
     * @dev calculates the next token ID based on value of _nextTokenId
     * @return uint256 for the next token ID
     */
    function getNextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev increments the value of _nextTokenId
     */
    function _incrementTokenId() private {
        require(_nextTokenId < maxQuantityMinted, "sold out");
        _nextTokenId++;
    }

    /**
     * @dev checks the given token ID is approved either for all or the single token ID
     */
    function isApproved(uint256 _tokenId, address _operator)
        public
        view
        returns (bool)
    {
        return
            isApprovedForAll(ownerOf(_tokenId), _operator) ||
            getApproved(_tokenId) == _operator;
    }
}
