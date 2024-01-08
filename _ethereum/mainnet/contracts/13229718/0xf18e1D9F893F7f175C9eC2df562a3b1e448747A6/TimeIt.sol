pragma solidity =0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";
import "./SafeCast.sol";

contract TimeIt is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using SafeCast for uint256;

    event TokenPriceChanged(uint256 newTokenPrice);
    event PresaleConfigChanged(address whitelistSigner, uint32 startTime, uint32 endTime);
    event SaleConfigChanged(uint32 startTime, uint32 initMaxCount, uint32 maxCountUnlockTime, uint32 unlockedMaxCount);
    event IsBurnEnabledChanged(bool newIsBurnEnabled);
    event TreasuryChanged(address newTreasury);
    event BaseURIChanged(string newBaseURI);
    event MaxSupplyChanged(uint256 newBaseURI);
    event ReserveCountChanged(uint256 reserveCount);
    event PresaleMint(address minter, uint256 count);
    event SaleMint(address minter, uint256 count);

    // Both structs fit in a single storage slot for gas optimization
    struct PresaleConfig {
        address whitelistSigner;
        uint32 startTime;
        uint32 endTime;
    }
    struct SaleConfig {
        uint32 startTime;
        uint32 initMaxCount;
        uint32 maxCountUnlockTime;
        uint32 unlockedMaxCount;
    }

    uint256 public maxSupply;
    uint256 public reserveCount;

    uint256 public tokensReserved;
    uint256 public nextTokenId;
    bool public isBurnEnabled;
    address payable public treasury;

    uint256 public tokenPrice;

    PresaleConfig public presaleConfig;
    mapping(address => uint256) public presaleBoughtCounts;

    SaleConfig public saleConfig;

    string public baseURI;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PRESALE_TYPEHASH = keccak256("Presale(address buyer,uint256 maxCount)");

    constructor(uint256 _maxSupply, uint256 _reserveCount) ERC721("TimeIt Token", "TIMEIT") {
        require(_reserveCount <= _maxSupply, "TimeIt: reserve count out of range");

        maxSupply = _maxSupply;
        reserveCount = _reserveCount;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Time It")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function reserveTokens(address recipient, uint256 count) external onlyOwner {
        require(recipient != address(0), "TimeIt: zero address");

        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        require(count > 0, "TimeIt: invalid count");
        require(_nextTokenId + count <= maxSupply, "TimeIt: max supply exceeded");

        require(tokensReserved + count <= reserveCount, "TimeIt: max reserve count exceeded");
        tokensReserved += count;

        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(recipient, _nextTokenId + ind);
        }
        nextTokenId += count;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
        emit TokenPriceChanged(_tokenPrice);
    }

    function setUpPresale(
        address whitelistSigner,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        uint32 _startTime = startTime.toUint32();
        uint32 _endTime = endTime.toUint32();

        // Check params
        require(whitelistSigner != address(0), "TimeIt: zero address");
        require(_startTime > 0 && _endTime > _startTime, "TimeIt: invalid time range");

        presaleConfig = PresaleConfig({whitelistSigner: whitelistSigner, startTime: _startTime, endTime: _endTime});

        emit PresaleConfigChanged(whitelistSigner, _startTime, _endTime);
    }

    function setUpSale(
        uint256 startTime,
        uint256 initMaxCount,
        uint256 maxCountUnlockTime,
        uint256 unlockedMaxCount
    ) external onlyOwner {
        uint32 _startTime = startTime.toUint32();
        uint32 _initMaxCount = initMaxCount.toUint32();
        uint32 _maxCountUnlockTime = maxCountUnlockTime.toUint32();
        uint32 _unlockedMaxCount = unlockedMaxCount.toUint32();

        require(_initMaxCount > 0 && _unlockedMaxCount > 0, "TimeIt: zero amount");
        require(_startTime > 0 && _maxCountUnlockTime > _startTime, "TimeIt: invalid time range");

        saleConfig = SaleConfig({
            startTime: _startTime,
            initMaxCount: _initMaxCount,
            maxCountUnlockTime: _maxCountUnlockTime,
            unlockedMaxCount: _unlockedMaxCount
        });

        emit SaleConfigChanged(_startTime, _initMaxCount, _maxCountUnlockTime, _unlockedMaxCount);
    }

    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit IsBurnEnabledChanged(_isBurnEnabled);
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    function setBaseURI(string calldata newbaseURI) external onlyOwner {
        baseURI = newbaseURI;
        emit BaseURIChanged(newbaseURI);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit MaxSupplyChanged(newMaxSupply);
    }

    function setReserveCount(uint256 newReserveCount) external onlyOwner {
        reserveCount = newReserveCount;
        emit ReserveCountChanged(newReserveCount);
    }

    function mintPresaleTokens(
        uint256 count,
        uint256 maxCount,
        bytes calldata signature
    ) external payable {
        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        // Make sure presale has been set up
        PresaleConfig memory _presaleConfig = presaleConfig;
        require(_presaleConfig.whitelistSigner != address(0), "TimeIt: presale not configured");

        require(treasury != address(0), "TimeIt: treasury not set");
        require(tokenPrice > 0, "TimeIt: token price not set");
        require(count > 0, "TimeIt: invalid count");
        require(block.timestamp >= _presaleConfig.startTime, "TimeIt: presale not started");
        require(block.timestamp < _presaleConfig.endTime, "TimeIt: presale ended");

        require(_nextTokenId + count <= maxSupply, "TimeIt: max supply exceeded");
        require(tokenPrice * count == msg.value, "TimeIt: incorrect Ether value");

        // Verify EIP-712 signature
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PRESALE_TYPEHASH, msg.sender, maxCount)))
        );
        address recoveredAddress = digest.recover(signature);
        require(
            recoveredAddress != address(0) && recoveredAddress == _presaleConfig.whitelistSigner,
            "TimeIt: invalid signature"
        );

        require(presaleBoughtCounts[msg.sender] + count <= maxCount, "TimeIt: presale max count exceeded");
        presaleBoughtCounts[msg.sender] += count;

        // The contract never holds any Ether. Everything gets redirected to treasury directly.
        treasury.transfer(msg.value);

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
        require(_saleConfig.startTime > 0, "TimeIt: sale not configured");

        require(treasury != address(0), "TimeIt: treasury not set");
        require(tokenPrice > 0, "TimeIt: token price not set");
        require(count > 0, "TimeIt: invalid count");
        require(block.timestamp >= _saleConfig.startTime, "TimeIt: sale not started");

        require(
            count <=
                (
                    block.timestamp >= _saleConfig.maxCountUnlockTime
                        ? _saleConfig.unlockedMaxCount
                        : _saleConfig.initMaxCount
                ),
            "TimeIt: max count per tx exceeded"
        );
        require(_nextTokenId + count <= maxSupply, "TimeIt: max supply exceeded");
        require(tokenPrice * count == msg.value, "TimeIt: incorrect Ether value");

        // The contract never holds any Ether. Everything gets redirected to treasury directly.
        treasury.transfer(msg.value);

        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(msg.sender, _nextTokenId + ind);
        }
        nextTokenId += count;

        emit SaleMint(msg.sender, count);
    }

    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "TimeIt: burning disabled");
        require(_isApprovedOrOwner(msg.sender, tokenId), "TimeIt: burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}