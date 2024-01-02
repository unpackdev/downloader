// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./web3-erc721-v1.sol";

interface IWeb3BasicNftMarketplace {
    struct Sale {
        uint256 amount;
        uint256 price;
        uint256 startingTime;
        uint256 endTime;
    }

    function sales(
        address _contract,
        uint256 _tokenId,
        address _owner
    ) external view returns (Sale memory);

    function createSaleDelegate(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        uint256 _startingTime,
        uint256 _endTime,
        address _owner
    ) external;

    function updateSaleDelegate(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        address _owner
    ) external;
}

contract Web3ERC721FactoryV1 is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address payable;
    using SafeMath for uint256;

    event CollectionCreated(
        address indexed collection,
        address indexed owner,
        string name,
        string symbol,
        uint256 flags,
        uint256 indexed uuid
    );

    event MarketplaceUpdated(address newMarketplace);
    event LatchProxyUpdated(address newLatchProxy);

    address private _marketplace;
    address private _latch;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice initialize the contract and its upgrade
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _marketplace = 0x38987f52a809E2BCdf2390b31088666528411291;
        _latch = 0x3Ce3c3d135A2D194A318B74f35Deefc28f431dde;
    }

    /// @notice deploys a new Web3ERC721 contract for the caller and initializes it
    /// @param _name name of the collection
    /// @param _symbol symbol of the collection
    /// @param _defaultFee default fee in basis points
    /// @param _flags behaviour flags ((1)transferable, (2)latcheable, (3)uploadable)
    /// @param _metadata ipfs metadata of the nfts
    /// @param _prices prices of the nfts
    /// @param _fees fees of the nfts
    /// @param _uuid uuid of the collection
    /// @param _uuids uuids of the nfts
    function deployAndInitialize(
        string memory _name,
        string memory _symbol,
        uint96 _defaultFee,
        uint256 _flags,
        string[] memory _metadata,
        uint256[] memory _prices,
        uint96[] memory _fees,
        uint256 _uuid,
        uint256[] memory _uuids
    ) public nonReentrant returns (address) {
        // Instantiate the contract
        Web3ERC721V1 sc = new Web3ERC721V1(_name, _symbol, _flags);
        sc.transferOwnership(_msgSender());
        sc.setContractOperator(address(this), true);
        sc.setContractOperator(_marketplace, true);
        sc.setDefaultRoyalty(_msgSender(), _defaultFee);

        emit CollectionCreated(
            address(sc),
            _msgSender(),
            _name,
            _symbol,
            _flags,
            _uuid
        );

        // Configure Latch if latcheable
        if (sc.isLatchable()) {
            sc.setLatchProxy(_latch);
        }

        // Batch mint the initial nfts for the caller
        require(_metadata.length == _prices.length, "invalid input");
        require(_metadata.length == _fees.length, "invalid input");
        require(_metadata.length == _uuids.length, "invalid input");
        address[] memory recipients = new address[](_metadata.length);
        for (uint256 i = 0; i < _metadata.length; ++i) {
            recipients[i] = _msgSender();
        }
        uint256 firstToken = sc.safeMintBatch(
            recipients,
            _metadata,
            _fees,
            _uuids
        );

        // Create sales in marketplace
        for (uint256 i = 0; i < _metadata.length; ++i) {
            IWeb3BasicNftMarketplace(_marketplace).createSaleDelegate(
                address(sc),
                firstToken + i,
                1,
                _prices[i],
                0,
                0,
                _msgSender()
            );
        }
        return address(sc);
    }

    /// @notice mints and puts on sale a set of newly created nfts.
    /// @param _collection address of the collection
    /// @param _metadata ipfs metadata of the nfts
    /// @param _prices prices of the nfts
    /// @param _fees fees of the nfts
    /// @param _uuids uuids of the nfts
    function mintAndSetOnSale(
        address _collection,
        string[] memory _metadata,
        uint256[] memory _prices,
        uint96[] memory _fees,
        uint256[] memory _uuids
    ) public nonReentrant {
        _checkCallerIsOwner(Web3ERC721V1(_collection).owner());
        require(_metadata.length == _prices.length, "invalid input");
        require(_metadata.length == _fees.length, "invalid input");
        require(_metadata.length == _uuids.length, "invalid input");

        address[] memory recipients = new address[](_metadata.length);
        for (uint256 i = 0; i < _metadata.length; ++i) {
            recipients[i] = _msgSender();
        }

        uint256 firstToken = Web3ERC721V1(_collection).safeMintBatch(
            recipients,
            _metadata,
            _fees,
            _uuids
        );

        // Create sales in marketplace
        for (uint256 i = 0; i < _metadata.length; ++i) {
            IWeb3BasicNftMarketplace(_marketplace).createSaleDelegate(
                address(_collection),
                firstToken + i,
                1,
                _prices[i],
                0,
                0,
                _msgSender()
            );
        }
    }

    /// @notice mints a set of newly created nfts to specific recipients
    /// @param _collection address of the collection
    /// @param _recipients recipients of the nfts
    /// @param _metadata ipfs metadata of the nfts
    /// @param _fees fees of the nfts
    /// @param _uuids uuids of the nfts
    function airdrop(
        address _collection,
        address[] memory _recipients,
        string[] memory _metadata,
        uint96[] memory _fees,
        uint256[] memory _uuids
    ) public nonReentrant {
        _checkCallerIsOwner(Web3ERC721V1(_collection).owner());
        require(_recipients.length == _metadata.length, "invalid input");
        require(_recipients.length == _fees.length, "invalid input");
        require(_recipients.length == _uuids.length, "invalid input");

        // Mint the nfts for the specified recipients
        Web3ERC721V1(_collection).safeMintBatch(
            _recipients,
            _metadata,
            _fees,
            _uuids
        );
    }

    /// @notice updates the price in the market as well as the fee in the collection for a minted token
    /// @param _collection address of the collection
    /// @param _tokenId id of the token
    /// @param _price new price of the token
    /// @param _fee new fee of the token
    function updatePriceAndToken(
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        uint96 _fee,
        string memory _metadata
    ) public nonReentrant {
        Web3ERC721V1 erc721 = Web3ERC721V1(_collection);
        IWeb3BasicNftMarketplace market = IWeb3BasicNftMarketplace(
            _marketplace
        );

        _checkCallerIsOwner(Web3ERC721V1(_collection).owner());
        erc721.setTokenRoyalty(_tokenId, _fee);

        if (market.sales(_collection, _tokenId, _msgSender()).amount > 0) {
            market.updateSaleDelegate(
                _collection,
                _tokenId,
                1,
                _price,
                _msgSender()
            );
        }

        if (erc721.owner() == erc721.ownerOf(_tokenId)) {
            erc721.setTokenUri(_tokenId, _metadata);
        }
    }

    /// @notice returns current marketplace address
    function marketplaceAddress() public view returns (address) {
        return _marketplace;
    }

    /// @notice sets a new marketplace address
    /// @param _newMarketplace new marketplace address
    function setMarketplaceAddress(address _newMarketplace) public onlyOwner {
        _marketplace = _newMarketplace;
        emit MarketplaceUpdated(_newMarketplace);
    }

    /// @notice returns current latch address
    function latchAddress() public view returns (address) {
        return _latch;
    }

    /// @notice sets a new latch address
    /// @param _newLatch new latch address
    function setLatchAddress(address _newLatch) public onlyOwner {
        _latch = _newLatch;
        emit LatchProxyUpdated(_newLatch);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _checkCallerIsOwner(address owner) internal view {
        require(_msgSender() == owner, "caller is not the owner");
    }
}
