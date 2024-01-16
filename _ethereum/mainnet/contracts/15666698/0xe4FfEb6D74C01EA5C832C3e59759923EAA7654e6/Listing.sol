// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BeaconProxy.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./SafeERC20Upgradeable.sol";

import "./DecimalConvert.sol";
import "./IListing.sol";
import "./IRegistry.sol";
import "./IIRO.sol";
import "./IBuyout.sol";

/// @notice This contract represents a single property listing that initially can undergo fractionalization (IRO). After the whole IRO process completes, this contract allows buyouts to start.
contract Listing is
    IListing,
    Initializable,
    AccessControlUpgradeable,
    IERC721Receiver
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using DecimalConvert for uint256;

    /// Emitted for each off-chain(e.g. IPFS) metadata/media update
    event NewMedia(Status status, uint256 network, bytes32 hash);

    /// Emitted for _some_ status changes
    /// @notice `status()` should be checked for up-to-date status
    event Update(Status status);

    /// Escrow address has been set
    event EscrowSet(address escrow);

    /// IRO started
    /// @notice IRO details can be fetched from IRO contract
    event IROStart(address iro);

    /// NFT Registered
    event NFTRegister(address addr, uint256 id);

    IRegistry internal _registry; // contracts registry
    address public owner; // user that added this listing
    bytes32 public name; // short name (up to 32 bytes)
    bytes32 public tokenName; // listing token name (up to 32 bytes)
    bytes16 public tokenSymbol; // listing token symbol (up to 16 bytes)
    IERC20Metadata public fundingToken; // ERC20 token used for funding
    uint8 internal _fundingTokenDecimals; // ERC20 funding token decimals()
    uint256 public softCap; // minimum goal in fundingTokens
    uint256 public hardCap; // maximum goal in fundingTokens
    uint256 public fundingDurationSeconds; // Start to end of IRO in seconds
    uint256 public expiryDurationSeconds; // Start to fail-safe funds distribution in seconds
    IERC721Metadata public nftAddr; // NFT representing the property
    uint256 public nftID; // (i.e. holder represents creditor)
    IERC20 public listingToken; // ERC20 token used for fractionalization

    address internal _escrow; // on IRO success, only this address can claim funds
    IIRO public iro;

    IBuyout[] public buyouts;

    bytes32 public constant DIRECTOR_ROLE = keccak256("DIRECTOR_ROLE");
    bytes32 public constant DUE_DILIGENCE_ROLE =
        keccak256("DUE_DILIGENCE_ROLE");
    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE"); // Role is and sets escrow wallet address
    bytes32 public constant ESCROW_ADMIN_ROLE = keccak256("ESCROW_ADMIN_ROLE"); // Grants ESCROW_ROLE to escrow address
    uint256 public constant FEE_BASIS_POINTS = 200;

    uint256 private constant FEE_BASIS_POINTS_PRECISION = 10000;
    uint8 private constant LISTING_TOKEN_DECIMALS = 18;

    modifier onlyStatus(IListing.Status s) {
        require(status() == s, "WRONG_LISTING_STAGE");
        _;
    }

    modifier onlyIROStatus(IIRO.Status s) {
        require(iro.status() == s, "WRONG_IRO_STAGE");
        _;
    }

    function initialize(
        IRegistry registry,
        address _owner,
        bytes32 _name,
        bytes32 _tokenName,
        bytes32 _tokenSymbol,
        address _fundingToken,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _fundingDurationSeconds,
        uint256 _expiryDurationSeconds
    ) public {
        require(
            _fundingDurationSeconds < _expiryDurationSeconds,
            "INVALID_DURATIONS"
        );
        require(_softCap <= _hardCap, "INVALID_CAPS");

        __AccessControl_init();

        _registry = registry;
        owner = _owner;
        name = _name;
        tokenName = bytes16(_tokenName);
        tokenSymbol = bytes8(_tokenSymbol);
        fundingToken = IERC20Metadata(_fundingToken);
        _fundingTokenDecimals = fundingToken.decimals(); // fail if extension missing
        softCap = _softCap;
        hardCap = _hardCap;
        fundingDurationSeconds = _fundingDurationSeconds;
        expiryDurationSeconds = _expiryDurationSeconds;

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setRoleAdmin(ESCROW_ROLE, ESCROW_ADMIN_ROLE);
    }

    /// @notice Current status of listing. Note that in the `BUYOUT` state, the Buyout contract should be checked if an initial offer has been made
    function status() public view returns (Status s) {
        if (address(iro) == address(0)) {
            s = Status.NEW;
        } else if (iro.status() != IIRO.Status.DISTRIBUTION) {
            s = Status.IRO;
        } else if (buyouts.length == 0) {
            s = Status.LIVE;
        } else {
            IBuyout.Status buyoutStatus = buyouts[buyouts.length - 1].status();

            if (
                buyoutStatus == IBuyout.Status.NEW ||
                buyoutStatus == IBuyout.Status.OPEN
            ) {
                s = Status.BUYOUT;
            } else if (buyoutStatus == IBuyout.Status.SUCCESS) {
                s = Status.REDEEMED;
            } else {
                s = Status.LIVE;
            }
        }
    }

    /// @notice Publish a hash corresponding to an off-chain document. Currently only IPFS is defined as `network` = 1. By convention, this document is a JSON file that may link to other IPFS media, e.g. images
    /// @param network Network where document is hosted (currently only IPFS)
    /// @param hash Hash identifying document on network
    /// @custom:role-due-diligence
    function publishMedia(uint256 network, bytes32 hash)
        public
        onlyRole(DUE_DILIGENCE_ROLE)
    {
        emit NewMedia(status(), network, hash);
    }

    /// @notice Sets the Escrow address by interacting with the contract to prove liveness. ESCROW_ROLE required (ESCROW_ADMIN_ROLE can grant this role)
    /// @custom:role-escrow
    function setEscrowAddress()
        public
        onlyRole(ESCROW_ROLE)
        onlyStatus(Status.NEW)
    {
        _escrow = msg.sender;

        emit EscrowSet(msg.sender);
    }

    /// @notice Start IRO, Escrow address must be provided as confirmation the address correct.
    /// @param escrow Only this address can withdraw successful IRO funds
    /// @custom:role-due-diligence
    function startIRO(address escrow)
        public
        onlyRole(DUE_DILIGENCE_ROLE)
        onlyStatus(Status.NEW)
    {
        require(escrow != address(0) && escrow == _escrow, "ESCROW_INVALID");

        BeaconProxy proxy = new BeaconProxy(
            address(_registry.iroBeacon()),
            abi.encodeWithSignature(
                "initialize(address,uint256,uint256,uint256,uint256,address)",
                fundingToken,
                softCap,
                hardCap,
                fundingDurationSeconds,
                expiryDurationSeconds,
                escrow
            )
        );
        iro = IIRO(address(proxy));

        emit Update(Status.IRO);
    }

    /// @notice Register the NFT that represents the property.
    /// @param addr NFT contract address
    /// @param id NFT ID
    /// @custom:role-director
    function registerNFT(IERC721Metadata addr, uint256 id)
        public
        onlyRole(DIRECTOR_ROLE)
        onlyIROStatus(IIRO.Status.AWAITING_TOKENS)
    {
        nftAddr = addr;
        nftID = id;

        emit NFTRegister(address(addr), id);
    }

    /// Start distribution phase of IRO
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) public override returns (bytes4 selector) {
        require(address(nftAddr) == msg.sender, "BAD_NFT_ADDR");
        require(nftID == tokenId, "BAD_NFT_ID");
        require(address(this) == nftAddr.ownerOf(nftID), "BAD_NFT_OWNER");

        _fractionalize();
        iro.enableDistribution(
            IERC20MetadataUpgradeable(address(listingToken))
        );

        selector = this.onERC721Received.selector;

        emit Update(Status.LIVE);
    }

    /// @notice Start a buyout, proposer must then interact with the Buyout contract
    function startBuyout() public onlyStatus(Status.LIVE) {
        BeaconProxy proxy = new BeaconProxy(
            address(_registry.buyoutBeacon()),
            abi.encodeWithSignature(
                "initialize(address,address)",
                listingToken,
                fundingToken
            )
        );
        IBuyout buyout = IBuyout(address(proxy));
        buyouts.push(buyout);

        emit Update(Status.BUYOUT);
    }

    /// @notice Claim underlying NFT upon a successful buyout
    function claimNFT() public onlyStatus(Status.REDEEMED) {
        require(
            msg.sender == buyouts[buyouts.length - 1].offerer(),
            "NOT_OFFERER"
        );
        nftAddr.safeTransferFrom(address(this), msg.sender, nftID);

        emit Update(Status.REDEEMED);
    }

    function _bytes32ToString(bytes32 _bytes32)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function _fractionalize() internal {
        require(address(listingToken) == address(0), "ALREADY_FRACTIONALIZED");

        uint256 supplyLessFee = hardCap.convertDecimal(
            _fundingTokenDecimals,
            LISTING_TOKEN_DECIMALS
        );

        // CitaDAO's listing token fees (1.96% of total)
        uint256 fee = (supplyLessFee * FEE_BASIS_POINTS) /
            FEE_BASIS_POINTS_PRECISION;

        BeaconProxy proxy = new BeaconProxy(
            address(_registry.brickTokenBeacon()),
            abi.encodeWithSignature(
                "initialize(string,string,uint8,uint256)",
                _bytes32ToString(tokenName),
                _bytes32ToString(tokenSymbol),
                LISTING_TOKEN_DECIMALS,
                supplyLessFee + fee
            )
        );
        listingToken = IERC20(address(proxy));

        require(
            listingToken.transfer(_registry.treasuryAddr(), fee),
            "LISTING_TOKEN_FEE_TRANSFER_FAIL"
        );
        require(
            listingToken.transfer(address(iro), supplyLessFee),
            "LISTING_TOKEN_IRO_TRANSFER_FAIL"
        );
    }

    function numBuyouts() public view returns (uint256) {
        return buyouts.length;
    }
}
