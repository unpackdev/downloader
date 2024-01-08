// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract LazyAstronauts is
    ERC721Enumerable,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;

    /// @dev Emitted when {setTokenURI} is executed.
    event TokenURISet(string indexed tokenUri);
    /// @dev Emitted when {lockTokenURI} is executed (once-only).
    event TokenURILocked(string indexed tokenUri);
    /// @dev Emitted when a whitelisted account claims NFTs
    event Claimed(address indexed account, uint256 indexed amount);

    string public constant PROVENANCE = "9e33c54af18de47d56984f4eda22066fab48b9dc2b1ead461022210413f76467";
    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant RESERVED_COMMUNITY = 30;
    uint256 public constant RESERVED_WHITELIST = 20;
    uint256 public constant FREE_MINT_SUPPLY =
        MAX_SUPPLY - RESERVED_COMMUNITY - RESERVED_WHITELIST;
    uint256 public constant PACK_LIMIT = 20;
    // Sun Sep 26 2021 04:00:00 GMT+0000
    uint256 public constant SALE_START = 1632628800;
    uint256 public constant PRICE = 1 ether / 20;
    address private constant DW = 0x448AE6f85Eee67F7D61A45eCB5d532620e0ec0c1;
    uint256 private constant DW_SHARE = 5; // %

    string private constant METADATA_INFIX = "/metadata/";

    uint256 private dwEarnings;
    uint256 private owEarnings;
    uint256 public communityMints;
    uint256 public whitelistMints;
    bool public tokenURILocked;
    string private _baseTokenUri;

    bytes32 public merkleRoot;
    uint256 private claimedBitMap;

    // prevent callers from sending ETH directly
    receive() external payable {
        revert();
    }

    // prevent callers from sending ETH directly
    fallback() external payable {
        revert();
    }

    constructor(bytes32 merkleRoot_) ERC721("Lazy Astronauts", "LA") {
        merkleRoot = merkleRoot_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function resume() external onlyOwner {
        _unpause();
    }

    function mint(uint256 astros) external payable whenNotPaused {
        require(block.timestamp > SALE_START, "WaitForSaleToStart");
        uint256 ts = totalSupply();
        uint256 freeMints = ts - communityMints - whitelistMints;

        require(freeMints < FREE_MINT_SUPPLY, "SoldOut");
        require(astros > 0, "ZeroNFTsRequested");
        require(astros <= PACK_LIMIT, "BuyLimitExceeded");
        require(PRICE * astros == msg.value, "InvalidETHAmount");
        require(
            freeMints + astros <= FREE_MINT_SUPPLY,
            "MintingExceedsMaxSupply"
        );

        uint256 dtip = (msg.value * DW_SHARE) / 100;
        dwEarnings += dtip;
        owEarnings += (msg.value - dtip);

        mintN(astros, msg.sender);
    }

    function communityMint(uint256 astros, address to) external onlyOwner {
        require(
            communityMints + astros <= RESERVED_COMMUNITY,
            "MintingExceedsReserve"
        );
        require(astros > 0, "ZeroNFTsRequested");
        communityMints += astros;

        mintN(astros, to);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!_isClaimed(index), "AlreadyClaimed");

        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "InvalidMerkleProof"
        );

        _setClaimed(index);

        whitelistMints += amount;

        emit Claimed(account, amount);

        mintN(amount, account);
    }

    /**
     * @dev Set base token URI. Only callable by the owner and only
     * if token URI hasn't been locked through {lockTokenURI}. Emit
     * TokenURISet with the new value on every successful execution.
     *
     * @param newUri The new base URI to use from this point on.
     */
    function setTokenURI(string memory newUri)
        external
        onlyOwner
        whenUriNotLocked
    {
        _baseTokenUri = newUri;
        emit TokenURISet(_baseTokenUri);
    }

    function lockTokenURI() external onlyOwner {
        if (!tokenURILocked) {
            tokenURILocked = true;
            emit TokenURILocked(_baseTokenUri);
        }
    }

    function tipdrawAll() external onlyDev {
        tipdraw(dwEarnings);
    }

    function tipdraw(uint256 amount) public onlyDev {
        require(amount > 0, "ZeroWEIRequested");
        require(amount <= dwEarnings, "AmountExceedsEarnings");

        dwEarnings -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "ETHTransferFailed");
    }

    function withdrawAll() external onlyOwner {
        withdraw(owEarnings);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount > 0, "ZeroWEIRequested");
        require(amount <= owEarnings, "AmountExceedsEarnings");

        owEarnings -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "ETHTransferFailed");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
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

    function isClaimed(uint256 index) public view returns (bool) {
        require(index <= RESERVED_WHITELIST, "InvalidClaimIndex");
        return _isClaimed(index);
    }

    function earnings(address whose) external view returns (uint256 bal) {
        require((msg.sender == owner()) || (msg.sender == DW), "Unauthorized");
        require(whose == owner() || whose == DW, "Unauthorized");

        bal = (whose == DW) ? dwEarnings : owEarnings;
    }

    // ---- INTERNAL ----
    // ------------------
    function mintN(uint256 astros, address to) internal nonReentrant {
        uint256 ts = totalSupply();
        for (uint256 i = 0; i < astros; i++) {
            _safeMint(to, ts + i);
        }
    }

    function _isClaimed(uint256 index) internal view returns (bool) {
        uint256 mask = (1 << index);
        return claimedBitMap & mask == mask;
    }

    modifier onlyDev() {
        require(msg.sender == DW, "Unauthorized");
        _;
    }

    modifier whenUriNotLocked() {
        require(!tokenURILocked, "TokenURILockedErr");
        _;
    }

    function _setClaimed(uint256 index) private {
        claimedBitMap = claimedBitMap | (1 << index);
    }
}