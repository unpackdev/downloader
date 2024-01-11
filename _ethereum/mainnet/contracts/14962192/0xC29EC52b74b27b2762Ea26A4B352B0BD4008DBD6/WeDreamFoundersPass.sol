// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721Burnable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./MintpassValidator.sol";
import "./LibMintpass.sol";

/**
 * @dev Learn more about this project on wedream.world.
 *
 * WeDreamFoundersPass is a ERC721 Contract that supports Burnable.
 * The minting process is processed in a public and an allow list sale
 * sale.
 */
contract WeDreamFoundersPass is MintpassValidator, ERC721Burnable, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Token Limit and Mint Limits
    uint256 public TOKEN_LIMIT = 1000;
    uint256 public tokenBatchLimit = 100;
    uint256 public allowlistMintLimitPerWallet = 2;
    uint256 public publicMintLimitPerWallet = 25;
    uint256 private ownerFreeMints = 5;
    uint256 private ownerFreeMintsRedeemed = 0;

    // Price per Token depending on Category
    uint256 public allowlistMintPrice = 0.4 ether;
    uint256 public publicMintPrice = 0.5 ether;

    // Sale Stages Enabled / Disabled
    bool public allowlistMintEnabled = false;
    bool public publicMintEnabled = false;

    // Mapping from minter to minted amounts
    mapping(address => uint256) public mintedTokenCount;
    mapping(address => uint256) public boughtAllowlistAmounts;

    // Optional mapping to overwrite specific token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Token Freezing Trackers
    mapping(uint256 => uint256) public tokenFrozenTotal;
    mapping(uint256 => uint256) public tokenFrozenAt;
    bool private frozenTransferPermit = false;

    // counter for tracking current token id
    Counters.Counter private _tokenIdTracker;

    string public _baseTokenURI;

    event FreezeToken(uint256 identifier, address owner, uint256 timestamp);

    event UnFreezeToken(
        uint256 identifier,
        address owner,
        uint256 frozenAt,
        uint256 timestamp,
        address caller
    );

    /**
     * @dev ERC721 Constructor
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setDefaultRoyalty(msg.sender, 750);
        SIGNER_WALLET = 0xbD90eeDED7bf65a2dac572CaA7772cDa491658d1;
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner
     *
     * Requirements:
     * - `msg.sender` needs to be Owner and payable
     */
    function withdrawalAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Function to mint Tokens during Allowlist Sale. This function is
     * should only be called on minting app to ensure signature validity.
     *
     * @param quantity amount of tokens to be minted
     * @param mintpass issued by the minting app
     * @param mintpassSignature issued by minting app and signed by SIGNER_WALLET
     *
     * Requirements:
     * - `quantity` can't be higher than {allowlistMintLimitPerWallet}
     * - `mintpass` needs to match the signature contents
     * - `mintpassSignature` needs to be obtained from minting app and
     *    signed by SIGNER_WALLET
     */
    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public payable {
        require(
            allowlistMintEnabled == true,
            "WeDreamFoundersPass: Allowlist Minting is not Enabled"
        );
        require(
            mintpass.wallet == msg.sender,
            "WeDreamFoundersPass: Mintpass Address and Sender do not match"
        );
        require(
            msg.value >= allowlistMintPrice * quantity,
            "WeDreamFoundersPass: Insufficient Amount"
        );
        require(
            boughtAllowlistAmounts[mintpass.wallet] + quantity <=
                allowlistMintLimitPerWallet,
            "WeDreamFoundersPass: Maximum Allowlist per Wallet reached"
        );

        validateMintpass(mintpass, mintpassSignature);
        mintQuantityToWallet(quantity, mintpass.wallet);
        boughtAllowlistAmounts[mintpass.wallet] =
            boughtAllowlistAmounts[mintpass.wallet] +
            quantity;
    }

    /**
     * @dev Public Mint Function.
     *
     * @param quantity amount of tokens to be minted
     *
     * Requirements:
     * - `quantity` can't be higher than {publicMintLimitPerWallet}
     */
    function mint(uint256 quantity) public payable {
        require(
            publicMintEnabled == true,
            "WeDreamFoundersPass: Public Minting is not Enabled"
        );
        require(
            msg.value >= publicMintPrice * quantity,
            "WeDreamFoundersPass: Insufficient Amount"
        );
        require(
            mintedTokenCount[msg.sender] + quantity <= publicMintLimitPerWallet,
            "WeDreamFoundersPass: Maximum per Wallet reached"
        );

        mintQuantityToWallet(quantity, msg.sender);
        mintedTokenCount[msg.sender] = mintedTokenCount[msg.sender] + quantity;
    }

    /**
     * @dev Free Mint Function for Owner. We mint a few to our owner wallet for later purposes.
     *
     * @param quantity amount of tokens to be minted
     *
     * Requirements:
     * - `quantity` can't be higher than {ownerFreeMints}
     */
    function freeMint(uint256 quantity) public onlyOwner {
        require(
            ownerFreeMintsRedeemed + quantity <= ownerFreeMints,
            "WeDreamFoundersPass: Max Freemints reached"
        );
        ownerFreeMintsRedeemed = ownerFreeMintsRedeemed + quantity;
        mintQuantityToWallet(quantity, msg.sender);
    }

    /**
     * @dev internal mintQuantityToWallet function used to mint tokens
     * to a wallet (cpt. obivous out). We start with tokenId 1.
     *
     * @param quantity amount of tokens to be minted
     * @param minterAddress address that receives the tokens
     *
     * Requirements:
     * - `TOKEN_LIMIT` should not be reached
     * - `tokenBatchLimit` should not be reached
     */
    function mintQuantityToWallet(uint256 quantity, address minterAddress)
        internal
        virtual
    {
        require(
            tokenBatchLimit >= quantity + _tokenIdTracker.current(),
            "WeDreamFoundersPass: Token Batch Limit reached"
        );
        require(
            TOKEN_LIMIT >= quantity + _tokenIdTracker.current(),
            "WeDreamFoundersPass: Token Limit reached"
        );

        for (uint256 i; i < quantity; i++) {
            _mint(minterAddress, _tokenIdTracker.current() + 1);
            _tokenIdTracker.increment();
        }
    }

    /**
     * @dev Function to change the SIGNER_WALLET by contract owner.
     * This wallet is used to verify mintpass signatures.
     *
     * @param _signer_wallet The new SIGNER_WALLET address
     */
    function setSignerWallet(address _signer_wallet) public virtual onlyOwner {
        SIGNER_WALLET = _signer_wallet;
    }

    /**
     * @dev Function to change the prices for minting. Checkout our discord for more information.
     *
     * @param _allowlistMintPrice price in WEI for allowlis tMints
     * @param _publicMintPrice price in WEI for public Mints
     */
    function setMintPrice(uint256 _allowlistMintPrice, uint256 _publicMintPrice)
        public
        virtual
        onlyOwner
    {
        allowlistMintPrice = _allowlistMintPrice;
        publicMintPrice = _publicMintPrice;
    }

    /**
     * @dev Function to be called for a batch limit. The reasoning behind this is to sell the Tokens in waves.
     *
     * @param _tokenBatchLimit A limit for currently mintable tokens. Needs to be lower than the general {TOKEN_LIMIT}
     */
    function setBatchLimit(uint256 _tokenBatchLimit) public virtual onlyOwner {
        require(
            TOKEN_LIMIT >= _tokenBatchLimit,
            "WeDreamFoundersPass: Batch Limit is out of Range"
        );
        tokenBatchLimit = _tokenBatchLimit;
    }

    /**
     * @dev Function to be called by contract owner to set minting limits
     *
     * @param _allowlistMintLimitPerWallet how many tokens per wallet can be minted in allow list sale
     * @param _publicMintLimitPerWallet how many tokens can be minted in the public sale
     */
    function setMintingLimits(
        uint256 _allowlistMintLimitPerWallet,
        uint256 _publicMintLimitPerWallet
    ) public virtual onlyOwner {
        allowlistMintLimitPerWallet = _allowlistMintLimitPerWallet;
        publicMintLimitPerWallet = _publicMintLimitPerWallet;
    }

    /**
     * @dev Function to be called by contract owner to enable / disable
     * different mint stages
     *
     * @param _allowlistMintEnabled true/false
     * @param _publicMintEnabled true/false
     */
    function setMintingEnabled(
        bool _allowlistMintEnabled,
        bool _publicMintEnabled
    ) public virtual onlyOwner {
        allowlistMintEnabled = _allowlistMintEnabled;
        publicMintEnabled = _publicMintEnabled;
    }

    /**
     * @dev Function can be called by owner of Token for an unfrozen Token to freeze it
     *
     * @param tokenId Identifier of Token
     */
    function freezeToken(uint256 tokenId) external {
        require(
            ownerOf(tokenId) == _msgSender(),
            "Genesis Token: Only token owner"
        );
        require(
            tokenFrozenAt[tokenId] == 0,
            "WeDreamFoundersPass: Token already frozen"
        );
        tokenFrozenAt[tokenId] = block.timestamp;
        emit FreezeToken(tokenId, ownerOf(tokenId), block.timestamp);
    }

    /**
     * @dev Function can be called by owner of Token or contract owner for an frozen Token to unfreeze it
     *
     * @param tokenId Identifier of Token
     */
    function unfreezeToken(uint256 tokenId) external {
        require(
            ownerOf(tokenId) == _msgSender() || owner() == _msgSender(),
            "Genesis Token: Only token owner or owner"
        );
        uint256 frozenAt = tokenFrozenAt[tokenId];
        require(frozenAt > 0, "WeDreamFoundersPass: Token is not frozen");
        tokenFrozenTotal[tokenId] = block.timestamp - frozenAt;
        tokenFrozenAt[tokenId] = 0;

        emit UnFreezeToken(
            tokenId,
            ownerOf(tokenId),
            frozenAt,
            block.timestamp,
            msg.sender
        );
    }

    /**
     * @dev It is not possible to move a token with the default functions to prevent Marketplace Usage
     * However, this function can be used to transfer the token between your own wallets for example
     *
     * @param tokenId Identifier of Token
     */

    function safeTransferFrozenTokenFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "Genesis Token: Only owner");
        frozenTransferPermit = true;
        safeTransferFrom(from, to, tokenId);
        frozenTransferPermit = false;
    }

    /**
     * @dev Helper to replace _baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) {
            return _baseTokenURI;
        }
        return
            string(
                abi.encodePacked(
                    "https://meta.bowline.app/",
                    Strings.toHexString(uint256(uint160(address(this))), 20),
                    "/"
                )
            );
    }


    /**
     * @dev Can be called by owner to change base URI. This is recommend to be used
     * after tokens are revealed to freeze metadata on IPFS or similar.
     *
     * @param permanentBaseURI URI to be prefixed before tokenId
     */
    function setBaseURI(string memory permanentBaseURI)
        public
        virtual
        onlyOwner
    {
        _baseTokenURI = permanentBaseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * @dev Extends default burn behaviour
     * if it exists. Calls super._burn Reset Token Royality if set
     *
     * @param tokenId tokenID that should be burned
     *
     * Requirements:
     * - `tokenID` needs to exist
     * - `msg.sender` needs to be current token Owner
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        _resetTokenRoyalty(tokenId);
    }

    /**
    @dev Block transfers while nesting.
     */
    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId
    ) internal view override {
        require(
            tokenFrozenAt[tokenId] == 0 || frozenTransferPermit,
            "WeDreamFoundersPass: Frozen Token"
        );
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        virtual
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/** created with bowline.app **/
