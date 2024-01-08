// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./Initializable.sol";

import "./console.sol";

contract SlothLounge is
    Initializable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using StringsUpgradeable for uint256;

    event TokenURISet(string indexed tokenUri);
    event TokenURILocked(string indexed tokenUri);
    event DevTipExecuted();
    event SlothLoungeTreasuryReplenished(uint256 indexed amount);

    address private constant TREASURY =
        0x02f4CFd0E5af6DA87856B6E70d1B595dE45591bA;
    address private constant SLOTH = 0x43Ae70BD9d4AE85fC13d07890879ECaF84Fd6ea3;
    address private constant G = 0xd53f68c213786BB5B836B6882BbAB181f93ef062;
    address private constant S = 0xa1D8BeF9008016Fcf2F8AD1b40E0122a5b3dDC71;
    address private constant M = 0xF54b1A926319bc407eDB16ae9809C5FE47C365da;

    // Tue Nov 09 2021 9PM UTC
    uint256 public constant WHITELIST_SALE_STARTS = 1636491600;
    uint256 public constant REGULAR_SALE_STARTS = WHITELIST_SALE_STARTS + 86400;
    uint256 public constant PRICE = 40000000000000000;
    uint256 public constant MAX_SLOTH_SUPPLY = 4500;
    uint256 public constant GIVEAWAY_SUPPLY = 68 + 8 + 8 + 9;
    uint256 public constant MAX_PER_WALLET = 20;
    uint256 public constant MAX_PER_WHITELISTED = 5;
    uint256 public constant OT_DEV_TIP = 435000000000000000;
    string private constant METADATA_INFIX = "/metadata/";

    string public constant PROVENANCE =
        "62a20e450008bdf854b24eaa042bd38aae19283ebc515e004247041232dabac8";

    // -- APPEND-ONLY STORAGE --
    bytes32 private MERKLE_ROOT;
    bool private otTipDone;
    bool public tokenURILocked;
    uint256 public totalSupply;
    uint256 public giveawayMints;
    uint256 private claimedBitMap;
    mapping(address => uint256) private _mints;
    string private _baseTokenUri;

    function initialize() external initializer {
        __ERC721_init("The Sloth Lounge", "SLTH");
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        MERKLE_ROOT = hex"c0d0be35e72372222728287f02704739f7afb8ee360f60ec3adfc2431f5f2b62";
        _setTokenURI("https://api.theslothlounge.com");

        _mintN(G, 2);
        _mintN(SLOTH, 1);
        _mintN(S, 2);
        _mintN(M, 1);
    }

    function setMerkleRoot(bytes32 mRoot) external {
        _enforceOnly(owner());

        MERKLE_ROOT = mRoot;
    }

    function isWhitelistSalePeriod() external view returns (bool) {
        return _isWhitelistPeriod();
    }

    function isRegularSalePeriod() external view returns (bool) {
        return _isRegularPeriod();
    }

    function mintWhitelist(
        uint256 sloths,
        uint256 index,
        bytes32[] calldata proof
    ) external payable {
        _enforceNotPaused();
        require(_isWhitelistPeriod(), "NotInWhitelistPeriod");
        require(sloths > 0, "ZeroSlothsRequested");
        require(sloths * PRICE == msg.value, "InvalidETHAmount");
        uint256 bal = balanceOf(msg.sender);
        require(bal + sloths <= MAX_PER_WHITELISTED, "MintingExceedsQuota");

        verifyProof(index, msg.sender, proof);

        _mintN(msg.sender, sloths);

        if (bal + sloths == MAX_PER_WHITELISTED) {
            _setClaimed(index);
        }
    }

    /// @dev mint up to `sloth` tokens
    function mint(uint256 sloths) public payable {
        _enforceNotPaused();
        require(_isRegularPeriod(), "NotInRegularSalePeriod");
        require(sloths > 0, "ZeroSlothsRequested");
        require(sloths * PRICE == msg.value, "InvalidETHAmount");
        _mints[msg.sender] += sloths;
        require(_mints[msg.sender] <= MAX_PER_WALLET, "MintingExceedsQuota");

        uint256 MINTABLE = MAX_SLOTH_SUPPLY -
            totalSupply -
            (GIVEAWAY_SUPPLY - giveawayMints);
        require(sloths <= MINTABLE, "MintingExceedsMaxSupply");

        _mintN(msg.sender, sloths);
    }

    function mintOwner(address to, uint256 sloths) external {
        _enforceOnly(owner());
        require(sloths > 0, "ZeroSlothsRequested");
        require(
            giveawayMints + sloths <= GIVEAWAY_SUPPLY,
            "GiveawaySupplyExceeded"
        );

        giveawayMints += sloths;

        _mintN(to, sloths);
    }

    function withdraw() external {
        if (!otTipDone) {
            payable(M).transfer(OT_DEV_TIP);
            otTipDone = true;
            emit DevTipExecuted();
        }

        if (address(this).balance > 2) {
            payable(TREASURY).transfer(address(this).balance / 2);
            payable(SLOTH).transfer(address(this).balance);
            emit SlothLoungeTreasuryReplenished(address(this).balance / 2);
        }
    }

    function setTokenURI(string calldata newUri) external {
        _setTokenURI(newUri);
    }

    function _setTokenURI(string memory newUri) internal {
        _enforceOnly(owner());
        require(!tokenURILocked, "TokenURILocked");
        _baseTokenUri = newUri;
        emit TokenURISet(_baseTokenUri);
    }

    function lockTokenURI() public {
        _enforceOnly(owner());
        if (!tokenURILocked) {
            tokenURILocked = true;
            emit TokenURILocked(_baseTokenUri);
        }
    }

    function toggle() external {
        _enforceOnly(owner());
        if (paused()) _unpause();
        else _pause();
    }

    /**
     * @dev Returns placeholder for a minted token prior to reveal time,
     * the regular tokenURI otherise.
     *
     * @param tokenId Identity of an existing (minted) Sloth NFT.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory result)
    {
        require(_exists(tokenId), "UnknownTokenId");

        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    METADATA_INFIX,
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    //
    // BASEMENT
    //
    function _enforceOnly(address authorized) internal view {
        require(msg.sender == authorized, "UnauthorizedAccess");
    }

    function _mintN(address to, uint256 sloths) internal nonReentrant {
        for (uint256 t = 0; t < sloths; t++) {
            _safeMint(to, totalSupply + t);
        }

        totalSupply += sloths;
    }

    function _isWhitelistPeriod() internal view returns (bool) {
        return (block.timestamp >= WHITELIST_SALE_STARTS &&
            block.timestamp < REGULAR_SALE_STARTS);
    }

    function _isRegularPeriod() internal view returns (bool) {
        return block.timestamp >= REGULAR_SALE_STARTS;
    }

    function _enforceNotPaused() internal view {
        require(!paused(), "SlothLoungePaused");
    }

    function verifyProof(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) internal view {
        require(!_isClaimed(index), "AlreadyClaimed");

        bytes32 node = keccak256(
            abi.encodePacked(index, account, MAX_PER_WHITELISTED)
        );
        require(
            MerkleProofUpgradeable.verify(merkleProof, MERKLE_ROOT, node),
            "InvalidMerkleProof"
        );
    }

    function _setClaimed(uint256 index) private {
        claimedBitMap = claimedBitMap | (1 << index);
    }

    function _isClaimed(uint256 index) internal view returns (bool) {
        uint256 mask = (1 << index);
        return claimedBitMap & mask == mask;
    }
}
