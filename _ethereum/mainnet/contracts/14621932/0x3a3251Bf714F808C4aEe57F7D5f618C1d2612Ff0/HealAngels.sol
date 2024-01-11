// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProofVerify.sol";

/**
 * @title HealAngels NFTs
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 */
contract HealAngels is Ownable, ERC721Enumerable, MerkleProofVerify {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /// tokenId tracker using lib
    Counters.Counter private _tokenIdTracker;

    /// base token uri
    string private _baseTokenURI;

    /**
     * @dev Returns the max allowed supply i.e. 1000.
     */
    uint256 public constant MAX_SUPPLY = 1000;

    /**
     * @dev Returns the price per a token.
     */
    uint256 public pricePerToken = 0.1 ether;

    /**
     * @dev Returns bool flag if saleFlag is active or not.
     */
    bool public saleFlag = false;

    /**
     * @dev Returns bool flag if whitelistSaleFlag is active or not.
     */
    bool public whitelistSaleFlag = false;

    /**
     * @dev Returns boolean value of claimer address.
     * mapping claimer address to bool value
     */
    mapping(address => bool) public claims;

    /**
     * @dev Emitted when `baseURI` is changed.
     */
    event BaseURIUpdated(string baseURI);

    /**
     * @dev Emitted when a new token is minted.
     */
    event NFTMinted(uint256 indexed tokenId, address indexed beneficiary);

    /**
     * @dev Emitted when a new token is minted.
     */
    event Withdrawn(uint256 amount, address indexed beneficiary);

    /**
     * @dev Emitted when whitelist sale is toggled.
     */
    event WhilelistSaleToggled(bool whitelistSaleFlag);

    /**
     * @dev Emitted when sale is toggled.
     */
    event SaleToggled(bool saleFlag);

    /**
     * @dev Emitted when price is updated.
     */
    event PricePerTokenUpdated(uint256 newPrice);

    /**
     * @dev Custom errors.
     */
    error SaleFlagNotActive();
    error InvalidPrice();
    error WhitelistSaleFlagNotActive();
    error InvalidProof();
    error AlreadyClaimed();
    error BaseTokenURIAlreadySet();
    error MaxFiveMintsPerTxn();
    error MaxSupplyLimitReached();

    constructor() ERC721("Heal Angels", "Angels") {}

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Returns the string value of {baseURI}.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Returns bool flag if token exists.
     */
    function tokenExists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev Returns the price for `_noOfTokens`.
     */
    function tokensPrice(uint256 _noOfTokens) public view returns (uint256) {
        return _noOfTokens * pricePerToken;
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
     * @dev Mints `_noOfTokens` and transfers to `caller`.
     *
     * Emits a {NFTMinted} event indicating the mint of a new NFT.
     *
     * @param _noOfTokens - no of tokens `caller` wants to mint.
     *
     * Requirements:
     *
     * - `_noOfTokens` must be less than 10.
     */
    function mint(uint256 _noOfTokens) public payable {
        if (!saleFlag) revert SaleFlagNotActive();
        if (msg.value != tokensPrice(_noOfTokens)) revert InvalidPrice();

        _mintTokensInternal(_msgSender(), _noOfTokens);
    }

    /**
     * @dev Mints a token and transfers to caller.
     *
     * Emits a {NFTMinted} event indicating the mint of amount of a new NFT.
     *
     * @param _index uint256 index of account.
     * @param _amount uint256 amount to be claimed.
     * @param _proof bytes32[] proof of merkle root.
     *
     * Requirements:
     *
     * - `_index`, `_amount` and `_proof` must be valid from merkle root.
     */
    function claim(
        uint256 _index,
        uint256 _amount,
        bytes32[] memory _proof
    ) external {
        if (!whitelistSaleFlag) revert WhitelistSaleFlagNotActive();
        bytes32 _leaf = keccak256(
            abi.encodePacked(_index, _msgSender(), _amount)
        );
        if (!verify(_proof, _leaf)) revert InvalidProof();
        if (claims[_msgSender()]) revert AlreadyClaimed();

        claims[_msgSender()] = true;

        _mintTokensInternal(_msgSender(), _amount);
    }

    /**
     * @dev Mints `_amount` tokens and transfers to `_to`.
     *
     * Emits a {NFTMinted} event indicating the mint of amount of a new NFT.
     *
     * @param _to - recipient address.
     * @param _noOfTokens - no of tokens to mint.
     *
     * Requirements:
     *
     * - caller must be {owner}.
     */
    function freeMint(address _to, uint32 _noOfTokens) external onlyOwner {
        _mintTokensInternal(_to, _noOfTokens);
    }

    /**
     * @dev Toggles whitlist sale active or inactive.
     *
     * Requirements:
     *
     * - caller must be {owner}.
     */
    function toggleWhitelistSaleFlag() public onlyOwner {
        whitelistSaleFlag = !whitelistSaleFlag;
        emit WhilelistSaleToggled(whitelistSaleFlag);
    }

    /**
     * @dev Toggles sale active or inactive.
     *
     * Requirements:
     *
     * - caller must be {owner}.
     */
    function toggleSale() public onlyOwner {
        saleFlag = !saleFlag;
        emit SaleToggled(saleFlag);
    }

    /**
     * @dev Sets the merkle root.
     *
     * Emits a {RootSet} event indicating update of merkle root hash.
     *
     * @param _root - markle root
     * @param _proofHash - ipfs hash containing json file of proofs.
     *
     * Requirements:
     *
     * - caller must be {owner}.
     * - `_root` must be valid.
     */
    function setRoot(bytes32 _root, string memory _proofHash) public onlyOwner {
        _setRoot(_root, _proofHash);
    }

    /**
     * @dev Sets {baseURI} to `_newBaseTokenURI`.
     *
     * Emits a {BaseURIUpdated} event indicating change of {baseURI}.
     *
     * @param _newBaseTokenURI - new base URI string.
     *
     * Requirements:
     * - `_newBaseTokenURI` must be in format: "ipfs://{hash}/"
     * - `_noOfTokens` must be less than 30.
     * - caller must be {owner}.
     * - callable only once.
     */
    function setBaseURI(string memory _newBaseTokenURI) public onlyOwner {
        if (bytes(_baseTokenURI).length != 0) revert BaseTokenURIAlreadySet();

        _baseTokenURI = _newBaseTokenURI;

        emit BaseURIUpdated(_newBaseTokenURI);
    }

    /**
     * @dev Sets new price per token.
     *
     * Emits a {PricePerTokenUpdated} event indicating change of {pricePerToken}.
     *
     * @param _newPrice - new price per token.
     *
     * Requirements:
     * - caller must be {owner}.
     */
    function setPricePerToken(uint256 _newPrice) public onlyOwner {
        if (_newPrice == 0) revert InvalidPrice();
        pricePerToken = _newPrice;
        emit PricePerTokenUpdated(pricePerToken);
    }

    /**
     * @dev Sends all ethers of this contract to msg.sender.
     *
     * Emits a {Withdrawn} event indicating ether transfer.
     *
     * Requirements:
     * - caller must be {owner}.
     */
    function withdraw() public onlyOwner {
        uint256 _value = address(this).balance;
        Address.sendValue(payable(_msgSender()), _value);
        emit Withdrawn(_value, _msgSender());
    }

    /**
     * @dev See {ERC721-_baseURI}
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Internal function to mint new tokens.
     *
     * Emits a {NFTMinted} event indicating transfer of nft to recipient.
     *
     * @param _to - recipient address.
     * @param _noOfTokens - no of tokens to mint.
     */
    function _mintTokensInternal(address _to, uint256 _noOfTokens) internal {
        if (_noOfTokens > 5) revert MaxFiveMintsPerTxn();
        if (totalSupply() + _noOfTokens > MAX_SUPPLY)
            revert MaxSupplyLimitReached();

        for (uint256 i = 0; i < _noOfTokens; i++) {
            // incrementing
            _tokenIdTracker.increment();
            uint256 _tokenId = _tokenIdTracker.current();

            // mint nft
            _safeMint(_to, _tokenId);

            emit NFTMinted(_tokenId, _msgSender());
        }
    }
}
