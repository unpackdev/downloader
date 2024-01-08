// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";
import "./Strings.sol";
import "./ECDSA.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using SafeCast for uint256;

    event TokenPriceChanged(uint256 newTokenPrice);
    event PresaleConfigChanged(
        address whitelistSigner,
        uint32 startTime,
        uint32 endTime
    );
    event SaleConfigChanged(uint32 startTime, uint32 endTime);
    event IsBurnEnabledChanged(bool newIsBurnEnabled);
    event TreasuryChanged(address newTreasury);
    event PresaleMint(address minter, uint256 count);
    event SaleMint(address minter, uint256 count);
    event BaseTokenURIChanged(string baseURI);
    struct PresaleConfig {
        address whitelistSigner;
        uint32 startTime;
        uint32 endTime;
    }
    struct SaleConfig {
        uint32 startTime;
        uint32 endTime;
    }
    // maxSupply = maxReserveSupply + maxPresaleSupply + maxSaleSupply + maxCommonReserveSupply +
    uint256 public immutable maxSupply;
    uint256 public immutable maxReserveSupply;
    uint256 public immutable maxPresaleSupply;
    uint256 public immutable maxSaleSupply;
    uint256 public immutable maxCommonReserveSupply;

    uint256 public immutable maxPresaleCountForSingleAccount;
    uint256 public immutable maxPresaleCountForSingleCall;
    uint256 public immutable maxSaleCountForSingleCall;

    uint256 public currentTokensReserved;
    uint256 public currentTokensPresold;
    uint256 public currentTokensSold;
    uint256 public currentTokensCommonReserved;
    uint256 public currentTokensMinted;

    address proxyRegistryAddress;
    uint256 public nextTokenId;
    bool public isBurnEnabled;
    address payable public treasury;

    uint256 public tokenPrice;

    PresaleConfig public presaleConfig;
    mapping(address => uint256) public presaleBoughtCounts;

    SaleConfig public saleConfig;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PRESALE_TYPEHASH =
        keccak256("Presale(address recipient)");

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxReserveSupply,
        uint256 _maxPresaleSupply,
        uint256 _maxSaleSupply,
        uint256 _maxCommonReserveSupply,
        uint256 _maxPresaleCountForSingleAccount,
        uint256 _maxPresaleCountForSingleCall,
        uint256 _maxSaleCountForSingleCall,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        maxSupply =
            _maxReserveSupply +
            _maxPresaleSupply +
            _maxSaleSupply +
            _maxCommonReserveSupply;
        maxReserveSupply = _maxReserveSupply;
        maxPresaleSupply = _maxPresaleSupply;
        maxSaleSupply = _maxSaleSupply;
        maxCommonReserveSupply = _maxCommonReserveSupply;
        maxPresaleCountForSingleAccount = _maxPresaleCountForSingleAccount;
        maxPresaleCountForSingleCall = _maxPresaleCountForSingleCall;
        maxSaleCountForSingleCall = _maxSaleCountForSingleCall;
        nextTokenId = _maxReserveSupply;
        _initializeEIP712(_name);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Hall of Fame")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
        emit TokenPriceChanged(_tokenPrice);
    }

    function setupPresale(
        address whitelistSigner,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        uint32 _startTime = startTime.toUint32();
        uint32 _endTime = endTime.toUint32();

        // Check params
        require(whitelistSigner != address(0), "HoF: zero address");
        require(
            _startTime > 0 && _endTime > _startTime,
            "HoF: invalid time range"
        );

        presaleConfig = PresaleConfig({
            whitelistSigner: whitelistSigner,
            startTime: _startTime,
            endTime: _endTime
        });

        emit PresaleConfigChanged(whitelistSigner, _startTime, _endTime);
    }

    function setupSale(uint256 startTime, uint256 endTime) external onlyOwner {
        uint32 _startTime = startTime.toUint32();
        uint32 _endTime = endTime.toUint32();

        require(
            _startTime >= presaleConfig.startTime && _endTime > _startTime,
            "HoF: invalid time range"
        );

        saleConfig = SaleConfig({startTime: _startTime, endTime: _endTime});

        emit SaleConfigChanged(_startTime, _endTime);
    }

    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit IsBurnEnabledChanged(_isBurnEnabled);
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    function commonReserveTokens(address recipient, uint256 count)
        external
        onlyOwner
    {
        require(recipient != address(0), "HoF: zero address");

        uint256 _nextTokenId = nextTokenId;

        require(count > 0, "HoF: invalid count");
        require(_nextTokenId + count <= maxSupply, "HoF: max supply exceeded");
        require(
            currentTokensCommonReserved + count <= maxCommonReserveSupply,
            "HoF: max common reserve supply exceeded"
        );

        currentTokensCommonReserved += count;
        currentTokensMinted += count;

        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(recipient, _nextTokenId + ind);
        }
        nextTokenId += count;
    }

    function reserveTokens(address recipient, uint256 count)
        external
        onlyOwner
    {
        require(recipient != address(0), "HoF: zero address");
        require(
            currentTokensReserved + count <= maxReserveSupply,
            "HoF: max common reserve supply exceeded"
        );
        uint256 _currentTokensReserved = currentTokensReserved;
        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(recipient, _currentTokensReserved + ind);
        }
        currentTokensReserved += count;
        currentTokensMinted += count;
    }

    function mintPresaleTokens(uint256 count) external payable {
        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        // Make sure presale has been set up
        PresaleConfig memory _presaleConfig = presaleConfig;
        require(
            _presaleConfig.whitelistSigner != address(0),
            "HoF: presale not configured"
        );

        require(treasury != address(0), "HoF: treasury not set");
        require(tokenPrice > 0, "HoF: token price not set");
        require(count > 0, "HoF: invalid count");
        require(
            count <= maxPresaleCountForSingleCall,
            "HoF: max count per tx exceeded"
        );
        require(
            block.timestamp >= _presaleConfig.startTime,
            "HoF: presale not started"
        );
        require(block.timestamp < _presaleConfig.endTime, "HoF: presale ended");

        require(_nextTokenId + count <= maxSupply, "HoF: max supply exceeded");
        require(
            currentTokensPresold + count <= maxPresaleSupply,
            "HoF: incorrect Ether value"
        );

        require(
            presaleBoughtCounts[msg.sender] + count <=
                maxPresaleCountForSingleAccount,
            "HoF: presale max presale count for single account exceeded"
        );
        presaleBoughtCounts[msg.sender] += count;
        currentTokensPresold += count;
        currentTokensMinted += count;

        // The contract never holds any Ether. Everything gets redirected to treasury directly.
        if (msg.value != 0) {
            treasury.transfer(msg.value);
        }

        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(msg.sender, _nextTokenId + ind);
        }
        nextTokenId += count;

        emit PresaleMint(msg.sender, count);
    }

    function mintTokens(uint256 count) external payable {
        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        // Make sure presale has been set up
        SaleConfig memory _saleConfig = saleConfig;
        require(_saleConfig.startTime > 0, "HoF: sale not configured");

        require(treasury != address(0), "HoF: treasury not set");
        require(tokenPrice > 0, "HoF: token price not set");
        require(
            count > 0 && count <= maxSaleCountForSingleCall,
            "HoF: invalid count"
        );
        require(
            block.timestamp >= _saleConfig.startTime,
            "HoF: sale not started"
        );
        require(block.timestamp < _saleConfig.endTime, "HoF: sale ended");

        require(
            count <= maxSaleCountForSingleCall,
            "HoF: max count per tx exceeded"
        );
        require(_nextTokenId + count <= maxSupply, "HoF: max supply exceeded");
        require(
            currentTokensSold + count <= maxSaleSupply,
            "HoF: max sale supply exceeded"
        );
        require(tokenPrice * count <= msg.value, "HoF: incorrect Ether value");

        // The contract never holds any Ether. Everything gets redirected to treasury directly.
        treasury.transfer(msg.value);
        currentTokensSold += count;
        currentTokensMinted += count;

        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(msg.sender, _nextTokenId + ind);
        }
        nextTokenId += count;

        emit SaleMint(msg.sender, count);
    }

    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "HoF: burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "HoF: burn caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function revertTransfer(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        recipient.transfer(amount);
    }

    function baseTokenURI() public view virtual returns (string memory);

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}
