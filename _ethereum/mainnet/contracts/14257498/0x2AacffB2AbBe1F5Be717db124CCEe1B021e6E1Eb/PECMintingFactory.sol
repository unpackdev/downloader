// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./PrimeEternalChampion.sol";

/**
 * @title The minting factory for Prime Eternal Champion NFTs
 * @notice This contract manages the minting of Prime Eternals to a buyer's address in two phases:
 * - A presale at a fixed price limited to a pre-determined list of addresses
 * - A public sale in a Dutch auction where the price declines over time from a fixed start price to a fixed end price.
 * @dev This contract should be given the MINTER_ROLE in the PrimeEternalChampion contract.
 * limits on the total number of Prime Eternals resides in the ERC721.
 */
contract PECMintingFactory is Pausable, AccessControl {
    event PrimeEternalsMinted(
        address to,
        uint256 number,
        uint256 extendedPrice,
        uint256 supply
    );
    event PresaleParametersSet(
        uint256 start,
        uint256 duration,
        bytes32 presaleMerkleRoot
    );
    event PublicSaleParametersSet(uint256 start, uint256 duration);

    error InsufficientFunds(
        uint256 units,
        uint256 unitPrice,
        uint256 valueOffered
    );

    // The PrimeEternalChampion ERC721 contract
    address public immutable nftAddress;

    // The account to receive the sales revenue
    address payable public immutable revenueReceiver;

    struct TimeSpan {
        uint256 start; // time of sale start in seconds since the epoch
        uint256 duration; // duration of sale in seconds
    }

    // Pre-sale parameters
    TimeSpan public presaleSpan;
    bytes32 public presaleRoot;

    uint256 public constant MAX_PRESALES_FOR_ADDRESS = 1; // maximum mintable in presale by an address
    uint256 public constant PRESALE_PRICE = 0.3 ether;

    mapping(address => uint256) public presalesForAddress; // number minted during presale to an address

    // Public sale parameters
    TimeSpan public publicSaleSpan;

    uint256 public constant MAX_PUBLIC_SALES_PER_TRANSACTION = 5; // maximum mintable in a single transaction
    uint256 public constant PUBLIC_SALE_START_PRICE = 1.0 ether;
    uint256 public constant PUBLIC_SALE_END_PRICE = 0.4 ether;
    uint256 public constant PUBLIC_SALE_PRICE_DECREASE_PER_STEP = 0.01 ether; // amount to decrease the price per step
    uint256 public constant PUBLIC_SALE_TIME_INTERVALS =
        (PUBLIC_SALE_START_PRICE - PUBLIC_SALE_END_PRICE) /
            PUBLIC_SALE_PRICE_DECREASE_PER_STEP;

    // Roles
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    bytes32 public constant SALE_ADMIN_ROLE = keccak256("SALE_ADMIN_ROLE");

    /**
     * @param _revenueReceiver address authorized to receive minting proceeds.
     *      This MUST NOT be set to a contract address that could call this contract's minting functions
     *      as this would lead re-entrancy in the _doMint() function.
     * @param _nftAddress address of the ERC721 contract
     */
    constructor(address payable _revenueReceiver, address _nftAddress) {
        require(_nftAddress != address(0), "_nftAddress is zero address");
        require(
            _revenueReceiver != address(0),
            "_revenueReceiver is zero address"
        );
        nftAddress = _nftAddress;
        revenueReceiver = _revenueReceiver;
        _setupRole(DEPLOYER_ROLE, msg.sender);
        _setupRole(SALE_ADMIN_ROLE, msg.sender);

        /**
         * @dev set deployer role as administrator of the sale admin role.
         * i.e. a member of DEPLOYER_ROLE can grant/revoke the SALE_ADMIN_ROLE to addresses
         */
        _setRoleAdmin(SALE_ADMIN_ROLE, DEPLOYER_ROLE);

        assert(PUBLIC_SALE_START_PRICE >= PUBLIC_SALE_END_PRICE);
    }

    /////////////////////////////////////////////////////////////////////////////
    // Sale Administration
    /////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Disables minting for any sales (scheduled or in progress)
     * @dev Does not extend any sale duration to compensate for the time paused
     */
    function pause() external onlyRole(SALE_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Disables minting for any sales (scheduled or in progress)
     * @dev Does not extend any sale duration to compensate for the time paused
     */
    function unpause() external onlyRole(SALE_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Set the parameters managing the presale.
     * @param _saleSpan the time span of the presale
     * @param _presaleMerkleRoot the root of the Merkle tree for the presale list
     */
    function setPresaleParameters(
        TimeSpan calldata _saleSpan,
        bytes32 _presaleMerkleRoot
    ) external onlyRole(SALE_ADMIN_ROLE) {
        presaleSpan = _saleSpan;
        presaleRoot = _presaleMerkleRoot;
        emit PresaleParametersSet(
            _saleSpan.start,
            _saleSpan.duration,
            _presaleMerkleRoot
        );
    }

    /**
     * @dev Set the parameters managing the public sale.
     */
    function setPublicSaleParameters(TimeSpan calldata saleSpan)
        external
        onlyRole(SALE_ADMIN_ROLE)
    {
        publicSaleSpan = saleSpan;
        emit PublicSaleParametersSet(saleSpan.start, saleSpan.duration);
    }

    /////////////////////////////////////////////////////////////////////////////
    // Presale
    /////////////////////////////////////////////////////////////////////////////

    function _presaleInitialized() internal view returns (bool) {
        return !(presaleSpan.start == 0 && presaleSpan.duration == 0);
    }

    function presaleActive() public view returns (bool) {
        if (!_presaleInitialized()) return false;
        uint256 _now = block.timestamp;
        return
            presaleSpan.start < _now &&
            _now < (presaleSpan.start + presaleSpan.duration);
    }

    modifier whenPresaleActive() {
        require(presaleActive(), "presale must be active");
        _;
    }

    function _leaf(address mintTo) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(mintTo));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, presaleRoot, leaf);
    }

    function isInPresale(address _address, bytes32[] calldata _proof)
        external
        view
        returns (bool)
    {
        return _verify(_leaf(_address), _proof);
    }

    function presaleMint(uint256 numToMint, bytes32[] calldata proof)
        public
        payable
        whenPresaleActive
    {
        require(_verify(_leaf(msg.sender), proof), "invalid merkle proof");
        if (msg.value < PRESALE_PRICE * numToMint)
            revert InsufficientFunds(numToMint, PRESALE_PRICE, msg.value);

        presalesForAddress[msg.sender] += numToMint;
        require(
            presalesForAddress[msg.sender] <= MAX_PRESALES_FOR_ADDRESS,
            "exceeds limit on presale for this address"
        );

        _doMint(msg.sender, numToMint);
    }

    /////////////////////////////////////////////////////////////////////////////
    // Public Sale
    /////////////////////////////////////////////////////////////////////////////

    function _publicSaleInitialized() internal view returns (bool) {
        return !(publicSaleSpan.start == 0 && publicSaleSpan.duration == 0);
    }

    function publicSaleActive() public view returns (bool) {
        if (!_publicSaleInitialized()) return false;
        uint256 _now = block.timestamp;
        return
            publicSaleSpan.start < _now &&
            _now < (publicSaleSpan.start + publicSaleSpan.duration);
    }

    modifier whenPublicSaleInitialized() {
        require(_publicSaleInitialized(), "public sale not scheduled");
        _;
    }

    modifier whenPublicSaleActive() {
        require(publicSaleActive(), "public sale must be active");
        _;
    }

    function currentPublicSalePrice() public view returns (uint256) {
        return publicSalePriceAt(block.timestamp);
    }

    /**
     * Compute the public sale price at a given time.
     * @dev The staring price must be the same or higher than the ending price. I.e. the public sale is a Dutch Auction.
     * @dev The price declines in equal (except the last) discrete price decreases.
     * There are N price levels over the course of the sale, and the duration of the sale
     * is divided into equal time steps. The price for the first step is the start price, and the price for the last
     * step is the end price. So there are likewise N time intervals but the price decreases only N-1 times.
     *
     * @param _time the time in epoch seconds
     */
    function publicSalePriceAt(uint256 _time)
        public
        view
        whenPublicSaleInitialized
        returns (uint256)
    {
        // assuming: assert(PUBLIC_SALE_START_PRICE >= PUBLIC_SALE_END_PRICE);
        if (_time <= publicSaleSpan.start) {
            return PUBLIC_SALE_START_PRICE;
        }
        if (publicSaleSpan.start + publicSaleSpan.duration <= _time) {
            return PUBLIC_SALE_END_PRICE;
        }

        uint256 stepSecs = publicSaleSpan.duration / PUBLIC_SALE_TIME_INTERVALS;
        uint256 currentStep = (_time - publicSaleSpan.start) / stepSecs;
        uint256 price;
        if (currentStep == 0) {
            // first step
            price = PUBLIC_SALE_START_PRICE;
        } else if (currentStep >= PUBLIC_SALE_TIME_INTERVALS - 1) {
            // last step
            price = PUBLIC_SALE_END_PRICE;
        } else {
            price =
                PUBLIC_SALE_START_PRICE -
                currentStep *
                PUBLIC_SALE_PRICE_DECREASE_PER_STEP;
        }
        require(
            PUBLIC_SALE_END_PRICE <= price && price <= PUBLIC_SALE_START_PRICE
        );
        return price;
    }

    /**
     * The public sale minting function to be called by the buyer.
     * @dev The message sender becomes the owner of the minted NFT.
     */
    function publicSaleMint(uint256 numToMint)
        external
        payable
        whenPublicSaleActive
    {
        require(
            numToMint <= MAX_PUBLIC_SALES_PER_TRANSACTION,
            "exceeds maximum per transaction"
        );
        uint256 currentPrice = currentPublicSalePrice();
        if (msg.value < currentPrice * numToMint)
            revert InsufficientFunds(numToMint, currentPrice, msg.value);
        _doMint(msg.sender, numToMint);
    }

    /////////////////////////////////////////////////////////////////////////////
    // Internal functions
    /////////////////////////////////////////////////////////////////////////////

    function _doMint(address to, uint256 numToMint) private whenNotPaused {
        // The revenueReceiver is stipulated to not be a contract that calls this
        // contract's minting functions as that would lead to this function being called re-entrantly.
        Address.sendValue(revenueReceiver, msg.value);
        PrimeEternalChampion pec = PrimeEternalChampion(nftAddress);
        uint256 supply = pec.totalSupply();
        pec.safeMint(to, numToMint);
        emit PrimeEternalsMinted(to, numToMint, msg.value, supply);
    }

    function selfDestruct() external onlyRole(DEPLOYER_ROLE) {
        selfdestruct(revenueReceiver);
    }
}
