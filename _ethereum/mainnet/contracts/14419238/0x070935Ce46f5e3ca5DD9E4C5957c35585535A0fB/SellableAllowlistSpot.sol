// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./IERC721.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Initializable.sol";
import "./Settings.sol";

contract SellableAllowlistSpot is
    IERC721Receiver,
    ReentrancyGuard,
    Pausable,
    Initializable
    {
    /// ==================================
    /// ==== VAULT INFORMATION ======
    /// ==================================

    /// @notice protocol-wide settings
    address public immutable settings;

    /// @notice the creator & admin of the vault, entitled to fees
    address public vaultOwner;

    /// @notice fee charged per transaction (not per NFT)
    uint256 public fee;

    /// @notice if there are 0 reservedBuyers, anyone can mint
    /// otherwise only addresses in `isReserved` can mint
    mapping (address => bool) public isReserved;
    uint256 public reservedBuyerCount;

    /// @notice NFTs owed to buyers
    /// @dev claiming NFTs happens in a second tx
    ///      token ->            borrower -> number of NFTs
    mapping (address => mapping (address => uint256)) public claimable;
    
    /// @notice overall NFTs owed to buyers by the vault
    /// required so that vault owner can claim eg airdrops
    /// without stealing them from buyers.
    mapping (address => uint256) public totalClaimable;

    /// ==================================
    /// ==== EVENTS ======
    /// ==================================
    
    /// @notice Emitted when `minter` pays `fee` to mint `tokenIDs` from `nft`
    event FlashmintedSafe(address indexed minter, address indexed nft, uint256[] tokenIDs, uint256 fee);

    /// @notice Emitted when `minter` mints `amount` of NFTs (minted)
    event Flashminted(address indexed minter, address indexed minted, uint256 amount, uint256 fee);

    /// @notice Emitted when `minter` claims NFTs they minted
    event ClaimedMint(address indexed claimant, address indexed minted, uint256[] tokenIds);

    /// @notice emitted when cost-per-tx is updated
    event FeeUpdated(uint256 fee);

    /// @notice emitted when user claims their balance
    event Cash(address depositor, uint256 depositorAmt, uint256 protocolAmt);

    /// @notice emitted when the vault is reserved for a buyer, 0x0 means anyone can use the vault
    event Reserved(address indexed buyer, bool indexed isReserved, uint256 reservedCount);

    /// @notice emitted to be able track what mint it's for
    event ForMint(string projectName);

    /// ==================================
    /// ==== MODIFIERS  ======
    /// ==================================
    modifier onlyVaultOwner {
        require(msg.sender == vaultOwner, "not owner");
        _;
    }

    modifier noMeanCalldata(bytes calldata _mintData) {
        bytes4 APPROVE = bytes4(0x095ea7b3);
        bytes4 APPROVE_FOR_ALL = bytes4(0xa22cb465);
        bytes4 sig = bytes4(_mintData[:4]);
        require(
            sig != APPROVE && sig != APPROVE_FOR_ALL,
            "no mean sigs"
        );
        _;
    }

    /// ---------------------------
    /// === LIFECYCLE/ADMIN FUNCTIONS ===
    /// ---------------------------
    constructor(address _settings) {
        settings = _settings;
    } 

    function initializeVault(address _owner, uint256 _fee) external initializer {
        vaultOwner = _owner;
        fee = _fee;
    }

    /// @notice vault owner can stop usage at any time
    function pause(bool _shouldPause) external onlyVaultOwner {
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @notice update fee charged to use vault
    function updateFee(uint256 _fee) external onlyVaultOwner {
        fee = _fee;
        emit FeeUpdated(fee);
    }

    /// @notice update the reserved buyer
    function updateReservedBuyer(address _buyer, bool _isReserved) external onlyVaultOwner {
        require(isReserved[_buyer] != _isReserved, "already set");

        if (_isReserved) {
            ++reservedBuyerCount;
        } else {
            --reservedBuyerCount;
        }

        isReserved[_buyer] = _isReserved;
        emit Reserved(_buyer, _isReserved, reservedBuyerCount);
    }

    /// @notice register a project this is WL'd for
    function registerAddressForMint(string calldata _projectName) external onlyVaultOwner {
        emit ForMint(_projectName);
    }

    /// ---------------------------
    /// === EXTERNAL FUNCTIONS ===
    /// ---------------------------

    /// @notice allows anyone to forward fees out to vault owner
    function withdrawFees() external nonReentrant {
        uint256 amount = address(this).balance;
        uint256 protocolFee = amount * Settings(settings).protocolFeeBips() / 10000;
        address protocol = Settings(settings).protocolFeeReceiver();

        bool sent;
        // if there is a protocol fee, pay it
        if (protocolFee > 0 && protocol != address(0)) {
            (sent, ) = payable(protocol).call{value: protocolFee}("");
            require(sent, "protocol fee fail");
        }
        // pay the owner
        (sent, ) = payable(vaultOwner).call{value: amount - protocolFee}("");
        require(sent, "owner pay fail");

        emit Cash(vaultOwner, amount - protocolFee, protocolFee);
    }

    /// MINT METHOD 1 of 2: If the NFT mints with `mint` instead 
    /// of `safeMint`, two transactions are required
    /// One to mint, and another to claim once the tokenID is known (from logs)
    /// Without safeMint, you don't know which tokenID you got

    /// @notice mint an NFT that doesn't use `safeMint()`
    /// without knowing the tokenId, a further call is required to claim
    /// @notice this function is unsafe for buyers if _nft is sketchy
    function mint(
        address _nft,
        bytes calldata _mintData
    ) external payable 
        noMeanCalldata(_mintData)
        whenNotPaused
        nonReentrant
    {
        require(_nft != vaultOwner, "cant call owner");
        require(_nft != address(this), "cant call self");
        require(reservedBuyerCount == 0 || isReserved[msg.sender], "reserved");
        // check our balance at start so we know if we got anything
        uint256 balanceBefore = IERC721(_nft).balanceOf(address(this));

        // mint the NFTs
        (bool success, ) = _nft.call{value: msg.value - fee}(_mintData);
        require(success, "failed to mint");

        // ensure we got something
        uint256 gained = IERC721(_nft).balanceOf(address(this)) - balanceBefore;
        require(gained > 0, "didnt mint");

        // set aside the right number of NFTs for the buyer
        claimable[_nft][msg.sender] += gained;
        totalClaimable[_nft] += gained;

        emit Flashminted(msg.sender, _nft, gained, fee);
    }

    /// @notice claim an NFT minted with `mint()`
    /// @notice this function works even if vault is paused
    function claimMintedNFT(address _nft, uint256[] calldata _newTokenIds) external nonReentrant {
        require(_nft != vaultOwner, "cant call owner");

        uint256 len = _newTokenIds.length;
        
        // throws if msg.sender doesnt have enough
        claimable[_nft][msg.sender] -= len;
        totalClaimable[_nft] -= len;

        for (uint256 i = 0; i < len; ++i) {
            // throws if we don't own `_newTokenIds[i]`
            IERC721(_nft).safeTransferFrom(
                address(this),
                msg.sender,
                _newTokenIds[i]
            );
        }
        emit ClaimedMint(msg.sender, _nft, _newTokenIds);
    }

    /// MINT METHOD 2 of 2: With `safeMint()`
    /// If the NFT uses `safeMint()`, then we get a callback
    /// that includes the tokenID so we transfer it
    /// right away.


    /// private variables to manage state between
    /// the safeMint fn call & the 721Received callback

    // list of all received tokenIDs...
    uint256[] private _safeMintReceivedNFTs;
    
    // ...from the address we're trying to mint from
    address private _nftToMint;

    function safeMint(
        address _nft,
        bytes calldata _mintData
    ) external payable
        nonReentrant
        noMeanCalldata(_mintData)
        whenNotPaused
    {
        require(_nft != vaultOwner, "cant call owner");
        require(_nft != address(this), "cant call self");
        require(reservedBuyerCount == 0 || isReserved[msg.sender], "reserved");

        // clear private variables
        _safeMintReceivedNFTs = new uint256[](0);
        _nftToMint = _nft;

        // mint the NFTs, which will call `onERC721Received`
        (bool success, ) = _nft.call{value: msg.value - fee}(_mintData);
        require(success, "failed to mint");

        uint256 gained = _safeMintReceivedNFTs.length;
        require(gained > 0, "didnt mint");

        for (uint256 i; i < gained; ++i) {
            // throws if we don't own `_newTokenIds[i]`
            IERC721(_nft).safeTransferFrom(
                address(this),
                msg.sender,
                _safeMintReceivedNFTs[i]
            );
        }

        emit FlashmintedSafe(msg.sender, _nft, _safeMintReceivedNFTs, fee);

        // delete private vars
        delete _safeMintReceivedNFTs;
        delete _nftToMint;
    }
    
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        if (msg.sender == _nftToMint){
            _safeMintReceivedNFTs.push(tokenId);
        }
        return this.onERC721Received.selector;
    }


    /// ---------------------------
    /// === RESCUE AIRDROPS IF ANY  ===
    /// ---------------------------

    function rescueCoin(address _coin) external 
        onlyVaultOwner
    {
        uint256 balance = IERC20(_coin).balanceOf(address(this));
        IERC20(_coin).transfer(msg.sender, balance);
    }

    function rescueNFT(address _token, uint256 _tokenId) external
        onlyVaultOwner
    {
        require(
            // totalClaimable[_token] must be reserved
            // for buyers to claim
            IERC721(_token).balanceOf(address(this)) >
            totalClaimable[_token],
            "reserved"
        );

        IERC721(_token).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }

    receive() external payable{}
}