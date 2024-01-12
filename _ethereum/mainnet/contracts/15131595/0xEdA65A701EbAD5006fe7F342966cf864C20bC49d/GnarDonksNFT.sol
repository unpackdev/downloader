// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Pausable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./IERC20Metadata.sol";

import "./ERC2981.sol";
import "./EIP712Base.sol";
import "./Claimable.sol";
import "./Math.sol";
// Template based on BitMaps for High Performance NFTs vs Gas Cost
import "./ERC721W.sol";
// Import the chainlink Aggregator Interface
import "./AggregatorV3Interface.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title GnarDonksNFT
 * @custom:a w3box.com
 */
contract GnarDonksNFT is
    ERC721W,
    Pausable,
    Claimable,
    Math,
    EIP712Base,
    ReentrancyGuard,
    AccessControl,
    ERC2981
{
    using Address for address;
    using SafeMath for uint256;

    modifier onlyAdmin {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    // Constant for Minter Role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant MASK_16 = 65535;
    uint256 private constant MASK_32 = 4294967295;
    uint256 private constant MASK_64 = 18446744073709551615;

    uint256[6] private tierPricesInEth = [1 ether, 0, 0, 0, 0, 0];
    uint256[6] private tierPricesInUsd = [0, 5000, 10000, 25000, 150000, 250000];

    // Slippage Limits
    uint256 private slipETH;
    uint256 private slipUSD;

    bool private ethEnabled;

    mapping(address => bool) private stableCoins;

    // Proxy Address for Frictionless with OpenSea
    address private immutable proxyRegistryAddress;

    // Payment  Smart Contract Address
    address private paymentContract;
    
    // Declare the priceFeed as an Aggregator Interface
    AggregatorV3Interface internal immutable priceFeed;
    
    // Launch Time
    uint256 internal launchTs;

    // Mapping of Tier Package BitMap to Tier ID
    mapping(uint256 => uint256) internal tiers;
    // Event for Token Minted with ETH
    /**
     * @dev Event when setting the Cost per Token
     * @param Payee address of the minter
     * @param tokendID TokenId of the minted token
     * @param Currency Tiker (USD/ETH)
     * @param Amount Amount of Token (Stable or Native)
     * @param tokenAddress timestamp of the token
     */
    event Mint(
        address Payee,
        uint256 tokendID,
        string Currency,
        uint256 Amount,
        address tokenAddress
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _launchTs, // TimeStamp of the launch
        uint256 _totalSupply,
        address _proxyRegistryAddress,
        address _priceFeedAddress, // Address of the Aggregator Interface for Getting Price ETH/USD
        uint96 _royalties, // Royalties far all tokens ids
        address _paymentContract
    )
        public
        // Setup manually the BaseURI and the Contract URI because the constructor raised the deep stack limit
        ERC721W(
            _name,
            _symbol,
            "https://nft.gnardonks.com/",
            "https://nft.gnardonks.com/gnardonks.json",
            _totalSupply
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(address(this), _royalties);
        proxyRegistryAddress = _proxyRegistryAddress;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        require(
            _paymentContract != address(0x0) && _paymentContract.isContract(),
            "Payment Contract Address is not valid"
        );
        // Enable ETH by defaut
        ethEnabled = true;
        // Enable USDC by default
        stableCoins[address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = true;
        paymentContract = _paymentContract;
        // Launch TimeStamp
        launchTs = _launchTs;
        // TimeStamp Period Limits per Tier

        // Slippage Limits
        slipETH = 1010; // represent 1%
        slipUSD = 1020; // represent 2%
        //[ total supply 16, total_sales 16, sales period 1 32, period supply 16, sales period 1 16, ... sales period 10 16].
        tiers[1] = 5850;
        tiers[2] =
            2500 |
            (0 << 16) |
            (31560000 << 32) |
            (250 << 64); // 250 per yer
        tiers[3] =
            1000 |
            (0 << 16) |
            (31560000 << 32) |
            (100 << 64); // 100 per yer
        tiers[4] =
            500 |
            (0 << 16) |
            (31560000 << 32) |
            (50 << 64); // 50 per yer
        tiers[5] =
            75 |
            (0 << 16) |
            (63120000 << 32) |
            (15 << 64); // 15 every 2 years
        tiers[6] = 10;
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     * @param _owner The owner of the NFT
     * @param _operator The operator to be added or removed
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
        return ERC721W.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC1155.
     * @dev See {ERC1155Pausable}.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     */
    function pause(bool status) public onlyAdmin {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /** MINT METHOD FOR ETH, USD AND MOONPAY */

    /**
     * @dev Method for Mint a new token, based on Tiers and with Payment in ETH
     * @param to The address of the recipient
     * @param tokenId tokenId of the token to be minted, with this define the tier
     */
    function mint(address to, uint256 tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(ethEnabled, "Mint with ETH is temporarily disabled");

        // Pre Check of tier before to mint
        beforeMintOfTier(tierOf(tokenId));
        // Get the price of the token
        uint256 price = _mintTierPriceInETH(tierOf(tokenId), false);
        // Get the balance of the sender
        uint256 balance = msg.value;
        // Check if the balance is enough to pay the price
        require(
            balance >= price,
            "ERC721: Insufficient funds to pay the price"
        );
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        
        (bool success, ) = address(paymentContract).call{value: balance}("");
        
        require(success,"Address: unable to send value, recipient may have reverted");
        
        // Call the mint method from ERC721W
        _safeMint(to, tokenId);
        // Post check of tier after to mint
        afterMintOfTier(tierOf(tokenId));
        // Event when the Smart Contract Send Amount of Native or ERC20 tokens
        emit Mint(to, tokenId, "ETH", price, address(0));
    }

    /**
     * @dev Method for Mint a new token, based on Tiers and with Payment in USD(Tether, USD Coin, BUSD Coin)
     * @param to The address of the recipient
     * @param tokenId tokenId of the token to be minted, with this define the tier
     */
    function mintWithUSD(
        address to,
        uint256 tokenId,
        address _stableCoin
    ) external
        virtual
        nonReentrant
        whenNotPaused
    {
        require(_stableCoin.isContract(), "Invalid stable coin address");
        require(stableCoins[_stableCoin], "ERC721: Stable Coin token not permitted");

        // Pre Check of tier before to mint
        beforeMintOfTier(tierOf(tokenId));
        // Check if the balance is enough to pay the price take account the decimals of the stable coin
        IERC20Metadata _stableToken = IERC20Metadata(_stableCoin);

        // Get the price of the token
        uint256 price = tierPriceInUSD(tierOf(tokenId)) * (10**_stableToken.decimals());

        require(
            _stableToken.balanceOf(_msgSender()) >= price,
            "ERC721: Not enough Stable Coin"
        );

        // Verify before to Transfer Stable Coin
        _beforeTokenTransfers(address(0), to, tokenId);
        // Transfer the Stable Coin to Split Payment process
        bool success_treasury = _stableToken.transferFrom(
            _msgSender(),
            address(paymentContract),
            price
        );
        require(
            success_treasury,
            "ERC721: Can't create Donks, you don't have enough stable coins"
        );
        // Call the mint method from ERC721W
        _safeMint(to, tokenId);
        // Post check of tier after to mint
        afterMintOfTier(tierOf(tokenId));
        // post check after mint
        _afterTokenTransfers(address(0), to, tokenId);
        // Event when the Smart Contract Send Amount of Native or ERC20 tokens
        emit Mint(to, tokenId, "USD", price, _stableCoin);
    }

    /**
     * @dev Method for Internal for Mint a new token, based on Tiers and with Payment in MoonPay
     * @param to The address of the recipient
     * @param tokenId tokenId of the token to be minted, with this define the tier
     */
    function mintTo(address to, uint256 tokenId)
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
        nonReentrant
    {
        // Pre Check of tier before to mint
        beforeMintOfTier(tierOf(tokenId));
        // Call the mint method from ERC721W
        _safeMint(to, tokenId);
        // Post check of tier after to mint
        afterMintOfTier(tierOf(tokenId));
    }

    /**
     * @dev Method for Mint a new token, based on Tiers and with Payment in MoonPay
     * @param _owner The address of the recipient
     * @param tokenIds Arrays of tokenId of the token to be minted, with any Tier, but with preview verification of Supply by timestamp
     */
    function mintMultiple(address _owner, uint256[] calldata tokenIds)
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
        nonReentrant
    {
        _mintMultiple(_owner, tokenIds);
    }

    /**
     * @dev Method for Internal for Mint by Batch a Group of new tokens, based with Verification of Supply by timestamp
     * @param _owner Arrays of addresses of the recipient
     * @param tokenIds Arrays of tokenId of the token to be minted, with any Tier, but with preview verification of Supply by timestamp
     */
    function batchMint(
        address[] calldata _owner,
        uint256[] calldata tokenIds,
        uint64 locktime
    ) 
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
        nonReentrant
    {
        _batchMint(_owner, tokenIds, locktime);
    }

    /**
     * @dev Method for Expose the burn method from ERC721W
     * @param tokenId tokenId of the token to be burned, with any Tier, but with preview verification of Supply by timestamp
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    /** HELPERS FOR TIERS AND PRICES */

    function tierOf(uint256 tokenId) public pure returns (uint256) {
        if (tokenId > 4150) {
            return 1;
        } else if (tokenId > 1650) {
            return 2;
        } else if (tokenId > 650) {
            return 3;
        } else if (tokenId > 150) {
            return 4;
        } else if (tokenId > 50) {
            return 5;
        } else {
            return 6;
        }
    }

    function _mintTierPriceInETH(uint256 tier, bool addSlippage) internal view returns (uint256 price) {
        price = tierPricesInEth[tier - 1];
        if(price == 0) {
            price = addSlippage ? mulDiv(_usdToEth(tierPriceInUSD(tier)), slipETH, 1000) : _usdToEth(tierPriceInUSD(tier));
        }
    }

    function tierPriceInETH(uint256 tier) public view returns (uint256 price) {
        price = _mintTierPriceInETH(tier, true);
    }

    function tierPriceInUSD(uint256 tier) public view returns (uint256 price) {
        price = tierPricesInUsd[tier - 1];
        if (price == 0) {
            price = _ethToUsd(_mintTierPriceInETH(tier, false)) / 1 ether; // the price is 1 ether, and is native in solididty
        }
    }

    /**
     * @dev Method for Internal Getting the convertion of USD to ETH
     * @param amount The amount of USD in decimal to convert
     */
    function _ethToUsd(uint256 amount) internal view returns (uint256) {
        (int256 _price, uint8 _decimals) = _getLatestPrice();
        uint256 price = mulDiv(uint256(_price), slipUSD * (10**15), 10**18); // add Slippage Over to the market price
        return mulDiv(amount, price, 10**(_decimals));
    }

    /**
     * @dev Method for Internal Getting the convertion of ETH to USD
     * @param amount The amount of ETH in decimal to convert
     */
    function _usdToEth(uint256 amount) internal view returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        (int256 price, uint8 _decimals) = _getLatestPrice();
        return mulDiv(amount * 10**18, 10**(_decimals), uint256(price));
    }

    /**
     * Returns the latest price and # of decimals to use
     */
    function _getLatestPrice()
        internal
        view
        returns (int256 price, uint8 _decimals)
    {
        (, price, , , ) = priceFeed.latestRoundData();
        _decimals = priceFeed.decimals();
        return (price, _decimals);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721W, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(!paused(), "ERC721: Can't transfer tokens while paused");

        super._beforeTokenTransfers(from, to, tokenId);
    }

    /**
     * @dev Method for verify and storage the Tier
     * @param tier uint256
     */
    function beforeMintOfTier(uint256 tier) internal {
        require(
            block.timestamp > launchTs,
            "ERC721: Can't mint, before to start launch"
        );
        // Check total supply x total sales
        uint256 supply = tiers[tier] & MASK_16;
        uint256 sales = (tiers[tier] >> 16) & MASK_16;

        require(sales < supply, "Sales for tier are finished");

        // update total sales
        tiers[tier] = (tiers[tier] & ~(MASK_16 << 16)) | (++sales << 16);
        //  tiers[5] = 90 | (0 << 16) | (31560000 << 32) | (15 << 64); // every 2 years
        uint256 period = (tiers[tier] >> 32) & MASK_32;

        if (period > 0) {
            supply = (tiers[tier] >> 64) & MASK_16; // period supply
            period = (block.timestamp - launchTs) / period; // period position
            if (period < 11) {
                // Maximal period is 11
                sales = (tiers[tier] >> (80 + (period * 16))) & SIZE_MASK; // period sales

                // check total period supply x period sales
                require(
                    sales < supply,
                    "Sales for tier are finished in this period"
                );

                // update tier sales
                tiers[tier] =
                    (tiers[tier] & ~(MASK_16 << (80 + (period * 16)))) |
                    (++sales << (80 + (period * 16)));
            }
        }
    }

    /**
     * @dev Method to Get Available Token per Tier, per Period
     * @param _tier Tier of the Token
     */
    function getAvailableTokenPerTier(uint256 _tier)
        public
        view
        returns (uint256 available)
    {
        require(_tier > 0 && _tier <= 6, "Tier must be between 1 and 6");
        // Check total supply x total sales
        uint256 _totalSupply = tiers[_tier] & MASK_16;
        uint256 _totalSales = (tiers[_tier] >> 16) & MASK_16;
        // Getting Period per Tier
        uint256 period = (tiers[_tier] >> 32) & MASK_32;
        if (period > 0) {
            uint256 supply = (tiers[_tier] >> 64) & MASK_16; // period supply
            period = (block.timestamp - launchTs) / period; // period position
            if (period < 11) {
                // Maximal period is 11
                uint256 sales = (tiers[_tier] >> (80 + (period * 16))) &
                    SIZE_MASK; // period sales
                available = supply > sales ? supply - sales : 0;
            } else {
                available = _totalSupply > _totalSales
                    ? _totalSupply - _totalSales
                    : 0;
            }
        } else {
            available = _totalSupply > _totalSales
                ? _totalSupply - _totalSales
                : 0;
        }
    }

    /**
     * @dev Method to Get Available Token per Tier, per Period
     * @param _tier Tier of the Token
     */
    function getTotalAvailableTokenPerTier(uint256 _tier)
        public
        view
        returns (uint256 available)
    {
        require(_tier > 0 && _tier <= 6, "Tier must be between 1 and 6");
        // Check total supply x total sales
        uint256 _totalSupply = tiers[_tier] & MASK_16;
        uint256 _totalSales = (tiers[_tier] >> 16) & MASK_16;
        available = _totalSupply > _totalSales
            ? _totalSupply - _totalSales
            : 0;
    }

    /**
     * @dev Method for verify and storage the Tier
     * @param tier uint256
     */
    function afterMintOfTier(uint256 tier) internal {}

    /**
     * @dev Method for Setting the Price of Each Tier of TokenIds
     * @param _tierPrices Arrays of Tier ETH Price in Decimals
     */
    function setTierPricesInEth(uint256[6] calldata _tierPrices) external onlyAdmin {
        tierPricesInEth = _tierPrices;
    }

    /**
     * @dev Method for Setting the Price of Each Tier of TokenIds
     * @param _tierPrices Arrays of Tier USD Price in Decimals
     */
    function setTierPricesInUsd(uint256[6] calldata _tierPrices) external onlyAdmin {
        tierPricesInUsd = _tierPrices;
    }

    /**
     * @dev Method for Setting the TimeStamps of Each Tier of TokenIds
     * @param limits Arrays of TimeStamp range of Period to Mint an Specific Amount of Tokens, per Tier
     */
    function setTSLimits(uint256[6] calldata limits)
        public
        virtual
        onlyAdmin {
        for (uint256 i = 0; i < limits.length; i++) {
            uint256 newLimit = limits[i] & MASK_32;
            // update Time Stamps of Each Tier
            tiers[i + 1] =
                (tiers[i + 1] & ~(MASK_32 << 32)) |
                (newLimit << 32);
        }
    }

    /**
     * @dev Method for Setting the Amount of Token can Minted per Period/Tier
     * @param limits Arrays of Token can minted per Period/Tier
     */
    function setAmountLimitsPerPeriod(uint256[6] calldata limits)
        public
        virtual
        onlyAdmin
    {
        for (uint256 i = 0; i < limits.length; i++) {
            uint256 newAmount = limits[i] & MASK_16;
            // update Amount Lmits of Each Tier
            tiers[i + 1] =
                (tiers[i + 1] & ~(MASK_16 << 64)) |
                (newAmount << 64);
        }
    }

    /**
     * @dev Method to Add Slippage to the Price of TokenIds in ETH and USD
     * @param _slipETH value in base 1000, where 1001 represent 0.1%, and 1010 represent 1% to represent the slippage in ETH
     * @param _slipUSD value in base 1000, where 1001 represent 0.1%, and 1010 represent 1% to represent the slippage in USD
     */
    function setSlippage(uint256 _slipETH, uint256 _slipUSD)
        external
        onlyAdmin
    {
        require(
            _slipETH > 1000,
            "ERC721: Slippage ETH must be greater than 100"
        );
        require(
            _slipUSD > 1000,
            "ERC721: Slippage USD must be greater than 100"
        );
        slipETH = _slipETH;
        slipUSD = _slipUSD;
    }

    /**
     * @dev Method for Setting the Payment Smart Contract
     * @param _paymentContract Address of the Payment Contract
     */
    function setPaymentContract(address _paymentContract)
        external
        onlyAdmin
    {
        require(
            _paymentContract != address(0) &&
                _paymentContract.isContract(),
            "ERC721: Payment Contract is not valid"
        );
        paymentContract = _paymentContract;
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     */
    function claimValues(address _token, address _to)
        external
        onlyAdmin
    {
        _claimValues(_token, _to);
    }

    /**
     * @dev Withdraw ERC721 or ERC1155 deposited for this contract
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimNFTs(address _token, uint256 _tokenId, address _to)
        external
        onlyAdmin
    {
        _claimNFTs(_token, _tokenId, _to);
    }

    /**
     * @dev Enable/disable mints with ETH
     */
    function setEthEnabled(bool enabled)
        external
        onlyAdmin
    {
        ethEnabled = enabled;
    }

    /**
     * @dev Enable/disable mints with a stable coin
     */
    function setStableCoinEnabled(address stableCoin, bool enabled)
        public
        onlyAdmin
    {
        stableCoins[stableCoin] = enabled;
    }

    /** 
     * @dev returns tier sales data
     */
    function getTier(uint256 tier)
        external
        view
        returns (uint256 tierData)
    {
        tierData = tiers[tier];
    }

    /**
     * @notice Method to reduce the friction with Opensea by allowing the Contract URI to be updated
     * @dev This method is only available for the owner of the contract
     * @param _contractURI The new contract URI
     */
    function setContractURI(string memory _contractURI)
        external
        onlyAdmin
    {
        _setContractURI(_contractURI);
    }
}
