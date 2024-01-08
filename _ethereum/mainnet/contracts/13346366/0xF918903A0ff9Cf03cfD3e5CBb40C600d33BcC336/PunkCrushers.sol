// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./IPunkCrushers.sol";

/**
 * @title PunkCrushers NFTs
 * @dev Implementation of the {IPunkCrushers} interface.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 */
contract PunkCrushers is IPunkCrushers, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // tokenId tracker using lib
    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    // flag for updating {baseURI} only once.
    bool private _uriUpdated = false;

    /**
     * @dev See {IPunkCrushers-MAX_SUPPLY}.
     */
    uint256 public constant override MAX_SUPPLY = 10000;

    /**
     * @dev See {IPunkCrushers-PRICE_PER_TOKEN_FOR_1}.
     */
    uint256 public constant override PRICE_PER_TOKEN_FOR_1 = 0.085 ether;

    /**
     * @dev See {IPunkCrushers-PRICE_PER_TOKEN_FOR_3}.
     */
    uint256 public constant override PRICE_PER_TOKEN_FOR_3 = 0.075 ether;

    /**
     * @dev See {IPunkCrushers-PRICE_PER_TOKEN_FOR_5}.
     */
    uint256 public constant override PRICE_PER_TOKEN_FOR_5 = 0.065 ether;

    /**
     * @dev See {IPunkCrushers-PRICE_PER_TOKEN_FOR_10}.
     */
    uint256 public constant override PRICE_PER_TOKEN_FOR_10 = 0.055 ether;

    /**
     * @dev See {IPunkCrushers-PRICE_PER_TOKEN_FOR_20}.
     */
    uint256 public constant override PRICE_PER_TOKEN_FOR_20 = 0.045 ether;

    /**
     * @dev See {IPunkCrushers-presaleActive}.
     */
    bool public override presaleActive = true;

    /**
     * @dev See {IPunkCrushers-dev}.
     */
    address public override dev;

    /**
     * @dev Sets {dev}, {_initialBaseURI} and {ERC721-constructor}.
     */
    constructor(address _dev, string memory _initialBaseURI)
        ERC721("Punk Crushers", "PKCS")
    {
        _baseTokenURI = _initialBaseURI;
        dev = _dev;
    }

    /**
     * @dev See {IPunkCrushers-baseURI}.
     */
    function baseURI() public view override returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev See {IPunkCrushers-tokenExists}.
     */
    function tokenExists(uint256 _tokenId) public view override returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev See {IPunkCrushers-tokensPrice}.
     */
    function tokensPrice(uint256 _noOfTokens)
        public
        pure
        override
        returns (uint256)
    {
        if (_noOfTokens == 3) return _noOfTokens * PRICE_PER_TOKEN_FOR_3;
        if (_noOfTokens == 5) return _noOfTokens * PRICE_PER_TOKEN_FOR_5;
        if (_noOfTokens == 10) return _noOfTokens * PRICE_PER_TOKEN_FOR_10;
        if (_noOfTokens == 20) return _noOfTokens * PRICE_PER_TOKEN_FOR_20;
        return _noOfTokens * PRICE_PER_TOKEN_FOR_1;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        super.tokenURI(_tokenId);
        return
            (bytes(baseURI()).length > 0)
                ? string(
                    abi.encodePacked(baseURI(), _tokenId.toString(), ".json")
                )
                : "";
    }

    /**
     * @dev See {IPunkCrushers-presaleMint}.
     *
     * Emits a {NFTMinted} event indicating the mint of a new NFT.
     *
     * @param _noOfTokens - no of tokens `caller` wants to mint.
     *
     * Requirements:
     *
     * - presale must be active.
     * - `_noOfTokens` must be less than 20.
     */
    function presaleMint(uint256 _noOfTokens) public payable override {
        require(presaleActive, "PresaleMint: presale inactive");
        require(_noOfTokens <= 20, "PresaleMint: max 20 per transaction");

        _mint(_noOfTokens, msg.value);
    }

    /**
     * @dev See {IPunkCrushers-mint}.
     *
     * Emits a {NFTMinted} event indicating the mint of a new NFT.
     *
     * @param _noOfTokens - no of tokens `caller` wants to mint.
     *
     * Requirements:
     *
     * - `_noOfTokens` must be less than 10.
     */
    function mint(uint256 _noOfTokens) public payable override {
        require(_noOfTokens <= 10, "Mint: max 10 per transaction");
        _mint(_noOfTokens, msg.value);
    }

    /**
     * @dev See {IPunkCrushers-reserveTokens}.
     *
     * Emits a {NFTMinted} event indicating the mint of a new NFT.
     *
     * @param _noOfTokens - no of tokens {owner} wants to mint.
     *
     * Requirements:
     *
     * - `_noOfTokens` must be less than 30.
     * - caller must be {owner}.
     */
    function reserveTokens(uint256 _noOfTokens) public override onlyOwner {
        require(_noOfTokens <= 30, "ReserveTokens: max 30 per transaction");
        _supplyValidator(_noOfTokens);
        for (uint8 i = 0; i < _noOfTokens; i++) {
            // incrementing by 1
            _tokenIdTracker.increment();
            uint256 _tokenId = _tokenIdTracker.current();

            // mint nft
            _safeMint(_msgSender(), _tokenId);

            emit NFTMinted(_tokenId, _msgSender());
        }
    }

    /**
     * @dev See {IPunkCrushers-togglePresale}.
     *
     * Requirements:
     *
     * - caller must be {owner}.
     */
    function togglePresale() public override onlyOwner {
        presaleActive = !presaleActive;
    }

    /**
     * @dev See {IPunkCrushers-setBaseURI}.
     *
     * Emits a {BaseURIUpdated} event indicating change of {baseURI}.
     *
     * @param _newBaseTokenURI - new base URI string.
     *
     * Requirements:
     * - `_newBaseTokenURI` must be in format: "ipfs://{hash}/"
     * - `_noOfTokens` must be less than 30.
     * - caller must be {owner}.
     */
    function setBaseURI(string memory _newBaseTokenURI)
        public
        override
        onlyOwner
    {
        require(
            !_uriUpdated,
            "setBaseURI: uri cannot be updated more than once"
        );
        _baseTokenURI = _newBaseTokenURI;
        _uriUpdated = true;

        emit BaseURIUpdated(_newBaseTokenURI);
    }

    /**
     * @dev Internal function called in {presaleMint} and {mint}.
     * mints tokens and transfers to `caller`.
     *
     * Emits a {FundsTransferred} event indicating transfer of funds.
     *
     * @param _noOfTokens - no of tokens {owner} wants to mint.
     * @param _value - ether price paid for token minting.
     *
     * Requirements:
     * - {totalSupply} must not max out {MAX_SUPPLY}.
     * - `_value` must be equal to correct tokenPrice.
     */
    function _mint(uint256 _noOfTokens, uint256 _value) internal {
        _supplyValidator(_noOfTokens);
        require(_value == tokensPrice(_noOfTokens), "Mint: invalid price");

        for (uint256 i = 0; i < _noOfTokens; i++) {
            // incrementing
            _tokenIdTracker.increment();
            uint256 _tokenId = _tokenIdTracker.current();

            // mint nft
            _safeMint(_msgSender(), _tokenId);

            emit NFTMinted(_tokenId, _msgSender());
        }

        // transfer funds to owner and dev
        _transferFunds(_value);
    }

    /**
     * @dev Internal function called in {_mint} and {reserveTokens}.
     *
     * @param _noOfTokens - no of tokens `caller` wants to mint.
     *
     * Requirements:
     * - {totalSupply} must not max out {MAX_SUPPLY}.
     */
    function _supplyValidator(uint256 _noOfTokens) internal view {
        require(
            totalSupply() + _noOfTokens <= MAX_SUPPLY,
            "SupplyValidator: max limit reached"
        );
    }

    /**
     * @dev Internal function called in {_mint}.
     * transfers funds to {owner} and {dev}.
     *
     * Emits a {FundsTransferred} event indicating transfer of funds.
     *
     * @param _value - ether price paid for token minting.
     */
    function _transferFunds(uint256 _value) internal {
        address payable _owner = payable(owner());
        uint256 _ownerShare = (_value * 70) / 100;
        Address.sendValue(_owner, _ownerShare);
        emit FundsTransferred(_owner, _ownerShare);

        address payable _dev = payable(dev);
        uint256 _devShare = (_value * 30) / 100;
        Address.sendValue(_dev, _devShare);
        emit FundsTransferred(_dev, _devShare);
    }

    /**
     * @dev See {ERC721-_baseURI}
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
