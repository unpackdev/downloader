// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721AUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC20Upgradeable.sol";

error PausedTransfer();
error MaxSupply();
error LockUpUnavailable();

contract GenesisKey is Initializable, ERC721AUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using ECDSAUpgradeable for bytes32;

    // 2^128 is more than enough to store unix timestamp
    struct LockupInfo {
        uint128 totalLockup; // total lockup of this GK
        uint128 currentLockup; // unlocked when currentLock is 0
    }

    /* An ECDSA signature. */
    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    address public owner;
    uint96 public publicSaleDurationSeconds; // length of public sale in seconds

    address public multiSig;
    uint96 public initialEthPrice; // initial price of genesis keys in Weth

    address public genesisKeyMerkle; // Deprecated
    uint96 public finalEthPrice; // final price of genesis keys in Weth

    address public gkTeamClaimContract;
    uint96 public publicSaleStartSecond; // second public sale starts

    address public signerAddress;
    bool public startPublicSale; // global state indicator if public sale is happening
    bool public pausedTransfer; // Deprecated
    bool public randomClaimBool; // Deprecated
    bool public lockupBoolean; // true if GK holders can lockup, false if not
    uint64 public remainingTeamAdvisorGrant; // Deprecated (0 left)

    mapping(bytes32 => bool) public cancelledOrFinalized; // Deprecated
    mapping(address => bool) public whitelistedTransfer; // Deperecated
    mapping(uint256 => LockupInfo) private _genesisKeyLockUp; // Deprecated

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public latestClaimTokenId;

    event ClaimedGenesisKey(address indexed _user, uint256 _amount, uint256 _blockNum, bool _whitelist);

    modifier onlyOwner() {
        require(msg.sender == owner, "GEN_KEY: !AUTH");
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        address _multiSig,
        uint256 _auctionSeconds,
        bool _randomClaimBool,
        string memory baseURI
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC721A_init(name, symbol, baseURI);
        __UUPSUpgradeable_init();

        startPublicSale = false;
        publicSaleDurationSeconds = uint96(_auctionSeconds);
        owner = msg.sender;
        multiSig = _multiSig;
        remainingTeamAdvisorGrant = 250; // 250 genesis keys allocated
        randomClaimBool = _randomClaimBool;
        signerAddress = 0x9EfcD5075cDfB7f58C26e3fB3F22Bb498C6E3174;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // governance functions =================================================================
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function bulkTransfer(uint256[] calldata tokenIds, address _to) external {
        for (uint256 i; i < tokenIds.length;) {
            if (_genesisKeyLockUp[tokenIds[i]].currentLockup != 0) revert PausedTransfer();
            _transfer(msg.sender, _to, tokenIds[i]);
            unchecked { i++; }
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (_genesisKeyLockUp[tokenId].currentLockup != 0) revert PausedTransfer();
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (_genesisKeyLockUp[tokenId].currentLockup != 0) revert PausedTransfer();
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        if (_genesisKeyLockUp[tokenId].currentLockup != 0) revert PausedTransfer();
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function setMultiSig(address _newMS) external onlyOwner {
        multiSig = _newMS;
    }

    function toggleLockupBoolean() external onlyOwner {
        lockupBoolean = !lockupBoolean;
    }

    function currentXP(uint256 tokenId)
        external
        view
        returns (
            bool locked,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = _genesisKeyLockUp[tokenId].currentLockup;
        if (start != 0) {
            locked = true;
            current = block.timestamp - start;
        }
        total = current + _genesisKeyLockUp[tokenId].totalLockup;
    }

    function toggleLockup(uint256 tokenId) internal {
        require(msg.sender == ownerOf(tokenId));
        uint256 start = _genesisKeyLockUp[tokenId].currentLockup;
        if (start == 0) {
            if (!lockupBoolean) revert LockUpUnavailable();
            _genesisKeyLockUp[tokenId].currentLockup = uint128(block.timestamp);
        } else {
            _genesisKeyLockUp[tokenId].totalLockup += uint128(block.timestamp - start);
            _genesisKeyLockUp[tokenId].currentLockup = 0;
        }
    }

    function toggleLockup(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleLockup(tokenIds[i]);
        }
    }

    function deprecateGK(uint256 _amount) external onlyOwner {
        require(_amount != 0, "!0");
        uint256 i = latestClaimTokenId + 1; // start at 1
        latestClaimTokenId += _amount;
        while (i <= latestClaimTokenId) {
            _adminTransfer(address(this), multiSig, i);
            unchecked { i++; }
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "STE");
    }

    // helper function for transferring eth from the public auction to MS
    function transferETH() external onlyOwner {
        safeTransferETH(multiSig, address(this).balance);
    }
}
