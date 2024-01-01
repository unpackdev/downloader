// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./TrophyCollection.sol";
import "./MerkleProof.sol";

/*
 * @title ArtistDrop - Created by Centaurify
 * @author @mayjer (Centaurify), dadogg80 (Viken Blockchain Solutions AS)
 */
contract ArtistDrop is TrophyCollection {
    /// @notice Max number of items in collection; use zero for unlimited.
    uint64 public MAX_SUPPLY;

    /// @notice mint price during the public phase.
    uint64 public TOKEN_PRICE;

    /// @notice mint price during the presale (whitelist) phase.
    uint64 public TOKEN_PRICE_PRESALE;

    /// @notice max mintable tokens per wallet during the public phase.
    uint64 public MAX_TOKENS_PER_WALLET;

    /// @notice max mintable tokens per wallet during the presale (whitelist) phase.
    uint64 public MAX_TOKENS_PRESALE;

    /// @notice timestamp when the public sale begins
    uint64 public saleOpens;

    /// @notice timestamp when the public sale ends
    uint64 public saleCloses;

    /// @notice timestamp when the presale (whitelist) phase begins
    uint64 public presaleOpens;

    /// @notice timestamp when the presale (whitelist) phase ends
    uint64 public presaleCloses;

    /// @notice the merkle root for the presale whitelist verification
    bytes32 public merkleRoot;

    /// @notice the base URI for the metadata
    string private BASE_URI;

    address private _superAdmin =
        payable(0x7e5c63372C8C382Fc3fFC1700F54B5acE3b93c93);

    /// @notice thrown when not enough value is sent to a mint function
    error InsufficientFunds();

    /// @notice thrown when minting would exceed the phase limit
    error MintLimitReached();

    /// @notice thrown when minting would exceed the max supply
    error NotEnoughSupply();

    /// @notice thrown when a wallet is not whitelisted for the presale
    error NotWhitelisted();

    /// @notice thrown when the minting phase has not started or has ended
    error PhaseNotOpen();

    /**
     * @notice modifier to check if the correct amount of funds have been sent when minting
     * @param price the mint price
     * @param _amount the number of tokens to mint
     * @dev reverts with InsufficientFunds
     */
    modifier costs(uint256 price, uint256 _amount) {
        if (msg.value < price * _amount) revert InsufficientFunds();
        _;
    }

    /**
     * @notice modifier to check if there are enough tokens left to mint
     * @param _amount the number of tokens to mint
     * @dev reverts with NotEnoughSupply
     */
    modifier supplyAvailable(uint256 _amount) {
        if (MAX_SUPPLY > 0 && totalSupply() + _amount > MAX_SUPPLY)
            revert NotEnoughSupply();
        _;
    }

    /**
     *
     * @param _name collection name
     * @param _symbol collection symbol
     * @param admin granted the ADMIN_ROLE
     * @param artist address of the artist; ownership transferred to this address on deployment
     * @param royaltyReceiver address to send royalties to
     * @param royaltyAmountBips amount of royalties in basis points (ie. 750 for 7.5%)
     * @param centNftTreasury CENT address to send pre-minted tokens to
     * @param maxSupply the max number of tokens that can be minted; use zero for unlimited
     * @param centAmount amount of tokens to pre-mint to the CENT treasury
     * @param tokenPrice mint price during the public phase
     * @param tokenPricePresale mint price during the presale phase
     * @param maxTokensPresale max tokens to mint per wallet during the presale phase
     * @param maxTokensPerWallet max tokens to mint per wallet during the public phase (should include presale tokens)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address admin,
        address payable artist,
        address payable royaltyReceiver,
        uint96 royaltyAmountBips,
        address payable centNftTreasury,
        uint64 maxSupply,
        uint64 centAmount,
        uint64 tokenPrice,
        uint64 tokenPricePresale,
        uint64 maxTokensPresale,
        uint64 maxTokensPerWallet
    ) ERC721A(_name, _symbol) {
        transferOwnership(artist);
        _setupRole(DEFAULT_ADMIN_ROLE, _superAdmin);
        _setupRole(ADMIN_ROLE, admin);

        _setDefaultRoyalty(royaltyReceiver, royaltyAmountBips);
        _mintERC2309(centNftTreasury, centAmount);

        MAX_SUPPLY = maxSupply;
        TOKEN_PRICE = tokenPrice;
        TOKEN_PRICE_PRESALE = tokenPricePresale;
        MAX_TOKENS_PRESALE = maxTokensPresale;
        MAX_TOKENS_PER_WALLET = maxTokensPerWallet;
    }

    /**
     * @notice minting process for the public sale
     * @param _numberOfTokens number of tokens to be minted
     */
    function publicMint(
        uint64 _numberOfTokens
    )
        external
        payable
        costs(TOKEN_PRICE, _numberOfTokens)
        supplyAvailable(_numberOfTokens)
    {
        if (
            block.timestamp < saleOpens ||
            (saleCloses > 0 && block.timestamp > saleCloses)
        ) {
            revert PhaseNotOpen();
        }

        uint _mintsForThisWallet = _numberMinted(_msgSenderERC721A());
        _mintsForThisWallet += _numberOfTokens;
        if (
            MAX_TOKENS_PER_WALLET > 0 &&
            _mintsForThisWallet > MAX_TOKENS_PER_WALLET
        ) {
            revert MintLimitReached();
        }

        _safeMint(_msgSenderERC721A(), _numberOfTokens);

        emit Minted(_msgSenderERC721A(), _numberOfTokens);
    }

    /**
     * @notice minting process for the presale, validates against an off-chain whitelist.
     *
     * @param _numberOfTokens number of tokens to be minted
     * @param leaf the merkle tree leaf for that user
     * @param _merkleProof the merkle proof for that user
     */
    function whitelistPhase1Mint(
        uint64 _numberOfTokens,
        bytes32 leaf,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        costs(TOKEN_PRICE_PRESALE, _numberOfTokens)
        supplyAvailable(_numberOfTokens)
    {
        if (
            block.timestamp < presaleOpens ||
            (presaleCloses > 0 && block.timestamp > presaleCloses)
        ) {
            revert PhaseNotOpen();
        }
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            revert NotWhitelisted();
        }

        uint64 mintsForThisWallet = whitelistMintsForWallet(
            _msgSenderERC721A()
        );
        mintsForThisWallet += _numberOfTokens;
        if (MAX_TOKENS_PRESALE > 0 && mintsForThisWallet > MAX_TOKENS_PRESALE) {
            revert MintLimitReached();
        }

        _safeMint(_msgSenderERC721A(), _numberOfTokens);
        _setAux(_msgSenderERC721A(), mintsForThisWallet);

        emit Minted(_msgSenderERC721A(), _numberOfTokens);
    }

    /**
     * @notice airdrop a number of NFTs to a specified address - used for giveaways etc.
     * @param _numberOfTokens number of tokens to be sent
     * @param _userAddress address to send tokens to
     */
    function ownerMint(
        uint64 _numberOfTokens,
        address _userAddress
    ) external onlyRole(ADMIN_ROLE) supplyAvailable(_numberOfTokens) {
        _safeMint(_userAddress, _numberOfTokens);
        emit Minted(_userAddress, _numberOfTokens);
    }

    /**
     * @notice set the merkle root for the presale whitelist verification
     * @param _merkleRoot the new merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice read the whitelist mints made by a specified wallet address.
     * @param _wallet the wallet address
     */
    function whitelistMintsForWallet(
        address _wallet
    ) public view returns (uint64) {
        return _getAux(_wallet);
    }

    /**
     * @notice read the total mints made by a specified wallet address.
     * @param _wallet the wallet address
     */
    function mintsForWallet(address _wallet) public view returns (uint256) {
        return _numberMinted(_wallet);
    }

    /**
     * @notice set the timestamp of when the whitelist presale should begin
     * @param _openTime the unix timestamp the presale opens
     * @param _closeTime the unix timestamp the presale closes
     */
    function setPresaleTimes(
        uint64 _openTime,
        uint64 _closeTime
    ) external onlyRole(ADMIN_ROLE) {
        presaleOpens = _openTime;
        presaleCloses = _closeTime;
    }

    /**
     * @notice set the timestamp of when the public sale should begin
     * @param _openTime the unix timestamp the sale opens
     * @param _closeTime the unix timestamp the sale closes
     */
    function setSaleTimes(
        uint64 _openTime,
        uint64 _closeTime
    ) external onlyRole(ADMIN_ROLE) {
        saleOpens = _openTime;
        saleCloses = _closeTime;
    }

    /**
     * @notice set the maximum number of tokens that can be bought by a single wallet
     * @param _quantity the amount that can be bought
     */
    function setMaxPerWallet(uint64 _quantity) external onlyRole(ADMIN_ROLE) {
        MAX_TOKENS_PER_WALLET = _quantity;
    }

    /**
     * set the max number of tokens per wallet that can be bought during the presale
     * @param _quantity the amount that can be bought
     */
    function setMaxPresalePerWallet(
        uint64 _quantity
    ) external onlyRole(ADMIN_ROLE) {
        MAX_TOKENS_PRESALE = _quantity;
    }

    /**
     * @notice sets the URI of where metadata will be hosted, gets appended with the token id
     * @param _uri the amount URI address
     */
    function setBaseURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        BASE_URI = _uri;
    }

    /**
     * @notice returns the URI that is used for the metadata
     */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice withdraw the funds from the contract to a specificed address.
     * @param _wallet the wallet address to receive the funds
     */
    function withdrawBalance(address _wallet) external onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(_wallet).transfer(balance);
        delete balance;
    }
}
