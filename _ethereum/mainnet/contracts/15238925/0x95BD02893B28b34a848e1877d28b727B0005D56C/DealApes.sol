// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./AggregatorV3Interface.sol";
import "./EnumerableSet.sol";

// import "./console.sol";
contract DealApes is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    string private baseURI;

    AggregatorV3Interface internal priceFeed;

    EnumerableSet.AddressSet private operators;

    struct Collection {
        string name;
        uint256 maxSupply;
        uint256 totalMinted;
        bool enabled;
    }

    struct Whitelist {
        uint256 maxMintPerWallet;
        uint256 usdPrice;
        bytes32 merkleRoot;
    }

    mapping(uint256 => mapping(address => uint256)) public mintedPerWallet;

    uint256 public collectionsLength;
    mapping(uint256 => Collection) public collections;

    uint256 public whitelistsLength;
    mapping(uint256 => Whitelist) public whitelists;

    bool public publicSale = false;
    uint256 public publicSaleUsdPrice = 955;

    address public treasuryOwner = 0xefbaa37517161660117588F5790Bb20cFceD7d10;
    address public feesReceiver;
    uint256 public FEES_BPS = 75;

    modifier onlyOwnerOrOperator() {
        // console.log("owner", owner());
        // console.log("msg.sender", msg.sender);
        // console.log("isOperator", operators.contains(msg.sender));
        // console.log("-----");
        require(
            msg.sender == owner() || operators.contains(msg.sender),
            "invalid-caller"
        );
        _;
    }

    function addOperator(address _newOperator) external onlyOwner {
        operators.add(_newOperator);
    }

    function removeOperator(address _operator) external onlyOwner {
        operators.remove(_operator);
    }

    function getOperators()
        external
        view
        returns (address[] memory _operators)
    {
        _operators = operators.values();
    }

    function _addCollection(
        string memory _name,
        uint256 _maxSupply,
        bool _enabled
    ) internal {
        require(_maxSupply > 0, "ts-lt-1");
        collections[collectionsLength] = Collection({
            name: _name,
            maxSupply: _maxSupply,
            totalMinted: 0,
            enabled: _enabled
        });
        collectionsLength++;
    }

    function _addWhitelist(uint256 _maxMintPerWallet, uint256 _usdPrice)
        internal
    {
        require(_maxMintPerWallet > 0, "mmpw-lt-1");
        require(_usdPrice > 0, "usd-lt-1");
        whitelists[whitelistsLength] = Whitelist({
            maxMintPerWallet: _maxMintPerWallet,
            usdPrice: _usdPrice,
            merkleRoot: 0x0
        });
        whitelistsLength++;
    }

    function updateMerkleRoot(uint256 _whitelistId, bytes32 _merkleRoot)
        external
        onlyOwnerOrOperator
    {
        require(_whitelistId < whitelistsLength, "wl-id-oob");
        whitelists[_whitelistId].merkleRoot = _merkleRoot;
    }

    function toggleCollection(uint256 _collectionId)
        external
        onlyOwnerOrOperator
    {
        collections[_collectionId].enabled = !collections[_collectionId]
            .enabled;
    }

    function togglePublicSale() external onlyOwnerOrOperator {
        publicSale = !publicSale;
    }

    constructor(address _priceFeedAddress) ERC721("Deal Apes", "DEAL APES") {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);

        _addCollection("Diletta", 1250, true);
        _addCollection("The Golden Goddess", 1250, false);
        _addCollection("The Last Dance", 1250, false);
        _addCollection("The KISS", 1250, false);

        _addWhitelist(3, 355); // P1
        _addWhitelist(3, 555); // P2
        _addWhitelist(3, 755); // P3
        _addWhitelist(3, 855); // P4
    }

    function updatewhitelistMaxMint(
        uint256 _whitelistId,
        uint256 _maxMintPerWallet
    ) external onlyOwnerOrOperator {
        require(_whitelistId < whitelistsLength, "wl-id-oob");
        whitelists[_whitelistId].maxMintPerWallet = _maxMintPerWallet;
    }

    function updatePublicSaleUsdPrice(uint256 _usdPrice)
        external
        onlyOwnerOrOperator
    {
        require(_usdPrice > 0, "usd-lt-1");
        publicSaleUsdPrice = _usdPrice;
    }

    function updateWhitelistSaleUsdPrice(
        uint256 _whitelistId,
        uint256 _usdPrice
    ) external onlyOwnerOrOperator {
        require(_whitelistId < whitelistsLength, "wl-id-oob");
        require(_usdPrice > 0, "usd-lt-1");
        whitelists[_whitelistId].usdPrice = _usdPrice;
    }

    function getPublicPriceInEth() public view returns (uint256) {
        return _usdToEth(publicSaleUsdPrice);
    }

    function getWhitelistPriceInEth(uint256 _whitelistId)
        public
        view
        returns (uint256)
    {
        require(_whitelistId < whitelistsLength, "wl-id-oob");
        return _usdToEth(whitelists[_whitelistId].usdPrice);
    }

    function _usdToEth(uint256 _usdAmount)
        internal
        view
        returns (uint256 _price)
    {
        (
            ,
            /*uint80 roundID*/
            int256 _ethPrice, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        _price = ((_usdAmount * 10**8) * 1e18) / uint256(_ethPrice);
    }

    function mintPublic(uint256 _collectionId, uint256 _numberOfTokens)
        external
        payable
    {
        require(publicSale, "public-sale-not-open");
        uint256 _totalPrice = getPublicPriceInEth() * _numberOfTokens;
        require(msg.value >= _totalPrice, "insufficient-funds");

        _mint(_collectionId, _numberOfTokens, msg.sender);
    }

    function mintWhitelist(
        uint256 _collectionId,
        uint256 _whitelistId,
        uint256 _numberOfTokens,
        bytes32[] calldata _proof
    ) external payable {
        require(_whitelistId < whitelistsLength, "wl-id-oob");

        mintedPerWallet[_whitelistId][msg.sender] += _numberOfTokens;

        require(
            mintedPerWallet[_whitelistId][msg.sender] <=
                whitelists[_whitelistId].maxMintPerWallet,
            "max-mint-exceeded"
        );

        bool isWhitelisted = MerkleProof.verify(
            _proof,
            whitelists[_whitelistId].merkleRoot,
            keccak256(abi.encodePacked(msg.sender))
        );

        require(isWhitelisted, "not-whitelisted");
        require(
            msg.value >=
                _usdToEth(whitelists[_whitelistId].usdPrice) * _numberOfTokens,
            "insufficient-funds"
        );

        _mint(_collectionId, _numberOfTokens, msg.sender);
    }

    function mintPrivate(
        uint256 _collectionId,
        uint256 _numberOfTokens,
        address _to
    ) external onlyOwnerOrOperator {
        _mint(_collectionId, _numberOfTokens, _to);
    }

    function _mint(
        uint256 _collectionId,
        uint256 _numberOfTokens,
        address _to
    ) internal {
        require(_collectionId < collectionsLength, "invalid-collection");
        require(collections[_collectionId].enabled, "collection-disabled");
        require(
            collections[_collectionId].maxSupply -
                collections[_collectionId].totalMinted >=
                _numberOfTokens,
            "collection-sold-out"
        );
        uint256 _totalMinted = collections[_collectionId].totalMinted;
        collections[_collectionId].totalMinted += _numberOfTokens;

        for (uint256 i; i < _numberOfTokens; i++) {
            // console.log(_collectionId * collections[_collectionId].maxSupply + _totalMinted + (i + 1));
            _safeMint(
                _to,
                _collectionId *
                    collections[_collectionId].maxSupply +
                    _totalMinted +
                    (i + 1)
            );
        }
    }

    function setBaseURI(string memory newURI_) external onlyOwner {
        baseURI = newURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "non-existent-token");
        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId_.toString()));
    }

    function updateFeesBps(uint256 _bps) external onlyOwnerOrOperator {
        require(_bps > 150, "bps-gt-15");
        FEES_BPS = _bps;
    }

    function updateTreasuryOwner(address _treasuryOwner)
        external
        onlyOwnerOrOperator
    {
        require(_treasuryOwner != address(0), "invalid-address");
        treasuryOwner = _treasuryOwner;
    }

    function updateFeesReceiver(address _feesReceiver)
        external
        onlyOwnerOrOperator
    {
        feesReceiver = _feesReceiver;
    }

    function withdraw() external onlyOwnerOrOperator {
        uint256 _balance = address(this).balance;
        // console.log("withdrawing", _balance, "wei");
        if (feesReceiver != address(0) && FEES_BPS != 0) {
            uint256 _fees = (_balance * FEES_BPS) / 1000;
            _balance = _balance - _fees;
            // console.log("feesReceiver", feesReceiver);
            // console.log("withdrawing", _fees, "wei");
            payable(feesReceiver).transfer(_fees);
        }
        payable(treasuryOwner).transfer(_balance);
    }
}
