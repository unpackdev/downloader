// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./MintpassValidator.sol";
import "./LibMintpass.sol";

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @dev Learn more about this project on takamuto.com.
 *
 * Takamuto is a ERC721 Contract that supports Burnable.
 * The minting process is processed in a public and a whitelist
 * sale.
 */
contract Takamuto is MintpassValidator, ERC721Burnable, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public totalSupply;

    // Token Limit and Mint Limits
    uint256 public TOKEN_LIMIT = 1000;
    uint256 public whitelistMintLimitPerWallet;
    uint256 public publicMintLimitPerWallet;

    // Price per Token depending on Category
    uint256 public whitelistMintPrice;
    uint256 public publicMintPrice;

    // Sale Stages Enabled / Disabled
    bool public isWhitelistMintEnabled = false;
    bool public isPublicMintEnabled = false;

    // Revealed Enabled / Disabled
    bool public revealed = false;

    // Mapping from minter to minted amounts
    mapping(address => uint256) public boughtAmounts;
    mapping(address => uint256) public boughtWhitelistAmounts;

    // Mapping from mintpass signature to minted amounts (Free Mints)
    mapping(bytes => uint256) public mintpassRedemptions;

    // Optional mapping to overwrite specific token URIs
    mapping(uint256 => string) private _tokenURIs;    

    // counter for tracking current token id
    Counters.Counter private _tokenIdTracker;

    // _abseTokenURI serving nft metadata per token
    string private _baseTokenURI;
    string private notRevealedUri;

    string public baseExtension = ".json";


    event TokenUriChanged(
        address indexed _address,
        uint256 indexed _tokenId,
        string _tokenURI
    );

    /**
     * @dev ERC721 Constructor
     */
    constructor(string memory name, string memory symbol, string memory _initBaseTokenURI, string memory _initNotRevealedURI) ERC721(name, symbol) {
        _setDefaultRoyalty(msg.sender, 1000);
        ACE_WALLET = 0xeaC703A4Fc9A82f070bAA9f12f0CabC627964f45;
        //Initial Values to safe gas
        totalSupply = 0;
        whitelistMintLimitPerWallet = 5;
        publicMintLimitPerWallet = 5;

        whitelistMintPrice = 0 ether;
        publicMintPrice = 0 ether;

        setBaseURI(_initBaseTokenURI);
        setNotRevealedURI(_initNotRevealedURI);
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
     * @dev Function to mint Tokens for only Gas. This function is used
     * for Community Wallet Mints, Raffle Winners and Cooperation Partners.
     * Redemptions are tracked and can be done in chunks.
     *
     * @param quantity amount of tokens to be minted
     * @param mintpass issued by takamuto.com.io
     * @param mintpassSignature issued by takamuto.com and signed by ACE_WALLET
     *
     * Requirements:
     * - `quantity` can't be higher than mintpass.amount
     * - `mintpass` needs to match the signature contents
     * - `mintpassSignature` needs to be obtained from takamuto.com and
     *    signed by ACE_WALLET
     */
    function freeMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public {
        require(
            isWhitelistMintEnabled == true || isPublicMintEnabled == true,
            "Minting is not Enabled"
        );
        require(
            mintpass.minterAddress == msg.sender,
            "Mintpass Address and Sender do not match"
        );
        require(
            mintpassRedemptions[mintpassSignature] + quantity <=
                mintpass.amount,
            "Mintpass already redeemed"
        );
        require(
            mintpass.minterCategory == 99,
            "Mintpass not a Free Mint"
        );

        validateMintpass(mintpass, mintpassSignature);
        mintQuantityToWallet(quantity, mintpass.minterAddress);
        mintpassRedemptions[mintpassSignature] =
            mintpassRedemptions[mintpassSignature] +
            quantity;
    }

    /**
     * @dev Function to mint Tokens during Whitelist Sale. This function is
     * should only be called on takamuto.com minting page to ensure
     * signature validity.
     *
     * @param quantity amount of tokens to be minted
     * @param mintpass issued by takamuto.com
     * @param mintpassSignature issued by takamuto.com and signed by ACE_WALLET
     *
     * Requirements:
     * - `quantity` can't be higher than {whitelistMintLimitPerWallet}
     * - `mintpass` needs to match the signature contents
     * - `mintpassSignature` needs to be obtained from takamuto.com and
     *    signed by ACE_WALLET
     */
    function mintWhitelist(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public payable {
        require(
            isWhitelistMintEnabled == true,
            "Whitelist Minting is not Enabled"
        );
        require(
            mintpass.minterAddress == msg.sender,
            "Mintpass Address and Sender do not match"
        );
        require(
            msg.value >= whitelistMintPrice * quantity,
            "Insufficient Amount"
        );
        require(
            boughtWhitelistAmounts[mintpass.minterAddress] + quantity <=
                whitelistMintLimitPerWallet,
            "Maximum Whitelist per Wallet reached"
        );

        validateMintpass(mintpass, mintpassSignature);
        mintQuantityToWallet(quantity, mintpass.minterAddress);
        boughtWhitelistAmounts[mintpass.minterAddress] =
            boughtWhitelistAmounts[mintpass.minterAddress] +
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
            isPublicMintEnabled == true,
            "Public Minting is not Enabled"
        );
        require(
            msg.value >= publicMintPrice * quantity,
            "Insufficient Amount"
        );
        require(
            boughtAmounts[msg.sender] + quantity <= publicMintLimitPerWallet,
            "Maximum per Wallet reached"
        );

        mintQuantityToWallet(quantity, msg.sender);
        boughtAmounts[msg.sender] = boughtAmounts[msg.sender] + quantity;
    }

    /**
     * @dev internal mintQuantityToWallet function used to mint tokens
     * to a wallet (cpt. obivous out). We start with tokenId 1.
     *
     * @param quantity amount of tokens to be minted
     * @param minterAddress address that receives the tokens
     *
     * Requirements:
     * - `TOKEN_LIMIT` should not be reahed
     */
    function mintQuantityToWallet(uint256 quantity, address minterAddress)
        internal
        virtual
    {
        require(
            TOKEN_LIMIT >= quantity + _tokenIdTracker.current(),
            "sold out"
        );

        for (uint256 i; i < quantity; i++) {
            _mint(minterAddress, _tokenIdTracker.current() + 1);
            _tokenIdTracker.increment();
            totalSupply++;
        }
    }

    /**
     * @dev Function to change the ACE_WALLET by contract owner.
     * Learn more about the ACE_WALLET on our Roadmap.
     * This wallet is used to verify mintpass signatures and is allowed to
     * change tokenURIs for specific tokens.
     *
     * @param _ace_wallet The new ACE_WALLET address
     */
    function setAceWallet(address _ace_wallet) public virtual onlyOwner {
        ACE_WALLET = _ace_wallet;
    }

    /**
     */
    function setMintingLimits(
        uint256 _whitelistMintLimitPerWallet,
        uint256 _publicMintLimitPerWallet
    ) public virtual onlyOwner {
        whitelistMintLimitPerWallet = _whitelistMintLimitPerWallet;
        publicMintLimitPerWallet = _publicMintLimitPerWallet;
    }

    /**
     * @dev Function to be called by contract owner to enable / disable
     * different mint stages
     *
     * @param _isWhitelistMintEnabled true/false
     * @param _isPublicMintEnabled true/false
     */
    function setMintingEnabled(
        bool _isWhitelistMintEnabled,
        bool _isPublicMintEnabled
    ) public virtual onlyOwner {
        isWhitelistMintEnabled = _isWhitelistMintEnabled;
        isPublicMintEnabled = _isPublicMintEnabled;
    }

    /**
     * @dev Helper to replace _baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
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

    /**
     * @dev _tokenURIs setter for a tokenId. This can only be done by owner or our
     * ACE_WALLET. Learn more about this on our Roadmap.
     *
     * Emits TokenUriChanged Event
     *
     * @param tokenId tokenId that should be updated
     * @param permanentTokenURI URI to OVERWRITE the entire tokenURI
     *
     * Requirements:
     * - `msg.sender` needs to be owner or {ACE_WALLET}
     */
    function setTokenURI(uint256 tokenId, string memory permanentTokenURI)
        public
        virtual
    {
        require(
            (msg.sender == ACE_WALLET || msg.sender == owner()),
            "Can only be modified by ACE"
        );
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = permanentTokenURI;
        emit TokenUriChanged(msg.sender, tokenId, permanentTokenURI);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function mintedTokenCount() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * @dev _tokenURIs getter for a tokenId. If tokenURIs has an entry for
     * this tokenId we return this URL. Otherwise we fallback to baseURI with
     * tokenID.
     *
     * @param tokenId URI requested for this tokenId
     *
     * Requirements:
     * - `tokenID` needs to exist
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "URI query for nonexistent token"
        );

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        //return super.tokenURI(tokenId);
        string memory currentBaseURI  = super.tokenURI(tokenId);
        return string(abi.encodePacked(currentBaseURI , baseExtension));
    }

    /**
     * @dev Extends default burn behaviour with deletion of overwritten tokenURI
     * if it exists. Calls super._burn before deletion of tokenURI; Reset Token Royality if set
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
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }


    function reveal() public onlyOwner {
      revealed = true;
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

    function transferForeignToken(address _token, address _to) public onlyOwner returns(bool _sent){
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        _sent = IBEP20(_token).transfer(_to, _contractBalance);
    }
}