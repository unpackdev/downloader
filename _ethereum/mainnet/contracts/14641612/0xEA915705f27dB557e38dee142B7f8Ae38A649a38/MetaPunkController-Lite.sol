// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./console.sol";

import "./IMetaPunk2018.sol";
import "./IPunk.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

// Ownable, reentrancyguard, ERC721 interface

interface IDAOTOKEN {
    function safeMint(address) external;

    function transferOwnership(address) external;
}

interface ExternalMintList {
    function isOnList(address) external returns (bool);

    function updateList(address) external;
}

contract MPCLITE is Ownable, ReentrancyGuard {
    using Address for address payable;

    // connected contracts
    IMetaPunk2018 public metaPunk;

    uint256 public mintFee;
    address payable public vault;
    bool public paused = false;
    uint256 public tokenId;
    string public baseUri;

    // white list members
    mapping(address => bool) public whiteList;
    uint256 public whiteListMintFee;
    uint256 public whiteListMintLimit;

    // White list
    bool public isWhiteListOpen = false;
    bool public isWhiteListMintOpen = false;
    uint256 public publicMintLimit = 8000;
    uint256 public whiteListTotalMintLimit = 4000;

    ExternalMintList public externalList;
    bool public externalListIsEnabled = false;

    // Reserved Tokens
    mapping(uint256 => bool) internal reservedTokens;

    // List of folks who helped get project off the ground
    mapping(address => uint256) public bootstrapList;
    // mapping(address => bool) public receivedDAOToken;
    event BootStrappersAdded(address[] Users, uint256[] Amounts);

    // DAO Token
    address public pridePunkTreasury;

    event MetaPunk2022Created(uint256 tokenId);

    // events
    // event PunkClaimed(uint256 punkId, address claimer);
    event PausedState(bool paused);
    event FeeUpdated(uint256 mintFee);
    event WhiteListFeeUpdated(uint256 mintFee);

    modifier whenNotPaused() {
        require(!paused, "Err: Contract is paused");
        _;
    }

    modifier whileTokensRemain() {
        require(tokenId < 10000, "err: all pride punks minted");
        _;
    }

    modifier whilePublicTokensRemain() {
        require(tokenId < publicMintLimit, "err: all public sale NFTs minted");
        _;
    }

    function updatePublicMintLimit(uint256 _publicMintLimit) public onlyOwner {
        publicMintLimit = _publicMintLimit;
    }

    // Set the MetaPunk2018 contracts' Punk Address to address(this)
    // Set the v1 Wrapped Punk Address
    // Set the v2 CryptoPunk Address
    function setup(
        uint256 _mintFee,
        uint256 _whiteListMintFee,
        uint256 _whiteListMintLimit,
        string memory _baseUri,
        IMetaPunk2018 _metaPunk,
        address payable _vault,
        address _pridePunkTreasury
    ) public onlyOwner {
        metaPunk = _metaPunk;
        mintFee = _mintFee;
        whiteListMintFee = _whiteListMintFee;
        whiteListMintLimit = _whiteListMintLimit;
        baseUri = _baseUri;
        vault = _vault;
        metaPunk.Existing(address(this));
        pridePunkTreasury = _pridePunkTreasury;

        // Set Token ID to the next in line.
        // Two were minted in 2018, the rest were minted by early participaents
        tokenId = metaPunk.totalSupply() - 2;

        emit FeeUpdated(mintFee);
    }

    function ownerMultiMint(address[] memory recipients, uint256[] memory amounts)
        public
        onlyOwner
        nonReentrant
        whileTokensRemain
    {
        require(recipients.length == amounts.length, "err: array length mismatch");

        for (uint256 x = 0; x < recipients.length; x++) {
            // for each recipient, mint them (amounts) of tokens
            for (uint256 y = 0; y < amounts[x]; y++) {
                _mint(recipients[x]);
            }
        }
    }

    function ownerMintById(uint256 _tokenId) public onlyOwner {
        require(!metaPunk.exists(_tokenId), "err: token already exists");
        metaPunk.makeToken(_tokenId, _tokenId);
        metaPunk.seturi(_tokenId, string(abi.encodePacked(baseUri, Strings.toString(_tokenId))));
        emit MetaPunk2022Created(_tokenId);

        // transfer metaPunk to msg.sender
        metaPunk.transferFrom(address(this), msg.sender, _tokenId);
    }

    function ownerMultipleMintById(uint256[] memory _tokenIds) public onlyOwner {

        for(uint x = 0; x < _tokenIds.length; x++){
        require(!metaPunk.exists(_tokenIds[x]), "err: token already exists");
        metaPunk.makeToken(_tokenIds[x], _tokenIds[x]);
        metaPunk.seturi(_tokenIds[x], string(abi.encodePacked(baseUri, Strings.toString(_tokenIds[x]))));
        emit MetaPunk2022Created(_tokenIds[x]);

        // transfer metaPunk to msg.sender
        metaPunk.transferFrom(address(this), msg.sender, _tokenIds[x]);

        }
    }

    function togglePause() public onlyOwner {
        paused = !paused;
        emit PausedState(paused);
    }

    function updateMintFee(uint256 _mintFee) public onlyOwner {
        mintFee = _mintFee;
        emit FeeUpdated(mintFee);
    }

    function updateWhiteListMintFee(uint256 _mintFee) public onlyOwner {
        whiteListMintFee = _mintFee;
        emit WhiteListFeeUpdated(mintFee);
    }

    // MetaPunk2018 Punk Contract replacement
    // Must be implemented for the 2018 version to work
    function punkIndexToAddress(uint256) external returns (address) {
        // Return the address of the MetaPunk Contract
        return address(metaPunk);
    }

    function balanceOf(address _user) external returns (uint256) {
        return metaPunk.balanceOf(_user);
    }

    // This is needed in case this contract doesn't work and we need to transfer it again
    function transferOwnershipUnderlyingContract(address _newOwner) public onlyOwner {
        metaPunk.transferOwnership(_newOwner);
    }

    function sendToVault() public {
        vault.sendValue(address(this).balance);
    }

    event OwnedTokenURIUpdated(uint256 token);

    function updateMetaData(uint256[] memory _tokenId) public {
        for (uint256 x = 0; x < _tokenId.length; x++) {
            // require the user to own this token
            if (metaPunk.ownerOf(_tokenId[x]) == msg.sender) {
                metaPunk.seturi(_tokenId[x], string(abi.encodePacked(baseUri, Strings.toString(_tokenId[x]))));
                emit OwnedTokenURIUpdated(_tokenId[x]);
            }
        }
    }

    function _mint(address _recipient) internal {
        require(tokenId < 10000, "err: all pride punks minted");

        _findNextToken();

        metaPunk.makeToken(tokenId, tokenId);
        metaPunk.seturi(tokenId, string(abi.encodePacked(baseUri, Strings.toString(tokenId))));
        emit MetaPunk2022Created(tokenId);

        // transfer metaPunk to msg.sender
        metaPunk.transferFrom(address(this), _recipient, tokenId);

        // increment the tokenId
        tokenId++;
    }

    function setReservedTokens(uint256[] memory _reservedTokenIds) public onlyOwner {
        for (uint256 x = 0; x < _reservedTokenIds.length; x++) {
            reservedTokens[_reservedTokenIds[x]] = true;
        }
    }

    // recursive
    function _findNextToken() internal {
        // maybe we should reserve specials
        if (metaPunk.exists(tokenId) || reservedTokens[tokenId]) {
            tokenId++;
            return _findNextToken();
        }
    }
}
