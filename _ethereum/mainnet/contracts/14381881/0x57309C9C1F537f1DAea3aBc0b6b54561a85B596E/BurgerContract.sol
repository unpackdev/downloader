// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract Burger is ERC721Enumerable, ERC721Burnable, AccessControl, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    /* STORAGE BEGINS */

    // Pause Variables
    bool public WLPaused;
    bool public EthMintPaused;
    bool public YollarMintPaused;

    IERC20 yollar;

    uint256 public currentMinted;
    uint256 public mintableSupply;

    uint256 public ethMintPrice;
    uint256 public yollarMintPrice;

    uint256 public currMerkleIndex;
    // mapping from WL index -> merkleRoot;
    mapping(uint256 => bytes32) private merkleRoots;
    // mapping from WL index -> address -> number claimed
    mapping(uint256 => mapping(address => uint256)) private claimedMapping;

    string private _tokenURI;

    bytes32 WL_ADMIN = keccak256("WHITELIST_ADMIN");

    /* STORAGE ENDS */

    constructor(address yollarAddress) ERC721("NASA Cheeseburger Fighters", "CBF") {
        WLPaused = true;
        EthMintPaused = true;
        YollarMintPaused = true;

        yollar = IERC20(yollarAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WL_ADMIN, msg.sender);
    }

    /**
     * @dev returns the supportsInterfaceIds for `ERC721` and `AccessControl`
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {

        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /* WITHDRAWAL FUNCTIONS */

    /**
     * @dev Allows to withdraw the Ether in contract
     * @param _amount - the amount being withdrawn
     */
    function withdrawEth(uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_amount <= address(this).balance);
        payable(msg.sender).transfer(_amount);
    }

    /**
     * @dev Withdraws ERC20
     * @param _amount - the amount being withdrawn
     */
    function withdrawYollar(uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        yollar.transfer(msg.sender, _amount);
    }

    /* MERKLE AIRDROP FUNCTIONS */

    /**
     * @dev public view function to get the merkleRoot at a current merkle index
     * @param rootIndex - the index in the series of merkle trees that is being returned
     * @return the merkle root at the given `rootIndex`
     */
    function getMerkleRoot(uint256 rootIndex) public view returns (bytes32) {
        return merkleRoots[rootIndex];
    }

    /**
     * @dev Sets the next merkle Root and invalidates the previous root
     * @param merkleRoot - The new merkleRoot
     */
    function setNextMerkleRoot(bytes32 merkleRoot)
        external
        adminOrWL
    {
        if (merkleRoot == 0) {
            // TODO: double check that this works for bytes32 (95% sure it does)
            revert InvalidMerkleRoot();
        }

        // This will invalidate the previous merkle from being claimed
        currMerkleIndex += 1;
        merkleRoots[currMerkleIndex] = merkleRoot;
        WLPaused = false;
    }

    /**
     * @dev constructs the intended leaft to validate
     */
    function _leaf(address account, uint256 redeemableAmount)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, redeemableAmount));
    }

    /**
     * @dev verifies the leaf and proof against the current valid merkleIndex
     */
    function _verifyMerkle(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoots[currMerkleIndex], leaf);
    }

    /* MINTING FUNCTIONS */

    /**
     * @dev mints with merkleRoot whitelisting
     */
    function mintWithMerkle(
        uint256 redeemableAmount,
        uint256 redeemAmount,
        bytes32[] calldata proof
    ) external whenWLActive nonReentrant {
        address redeemer = msg.sender;
        if (!_verifyMerkle(_leaf(redeemer, redeemableAmount), proof)) {
            revert InvalidRedeemer();
        }

        uint256 claimedSoFar = claimedMapping[currMerkleIndex][redeemer];

        // if the claimedAmountSoFar + the amount intended to redeem is larger than amount available, throw
        // if redeem amount + current minted > total supply, throw
        if ((mintableSupply != 0 && currentMinted + redeemAmount > mintableSupply) || 
        (claimedSoFar + redeemAmount > redeemableAmount)) {
            revert NotEnoughRedeemsAvailable();
        }

        claimedMapping[currMerkleIndex][redeemer] += redeemAmount;
        for (uint256 i = 0; i < redeemAmount; i ++) {
            _mintBurger(redeemer);
        }
    }

    /**
     * @dev mints an NFT payable in Eth
     */
    function mintWithEth(uint256 redeemAmount) external payable whenEthMintActive nonReentrant {
        address to = msg.sender;
        if (msg.value != ethMintPrice * redeemAmount) {
            revert InsufficentEth();
        }

        // This short circuit check will save gas on _mintBurger
        if (mintableSupply != 0 && currentMinted + redeemAmount > mintableSupply) {
            revert SupplyUnavailable();
        }

        for (uint256 i = 0; i < redeemAmount; i ++) {
            _mintBurger(to);
        }
    }

    /**
     * @dev mints an NFT payable in Yollar - Must call approve on yollar contract before this
     */
    function mintWithYollar(uint256 redeemAmount) external payable whenYollarMintActive nonReentrant {
        address to = msg.sender;
        // if mintableSupply is set to 0, then unlimited mint
        if (mintableSupply != 0 && currentMinted + redeemAmount > mintableSupply) {
            revert SupplyUnavailable();
        }

        // This will automatically revert if it fails
        yollar.safeTransferFrom(msg.sender, address(this), yollarMintPrice * redeemAmount);

        
        for (uint256 i = 0; i < redeemAmount; i ++) {
            _mintBurger(to);
        }
    }

    /**
     * @dev internal function for minting Burger
     */
    function _mintBurger(address to) internal {
        currentMinted += 1;
        _safeMint(to, currentMinted);
    }

    /* VIEW FUNCTIONS */

    /**
     * @dev returns the tokenURI if exists
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_exists(tokenId)) {
            return _tokenURI;
        }
        return "";
    }

    /**
     * @dev returns the mintedCount of a minter against a merkleIndex
     */
    function getMintedAmounts(uint256 merkleIndex, address minter)
        public
        view
        returns (uint256)
    {
        return claimedMapping[merkleIndex][minter];
    }

    /* ADMIN FUNCTIONS */

    /**
     * @dev Override parameters
     */
    function ADMIN_OVERRIDE(
        uint256 _mintableSupply,
        address yollarAddress,
        string memory _newTokenURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_mintableSupply != 0 && _mintableSupply < currentMinted) {
            revert InvalidmintableSupplyAdmin();
        }

        yollar = IERC20(yollarAddress);
        mintableSupply = _mintableSupply;
        _tokenURI = _newTokenURI;
    }

    /**
     * @dev Override parameters
     */
    function adminOverridePrices(
        uint256 _ethMintPrice,
        uint256 _yollarMintPrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ethMintPrice = _ethMintPrice;
        yollarMintPrice = _yollarMintPrice;
    }

    /**
     * @dev toggle pause for merkle
     */
    function toggleWLPause() external adminOrWL {
        if (WLPaused) {
            emit WLActiveEvent();
        } else {
            emit WLPausedEvent();
        }
        WLPaused = !WLPaused;
    }

    /**
     * @dev toggle pause for eth mint
     */
    function toggleEthMintPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (EthMintPaused) {
            emit EthMintActiveEvent();
        } else {
            emit EthMintPausedEvent();
        }
        EthMintPaused = !EthMintPaused;
    }

    /**
     * @dev toggle pause for yollar mint
     */
    function toggleYollarMintPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (YollarMintPaused) {
            emit YollarMintActiveEvent();
        } else {
            emit YollarMintPausedEvent();
        }
        YollarMintPaused = !YollarMintPaused;
    }

    /**
     * @dev modifier for WL
     */
    modifier whenWLActive() {
        if (WLPaused) {
            revert WLPausedError();
        }
        _;
    }

    /**
     * @dev modifier for eth mint
     */
    modifier whenEthMintActive() {
        if (EthMintPaused) {
            revert EthMintPausedError();
        }
        _;
    }

    /**
     * @dev modifier for yollar mint
     */
    modifier whenYollarMintActive() {
        if (YollarMintPaused) {
            revert YollarMintPausedError();
        }
        _;
    }

    /**
     * @dev Check if there is DEFAULT_ADMIN_ROLE or WL_ADMIN role, otherwise revert
     */
    modifier adminOrWL() {
        if (!(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(WL_ADMIN, msg.sender))) {
            revert InvalidRole();
        }
        _;
    }


    error WLPausedError();
    error EthMintPausedError();
    error YollarMintPausedError();
    error SupplyUnavailable();
    error InsufficentEth();

    error InvalidMerkleRoot();
    error InvalidRedeemer();
    error NotEnoughRedeemsAvailable();

    error InvalidmintableSupplyAdmin();
    error InvalidRole();

    /* EVENTS BEGIN */
    event WLPausedEvent();
    event WLActiveEvent();
    event EthMintPausedEvent();
    event EthMintActiveEvent();
    event YollarMintPausedEvent();
    event YollarMintActiveEvent();
}
