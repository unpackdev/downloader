// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";

contract CryptoSaintsClaimableUpgrade is
    Initializable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    // prepublished hash of the artwork
    // FIXME: set this
    string public constant provenance =
        "7e652abe53d64f9293c97ece038b8b8f7c576e61c08081dca431cc9a0a9d20c2";

    // opens on ... 1619784005
    // FIXME: set this
    uint256 public constant SALE_START_TIMESTAMP = 1619870400 + 3600;

    uint256 public constant MAX_NFT_SUPPLY = 7777;

    uint256 public constant price = 55500000000000000;

    uint256 public startingIndex;

    // current metadata base prefix
    string private _baseTokenUri;

    uint256 public daoLockedFunds;
    uint256 public ownerBalance;

    // Make this an ERC20Upgradeable
    address public daoToken;

    //
    uint256 public constant PACK_LIMIT = 20;

    //
    // UPGRADE CLAIMS/BYOWNER; Sep.16
    //
    uint256 public constant PRIVATE_RESERVE = 50;
    mapping(uint256 => uint256) private saintsClaimedBitmap;
    uint256 private claimCutoffTimestamp;
    uint256 private claimSnapshotSupply;
    uint256 private saintsClaimed;
    uint256 private privateReserveClaimed;

    function initialize() public initializer {
        __ERC721_init("CryptoSaints", "SAINT");
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    function setStartingIndex() internal {
        startingIndex =
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.gasprice,
                        msg.sender,
                        block.difficulty,
                        block.timestamp
                    )
                )
            ) %
            MAX_NFT_SUPPLY;
    }

    /// @dev Multimint CryptoSaints
    function mintNFT(uint256 numberOfNfts) public payable {
        require(totalSupply() < MAX_NFT_SUPPLY, "Max Supply Reached");
        require(numberOfNfts > 0, "0 NFTs Requested");
        require(numberOfNfts <= PACK_LIMIT, "Buy Limit Exceeded");
        require(
            (totalSupply() + numberOfNfts) <= MAX_NFT_SUPPLY,
            "Minting Exceeds Max Supply"
        );
        require((price * numberOfNfts) == msg.value, "Invalid ETH Amount");
        _enforceTemporarySupplyReserve(numberOfNfts);

        if (startingIndex == 0) {
            setStartingIndex();
        }

        for (uint256 i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    /// @dev Withdraw owner's ETH from this contract.
    /// @param amount ETH amount to withdraw.
    function withdraw(uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "Can't withdraw 0 wei");
        require(amount <= address(this).balance, "Amount Exceeds Balance");

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "ETH Transfer Failed");
    }

    /// @dev Return _baseTokenUri instead of the default impl's "".
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    /// @dev Set a new base URI to use in tokenURI.
    /// @param newUri Must NOT include the trailing slash.
    function setTokenURI(string calldata newUri) public onlyOwner {
        _baseTokenUri = newUri;
    }

    /// @dev Generate a token URI.
    /// @param rTokenId A token id remapped based on `startingIndex`
    function indexedTokenURI(uint256 rTokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_baseURI(), "/", rTokenId.toString(), ".json")
            );
    }

    /// @dev Return a token URI.
    /// @param tokenId A token id. (Always non-remapped.)
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory result)
    {
        require(_exists(tokenId), "Unknown tokenId");

        return indexedTokenURI((tokenId + startingIndex) % MAX_NFT_SUPPLY);
    }

    //
    // UPGRADE CLAIMS/BYOWNER; Sep.16
    //
    function claimSaintsByOwner(uint256 count) public onlyOwner {
        _setClaimableSupplyAndCutoff();
        require(
            privateReserveClaimed + count <= PRIVATE_RESERVE,
            "Minting Exceeds Reserve"
        );

        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, totalSupply());
        }

        privateReserveClaimed += count;
    }

    function claimSaints(uint256 count) public {
        _setClaimableSupplyAndCutoff();
        require(block.timestamp < claimCutoffTimestamp, "Claim Period Expired");

        (uint256[] memory saintIds, uint256 available) = _countUnclaimed();
        require(available > 0, "No Saints To Claim");
        require(count <= available, "Claim Too High");

        uint256 toMint = (count == 0) ? available : count;
        uint256 ts = totalSupply();
        for (uint256 s = 0; s < toMint; s++) {
            _setClaimed(saintIds[s]);
            _safeMint(msg.sender, ts + s);
        }

        saintsClaimed += toMint;
    }

    function countUnclaimed() public view returns (uint256[] memory, uint256) {
        return _countUnclaimed();
    }

    function _enforceTemporarySupplyReserve(uint256 requestedToMint)
        internal
        view
    {
        // short-circuit if claim reserve no longer applies
        if (
            (claimCutoffTimestamp > 0) &&
            (claimCutoffTimestamp < block.timestamp)
        ) return;

        uint256 yetUnclaimedSaints = claimSnapshotSupply - saintsClaimed;

        require(
            (totalSupply() + requestedToMint) <=
                (MAX_NFT_SUPPLY - yetUnclaimedSaints),
            "Minting Exceeds MaxR Supply"
        );
    }

    function _isClaimed(uint256 index) private view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = saintsClaimedBitmap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        saintsClaimedBitmap[claimedWordIndex] =
            saintsClaimedBitmap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function _countUnclaimed()
        internal
        view
        returns (uint256[] memory, uint256 unclaimedCount)
    {
        require(claimSnapshotSupply > 0, "Claimable Supply Not Set");
        uint256 saintsHeld = balanceOf(msg.sender);
        uint256[] memory unclaimedSaintIds = new uint256[](saintsHeld);

        for (uint256 s = 0; s < saintsHeld; s++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, s);
            if ((tokenId < claimSnapshotSupply) && !_isClaimed(tokenId)) {
                unclaimedSaintIds[unclaimedCount] = tokenId;
                unclaimedCount++;
            }
        }

        return (unclaimedSaintIds, unclaimedCount);
    }

    function _setClaimableSupplyAndCutoff() internal {
        if (claimCutoffTimestamp == 0) {
            claimCutoffTimestamp = block.timestamp + 4 weeks;
        }

        if (claimSnapshotSupply == 0) {
            claimSnapshotSupply = totalSupply();
        }
    }
}
