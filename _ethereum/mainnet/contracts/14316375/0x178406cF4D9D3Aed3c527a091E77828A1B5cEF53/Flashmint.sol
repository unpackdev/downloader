// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./Settings.sol";

contract Flashmint is 
            ERC721, 
            IERC721Receiver, 
            ReentrancyGuard,
            IERC2981
    {
    using Strings for uint256;
    /// -------------------------
    /// === TOKEN INFORMATION ===
    /// -------------------------

    /// @notice the ERC721 token address of this vault's token
    address public token;
    
    /// @notice the erc721 token ID of this vault's token
    uint256 public id;
    
    /// -------------------------
    /// === VAULT INFORMATION ===
    /// -------------------------

    /// @notice the protocol-wide settings
    address public immutable settings; 

    /// @notice the price a lender must pay to mint with this token. in wei, ie 18 decimals (10**18 = 1)
    uint256 public fee;

    // NOT_ACTIVE when created, ACTIVE when initialized & ready for use
    // FINISHED when NFT is withdrawn by owner
    enum State { NOT_ACTIVE, ACTIVE, FINISHED } 
    State public vaultState;

    /// @notice owner may reserve certain mints for themselves
    mapping (address => bool) public reserved;

    /// @notice NFTs owed to borrowers
    /// @dev this only applies for NFTs minted without safeMint
    /// note that tokenIds aren't reserved 1:1
    ///       token ->          borrower -> number of NFTs
    mapping (address => mapping (address => uint256)) public claimable;

    /// @notice total number of NFTs owed to borrowers
    /// the rest are prob airdrops and can be claimed by vault owner
    /// token -> number of NFTs
    mapping (address => uint256) public totalClaimable;
    
    /// -------------------------
    /// === MINT INFORMATION ===
    /// -------------------------

    enum FlightStatus {
        READY,    // before call to external NFT
        INFLIGHT, // during call to external NFT
        LANDED    // once NFT is received in `onERC721Received`
    }

    struct MintRequest {
        FlightStatus flightStatus;
        address expectedNFTContractAddress;
        uint256[] newids; // @notice this is only defined if flightStatus != READY
    }
    /// @notice state variable is needed to track a mint request because 
    /// we're reliant on the ERC721Receiver callback to get id
    MintRequest private safeMintReq;

    /// -------------------------
    /// ======== EVENTS ========
    /// -------------------------

    /// @notice Emitted when `minter` borrows this NFT to mint `minted`
    event FlashmintedSafe(address indexed minter, address indexed minted, uint256[] tokenIds, uint256 fee);

    /// @notice Emitted when `minter` mints `amount` of NFTs (minted)
    event Flashminted(address indexed minter, address indexed minted, uint256 amount, uint256 fee);

    /// @notice Emitted when someone claims an NFT minted with unsafely
    event ClaimedMint(address indexed claimant, address indexed minted, uint256 tokenId);

    /// @notice Emitted when initial depositor reclaims their NFT and ends this contract.
    event Closed(address depositor);

    /// @notice Emitted when the claimer cashes out their fees
    event Cash(address depositor, uint256 amount);

    /// @notice Emitted when the cost is updated
    event FeeUpdated(uint256 amount);

    /// @notice Emitted when the owner reserves a mint for themselves
    event Reserved(address indexed nft, bool indexed reserved);

    string constant _name = unicode"⚡Flashmint Held NFT";
    string constant _symbol = unicode"⚡FLASH";

    constructor(address _settings) ERC721(_name, _symbol) {
        vaultState = State.NOT_ACTIVE;
        settings = _settings;
    }
    

    function name() public view override returns (string memory){return _name;}
    function symbol() public view override returns (string memory){return _symbol;}

    /// ---------------------------
    /// ===    MODIFIERS  ===
    /// ---------------------------

    // @dev access control for vault admin functions
    modifier onlyVaultOwner {
        require(msg.sender == ownerOf(0), "not owner");
        _;
    }

    // @dev for use with calls to external contracts
    modifier noStealing {
        _;
        require(IERC721(token).ownerOf(id) == address(this), "no stealing");
    }

    // @dev prevent malicious calls to `token` that eg approve() others
    modifier notToken(address _token) {
        require(token != _token, "can't call underlying");
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
    /// === LIFECYCLE FUNCTIONS ===
    /// ---------------------------

    function initializeWithNFT(address _token, uint256 _id, address _depositor, uint256 _fee) external nonReentrant {
        require(vaultState == State.NOT_ACTIVE, "already active");
        require(_token != _depositor, "self deposit");
        token = _token;
        id = _id;
        vaultState = State.ACTIVE;
        fee = _fee;
        _safeMint(_depositor, 0);
        emit FeeUpdated(_fee);
    }

    /// @notice allow the depositor to reclaim their NFT, ending this flashmint
    function withdrawNFT() external nonReentrant {
        vaultState = State.FINISHED;

        // pay out remaining balance
        _withdrawEth();

        address recipient = ownerOf(0);
        // @note requires that msgSender controls id 0 of this vault
        transferFrom(recipient, address(this), 0);
        // Burn LP token
        _burn(0);

        // Distribute underlying token
        IERC721(token).safeTransferFrom(address(this), recipient, id);

        emit Closed(msg.sender);
    }

    /// @notice allows anyone to forward payments to the depositor
    function withdrawEth() external nonReentrant {
        require(vaultState != State.NOT_ACTIVE, "State is NOT_ACTIVE");
        _withdrawEth();
    }
    
    function _withdrawEth() internal {
        address recipient = ownerOf(0);
        uint256 amount = address(this).balance;

        uint256 protocolFee = amount * Settings(settings).protocolFeeBips() / 10000;
        address protocol = Settings(settings).protocolFeeReceiver();

        bool sent;
        if (protocolFee > 0 && protocol != address(0)) {
            (sent, ) = payable(protocol).call{value: protocolFee}("");
            require(sent, "_withdrawEth: protocol payment failed");
        }

        (sent, ) = payable(recipient).call{value: amount - protocolFee}("");
        require(sent, "_withdrawEth: payment failed");

        emit Cash(recipient, amount);
    }

    /// ---------------------------
    /// === OWNER MGMT UTILITIES ===
    /// ---------------------------
    /// @notice allow the depositor to update their fee
    function updateFee(uint256 _fee) external 
        onlyVaultOwner 
        nonReentrant 
    {
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    /// @notice allow the depositor to reserve a mint for themselves
    function reserve(address _token, bool _reserved) external 
        onlyVaultOwner
    {
        reserved[_token] = _reserved;
        emit Reserved(_token, _reserved);
    }

    /// @notice let vault owner rescue eg airdrops
    function rescueCoin(address _coin) external 
        onlyVaultOwner
        notToken(_coin)
        noStealing
    {
        uint256 balance = IERC20(_coin).balanceOf(address(this));
        IERC20(_coin).transfer(msg.sender, balance);
    }
    /// @notice let vault owner rescue eg airdrops
    function rescueNFT(address _token, uint256 _tokenId) external 
        nonReentrant
        onlyVaultOwner
        notToken(_token)
        noStealing
    {
        // ensure token doesn't belong to a customer
        require(
            IERC721(_token).balanceOf(address(this)) >
            totalClaimable[_token],
            "spoken for"
        );
        IERC721(_token).transferFrom(address(this), msg.sender, _tokenId);
    }

    /// ---------------------------
    /// === FLASHMINT FUNCTIONS ===
    /// ---------------------------

    /// @notice mint a derivative NFT and send it to the caller
    /// @notice derivative must use `_safeMint` because need onERC721Received callback
    /// @param _derivativeNFT the NFT user would like to mint
    /// @param _mintData data for the mint function ie abi.encodeWithSignature(...)
    function lendToMintSafe (
        address _derivativeNFT, 
        bytes calldata _mintData
    ) external payable 
        nonReentrant 
        notToken(_derivativeNFT) 
        noMeanCalldata(_mintData)
        noStealing
    {
        require(vaultState == State.ACTIVE, "vault not active");
        require(msg.value >= fee, "didn't send enough eth");
        require(!reserved[_derivativeNFT] || msg.sender == ownerOf(0), "NFT is reserved");
        require(_derivativeNFT != address(this), "must call another contract");
        require(_derivativeNFT != ownerOf(0), "must call another contract");

        // request data is updated by nested functions, ie onERC721Received
        delete safeMintReq.newids;
        safeMintReq = MintRequest({
            flightStatus: FlightStatus.INFLIGHT,
            expectedNFTContractAddress: _derivativeNFT,
            newids: new uint256[](0) // not used unless FlightStatus is LANDED
        });

        // mint the derivative and make sure we got it
        (bool success, ) = _derivativeNFT.call{value: msg.value - fee}(_mintData);
        require(success, "call to mint failed");
        require(safeMintReq.flightStatus == FlightStatus.LANDED, "didnt mint");

        uint256 len = safeMintReq.newids.length;
        for (uint256 i = 0; i < len; i++) {
            // @note: asserts that we own the token
            IERC721(_derivativeNFT).safeTransferFrom(address(this), msg.sender, safeMintReq.newids[i]);
        }


        emit FlashmintedSafe(msg.sender, _derivativeNFT, safeMintReq.newids, fee);

        // reset state variable for next calls.
        delete safeMintReq.newids;
        delete safeMintReq;
        safeMintReq = MintRequest({
            flightStatus: FlightStatus.READY,
            expectedNFTContractAddress: address(0),
            newids: new uint256[](0)
        });
    }

    function onERC721Received(
        address, 
        address, 
        uint256 _id, 
        bytes calldata
    ) external virtual override returns (bytes4) {
        if (safeMintReq.flightStatus == FlightStatus.INFLIGHT
            && msg.sender == safeMintReq.expectedNFTContractAddress
        ){
            // we're receiving the expected derivative
            safeMintReq.flightStatus = FlightStatus.LANDED;
            safeMintReq.newids.push(_id);
        }

        // Note: can still receive other NFTs
        return this.onERC721Received.selector;
    }

    /// @notice mint an NFT that doesn't use `safeMint()`
    /// without knowing the tokenId, two txs are required.
    /// @notice this function is unsafe if _derivativeNFT is sketchy,
    /// ie has non ERC721 `approve` fns, 
    /// @dev see `lendToMintSafe` for _safeMint() NFTs
    function lendToMint(
        address _derivativeNFT,
        bytes calldata _mintData
    ) external payable
        nonReentrant
        notToken(_derivativeNFT)
        noMeanCalldata(_mintData)
        noStealing
    {
        require(vaultState == State.ACTIVE, "vault not active");
        require(msg.value >= fee, "didn't send enough eth");
        require(!reserved[_derivativeNFT] || msg.sender == ownerOf(0), "NFT is reserved");
        require(_derivativeNFT != address(this), "must call another contract");
        require(_derivativeNFT != ownerOf(0), "must call another contract");

        uint256 balanceBefore = IERC721(_derivativeNFT).balanceOf(address(this));
        // mint the derivative and make sure we got it
        (bool success, ) = _derivativeNFT.call{value: msg.value - fee}(_mintData);
        require(success, "call to mint failed");

        // check that we minted successfully
        uint256 gained = IERC721(_derivativeNFT).balanceOf(address(this)) - balanceBefore;
        require(gained > 0, "didnt mint");

        // set them aside for the minter
        claimable[_derivativeNFT][msg.sender] += gained;
        totalClaimable[_derivativeNFT] += gained;

        emit Flashminted(msg.sender, _derivativeNFT, gained, fee);
    }

    function claimMintedNFT(address _derivativeNFT, uint256 _newTokenId) external 
        notToken(_derivativeNFT)
        noStealing
    {
        // throws if msg.sender doesn't have a claimable token
        claimable[_derivativeNFT][msg.sender] --;
        totalClaimable[_derivativeNFT] --;

        // throws if we don't own `_newTokenId`
        IERC721(_derivativeNFT).safeTransferFrom(address(this), msg.sender, _newTokenId);
        emit ClaimedMint(msg.sender, _derivativeNFT, _newTokenId);
    }

    /// ---------------------------
    /// === TOKENURI FUNCTIONS  ===
    /// ---------------------------
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(vaultState == State.ACTIVE, "no token");
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory tAddr = toAsciiString(token);
        string memory tId = id.toString();
        string memory myAddr = toAsciiString(address(this));
        return string(abi.encodePacked(
            Settings(settings).baseURI(),
            myAddr,
            "/",
            tokenId.toString(),
            "/",
            tAddr,
            "/",
            tId,
            "/"
        ));
    }
    

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /// ---------------------------
    /// = PROJECT SETTINGS & MARKETPLACES =
    /// ---------------------------   
    
    // some NFT marketplaces wants an `owner()` function
    function owner() public view virtual returns (address) {
        return Settings(settings).marketplaceAdmin();
    }

    // eventual compatibility with royalties
    function royaltyInfo(uint256 /*tokenId*/, uint256 _salePrice)
        external view virtual override 
        returns (address receiver, uint256 royaltyAmount) {
            receiver = Settings(settings).royaltyReceiver();
            royaltyAmount = _salePrice * Settings(settings).royaltyPercentBips() / 10000;
    }

    function supportsInterface(bytes4 interfaceId) 
        public view virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId
        || super.supportsInterface(interfaceId);
    }

    receive() external payable{}
}