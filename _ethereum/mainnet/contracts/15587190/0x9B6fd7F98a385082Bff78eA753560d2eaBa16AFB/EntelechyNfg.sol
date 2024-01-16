// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

import "./ERC2981.sol";
import "./MintpassValidator.sol";
import "./LibMintpass.sol";

/**
 * @dev www.the-nfg.com
 *   _   _ _____ ____ 
 * | \ | |  ___/ ___|
 * |  \| | |_ | |  _ 
 * | |\  |  _|| |_| |
 * |_| \_|_|   \____|
 *                   
 * www.the-nfg.com
 */


contract EntelechyNfg is MintpassValidator, ERC721A, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    AggregatorV3Interface internal priceFeed;

    // Token Limit and Mint Limits
    uint256 public TOKEN_LIMIT = 1500;
    uint256 public freeMintsPerWallet = 1;
    uint256 public allowlistMintsPerWallet = 1;
    uint256 public publicMintsPerWallet = 10;
    mapping(address => uint256) public freeMintAmountByWallet;
    mapping(address => uint256) public allowlistMintAmountByWallet;
    mapping(address => uint256) public publicMintAmountByWallet;

    // Sale Stages Enabled / Disabled
    bool public allowlistMintEnabled = true;
    bool public publicMintEnabled = true;
    bool public freeMintEnabled = true;

    // Limits
    uint256 public RESERVED_ALLOWLIST_TOKEN_LIMIT = 300;
    uint256 public AVAILABLE_FREE_MINT_LIMIT = 150;

    // Minted Amounts
    uint256 public allowlistMinted = 0;
    uint256 public freeMinted = 0;

    // Mint Price
    int256 public mintUSDPrice = 5000000000; // = 50 USD

    string public _baseTokenURI;

    /**
     * @dev ERC721A Constructor
     */
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {
        _setDefaultRoyalty(msg.sender, 2000);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); // Chainlink ETH/USD
        SIGNER_WALLET = 0x723804Db666346463554D43f7e6af1847d313221;
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner
     *
     * Requirements:
     * - `msg.sender` needs to be Owner and payable
     */
    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Overwrite Token ID Start to skip Token with ID 0
     *
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Public Mint Function.
     *
     * @param minter amount of tokens to be minted
     *
     * Requirements:
     * - `minter` user that should receive the token
     * - `quantity` user that should receive the token
     */
    function mint(address minter, uint256 quantity) public payable {
        require(
            publicMintEnabled == true,
            "EntelechyNfg: Public Minting is not Enabled"
        );

        require(
            msg.value >= (mintPrice() * quantity * 199) / 200, // 0.5% treshold due to conversion rate swings
            "EntelechyNfg: Insufficient Amount"
        );

        require(
            (TOKEN_LIMIT - RESERVED_ALLOWLIST_TOKEN_LIMIT + allowlistMinted) >= _nextTokenId(),
            "EntelechyNfg: Token Limit reached"
        );

        require(
            publicMintAmountByWallet[minter] + quantity <=
                publicMintsPerWallet,
            "EntelechyNfg: Maximum Amount per Wallet reached"
        );
        _mint(minter, quantity);
        publicMintAmountByWallet[minter] =
            publicMintAmountByWallet[minter] +
            quantity;
    }

    /**
     * @dev Public Mint Function.
     *
     * @param minter amount of tokens to be minted
     *
     * Requirements:
     * - `minter` user that should receive the token
     * - `quantity` user that should receive the token
     */
    function freeMint(address minter) public payable {
        require(
            freeMintEnabled == true,
            "EntelechyNfg: Free Minting is not Enabled"
        );

        require(
            TOKEN_LIMIT >= _nextTokenId(),
            "EntelechyNfg: Token Limit reached"
        );

        require(
            freeMintAmountByWallet[minter] + 1 <= freeMintsPerWallet,
            "EntelechyNfg: Maximum Amount per Wallet reached"
        );

        require(
            AVAILABLE_FREE_MINT_LIMIT >= freeMinted,
            "EntelechyNfg: No Free Mints left"
        );

        _mint(minter, 1);
        freeMinted = freeMinted + 1;

        // autoclose free minting on limit
        if (freeMinted >= AVAILABLE_FREE_MINT_LIMIT) {
            freeMintEnabled = false;
        }

        freeMintAmountByWallet[minter] = freeMintAmountByWallet[minter] + 1;

        // It's a free mint so send back any paid money, this is on purpose since some payment providers require sending us ether to work
        if (msg.value > 0) {
            require(payable(minter).send(msg.value));
        }
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
     * - `quantity` can't be higher than {mintLimitPerWallet}
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
            "EntelechyNfg: Allowlist Minting is not Enabled"
        );

        require(
            msg.value >= (mintPrice() * quantity * 199) / 200, // 0.5% treshold due to conversion rate swings
            "EntelechyNfg: Insufficient Amount"
        );

        require(
            TOKEN_LIMIT >= _nextTokenId(),
            "EntelechyNfg: All Tokens minted"
        );

        require(
            allowlistMintAmountByWallet[mintpass.wallet] + quantity <=
                allowlistMintsPerWallet,
            "EntelechyNfg: Maximum Amount per Wallet reached"
        );

        require(
            RESERVED_ALLOWLIST_TOKEN_LIMIT >= allowlistMinted,
            "EntelechyNfg: No Allowlist Mints left"
        );

        validateMintpass(mintpass, mintpassSignature);
        _mint(mintpass.wallet, quantity);
        allowlistMinted = allowlistMinted + quantity;

        // autoclose allowlist minting on limit
        if (allowlistMinted >= RESERVED_ALLOWLIST_TOKEN_LIMIT) {
            allowlistMintEnabled = false;
        }

        allowlistMintAmountByWallet[mintpass.wallet] =
            allowlistMintAmountByWallet[mintpass.wallet] +
            1;
    }

    function mintPrice() public view returns (uint256) {
        return convertFiatToEth(mintUSDPrice);
    }

    /**
     * Returns the latest price
     */
    function convertFiatToEth(int256 fiatPrice)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return
            uint256(
                (((fiatPrice * 1000000000) / price) * 1000000000) * (1 wei)
            );
    }

    /**
     * @dev Function to be called by contract owner to enable / disable
     * different mint stages
     *
     * @param _freeMintEnabled true/false
     * @param _allowlistMintEnabled true/false
     * @param _publicMintEnabled true/false
     */
    function setMintingEnabled(
        bool _freeMintEnabled,
        bool _allowlistMintEnabled,
        bool _publicMintEnabled
    ) public virtual onlyOwner {
        freeMintEnabled = _freeMintEnabled;
        allowlistMintEnabled = _allowlistMintEnabled;
        publicMintEnabled = _publicMintEnabled;
    }

    /**
     * @dev Function to be called by contract owner to change mint Limits
     *
     * @param _freeMintsPerWallet 1
     * @param _allowlistMintsPerWallet 1
     * @param _publicMintsPerWallet 10
     */
    function setMintingLimits(
        uint256 _freeMintsPerWallet,
        uint256 _allowlistMintsPerWallet,
        uint256 _publicMintsPerWallet
    ) public virtual onlyOwner {
        freeMintsPerWallet = _freeMintsPerWallet;
        allowlistMintsPerWallet = _allowlistMintsPerWallet;
        publicMintsPerWallet = _publicMintsPerWallet;
    }

    /**
     * @dev Function to change the mint usd price
     * different mint stages
     *
     * @param _mintUSDPrice int256 = 5000000000; // = 50 USD
     */
    function setMintUSDPrice(int256 _mintUSDPrice) public virtual onlyOwner {
        mintUSDPrice = _mintUSDPrice;
    }

    /**
     * @dev Function to change the signer Wallet
     *
     * @param _signerWallet address
     */
    function setSignerWallet(address _signerWallet) public virtual onlyOwner {
        SIGNER_WALLET = _signerWallet;
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

    /**
     * @dev Can be called to reduce the maximum Token supply.
     *
     * @param tokenLimit new token limit
     */
    function reduceTokenLimit(uint256 tokenLimit) public virtual onlyOwner {
        require(
            TOKEN_LIMIT > tokenLimit,
            "EntelechyNfg: New Limit must be below current Limit."
        );
        require(
            tokenLimit >= _nextTokenId(),
            "EntelechyNfg: New Limit must be higher than current Token Supply"
        );
        TOKEN_LIMIT = tokenLimit;
    }

    /**
     * @dev Can be called to reduce the maximum Token supply.
     *
     * @param tokenLimit new token limit
     */
    function releaseAllowlistSpots(uint256 tokenLimit) public virtual onlyOwner {
        require(
            RESERVED_ALLOWLIST_TOKEN_LIMIT > tokenLimit,
            "EntelechyNfg: New Limit must be below current Limit."
        );
        require(
            tokenLimit >= allowlistMinted,
            "EntelechyNfg: New Limit must be higher already minted spots"
        );
        RESERVED_ALLOWLIST_TOKEN_LIMIT = tokenLimit;
        // autoclose allowlist minting on limit
        if (allowlistMinted >= RESERVED_ALLOWLIST_TOKEN_LIMIT) {
            allowlistMintEnabled = false;
        }
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
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}

/** created with bowline.app **/
