//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "Ownable.sol";
import "Pausable.sol";
import "PaymentSplitter.sol";
import "ERC721A.sol";
import "Whitelist.sol";


contract InvisibleKennel is ERC721A, Ownable, Pausable, Whitelist, PaymentSplitter {

    /**
     * General constants and immutable variables
     */
    // maximum number of items in the collection
    uint256 immutable public COLLECTION_MAX_ITEMS;
    // "believers" get their first few whitelist mints boosted with free items
    uint256 public constant BELIEVER_MAX_SPONSORED_MINTS = 10;
    // boosting factor for "believers"
    uint256 public constant BELIEVER_BOOST_FACTOR = 2;

    // maximum number of mints per transaction
    uint256 public maxMintsPerTx;
    // UTC timestamp when whitelist minting starts
    uint256 public whitelistStartingTime;
    // UTC timestamp when public minting starts
    uint256 public publicStartingTime;
    // price of one NFT in wei
    uint256 public price;
    // when `true`, `specialMint` cannot longer be called
    bool public specialMintLocked;

    // for each believer, number of paid mints that were already sponsored
    mapping(address => uint256) public believerAlreadySponsoredMints;

    // URI used to prefix token URI
    string internal __baseURI;


    constructor(string memory name_,
                string memory symbol_,
                uint256 collectionMaxItems_,
                uint256 price_,
                uint256 maxMintsPerTx_,
                uint256 whitelistStartingTime_,
                uint256 publicStartingTime_,
                string memory _baseURI_,
                address[] memory payees_,
                uint256[] memory shares_)
                ERC721A(name_, symbol_)
                PaymentSplitter(payees_, shares_) {
        COLLECTION_MAX_ITEMS = collectionMaxItems_;
        setPrice(price_);
        maxMintsPerTx = maxMintsPerTx_;
        whitelistStartingTime = whitelistStartingTime_;
        publicStartingTime = publicStartingTime_;
        __baseURI = _baseURI_;
        setSigner(msg.sender);
    }

    /**
     * Unrestricted functions.
     */

    /**
     * Returns the total amount of tokens minted in the contract.
     */
     function totalMinted() external view returns(uint256) {
         return _totalMinted();
     }

    /**
     * @dev Safely mints an amount of tokens equal to `msg.value/price` to `msg.sender`.
     */
    function mint() external payable whenNotPaused {
        require(block.timestamp >= publicStartingTime, "minting not open yet");
        uint256 _numToMint = msg.value / price;
        require(_numToMint <= maxMintsPerTx, "limit on minting too many at a time");
        _isValidMintAmount(_numToMint);
        _safeMint(msg.sender, _numToMint);
    }

    /**
     * @dev Safely mints an amount of tokens equal to `msg.value/price` to `msg.sender` provided
     * `_signature` is valid. If `_isBeliever` is `true`, the first paid `BELIEVER_MAX_SPONSORED_MINTS`
     * mints from msg.sender will yield her an extra `BELIEVER_BOOST_FACTOR` items.
     */
    function whitelistMint(bool _isBeliever, bytes memory _signature) external payable whenNotPaused {
        require(block.timestamp >= whitelistStartingTime, "whitelist not open yet");
        require(_verify(msg.sender, _isBeliever, _signature), "invalid arguments or not whitelisted");

        uint256 _numToMint = msg.value / price;
        uint256 _numToMintWithoutSponsor = _numToMint;
        if (_isBeliever) {
            uint256  _maxRemainingSponsored = BELIEVER_MAX_SPONSORED_MINTS - believerAlreadySponsoredMints[msg.sender];

            if (_maxRemainingSponsored < _numToMint) {
                believerAlreadySponsoredMints[msg.sender] += _maxRemainingSponsored;
                _numToMint += _maxRemainingSponsored * (BELIEVER_BOOST_FACTOR - 1);
            } else {
                believerAlreadySponsoredMints[msg.sender] += _numToMint;
                _numToMint *= BELIEVER_BOOST_FACTOR;
            }
        }

        require(_numToMintWithoutSponsor <= maxMintsPerTx, "limit on minting too many at a time");
        _isValidMintAmount(_numToMint);
        _safeMint(msg.sender, _numToMint);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    /**
     * @dev Returns `__baseURI`.
     */
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    /**
     * @dev Checks that the quantity being minted is valid.
     */
    function _isValidMintAmount(uint256 _numToMint) private view returns(uint256){
        require(_numToMint > 0, "cannot mint 0");
        require((_numToMint + _totalMinted()) <= COLLECTION_MAX_ITEMS,
                        "would exceed max supply");
    }

    /**
     * Restricted functions.
     */

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public override {
        require(msg.sender == address(account), "msg.sender != account");
        super.release(account);
    }

     /**
     * @dev Minting, at no cost, a quantity of items as defined by the array `amounts`
     * to an array of `recipients`. This function can only be called by the `owner`
     * while `specialMintLocked` evaluates to `false`.
     */
    function specialMint(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(!specialMintLocked, "special mint permanently locked");
        require(recipients.length == amounts.length, "arrays have different lengths");

        for(uint256 i=0; i < recipients.length; i++){
            _safeMint(recipients[i], amounts[i]);
        }

        require(_totalMinted() <= COLLECTION_MAX_ITEMS, "would exceed max supply");
    }

    /**
     * @dev Sets the starting time of the whitelist.
     */
    function setWhitelistStartingTime(uint256 _whitelistStartingTime) external onlyOwner {
        whitelistStartingTime = _whitelistStartingTime;
    }

    /**
     * @dev Sets the starting time of the public sale.
     */
    function setPublicStartingTime(uint256 _publicStartingTime) external onlyOwner {
        publicStartingTime = _publicStartingTime;
    }

    /**
     * @dev Sets the maximum number of items that can be minted at once.
     */
    function setMaxMintsPerTx(uint256 _newMaxMintsPerTx) external onlyOwner {
        maxMintsPerTx = _newMaxMintsPerTx;
    }

    /**
     * @dev Permanently prevents the `owner` from calling `specialMint`.
     */
    function lockSpecialMint() external onlyOwner {
        specialMintLocked = true;
    }

    /**
     * @dev Sets the base URI.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        __baseURI = _newBaseURI;
    }

    /**
     * @dev Pauses functions modified with `whenNotPaused`.
     */
    function pause() external virtual whenNotPaused onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses functions modified with `whenNotPaused`.
     */
    function unpause() external virtual whenPaused onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the price in wei per item. Price must be positive.
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0, "price must be positive");
        price = _newPrice;
    }

    /**
     * @dev Sets the address to use to verify validity of signatures in `whitelistMint`.
     */
    function setSigner(address _newSigner) public onlyOwner {
        require(_newSigner != address(0), "signer cannot be the zero address");
        _signer = _newSigner;
    }
}