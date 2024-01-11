// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";

/*
 *   ___                                  __
 *  )_  _   _ )   \  X  / o _)_ ( _     (_ ` _   _ _   _  _)_ ( _  o  _   _
 * (__ ) ) (_(     \/ \/  ( (_   ) )   .__) (_) ) ) ) )_) (_   ) ) ( ) ) (_(
 *                                                   (_                    _)
 * Unveil SOMETHING Adventurous
 * Phase 1: The Echo of Poseidon - Introduce Creature Fantasy NFT Collection
 *  ---------------------------------------------
 * | We end with SOMETHING when AI meets anything
 * | Website: https://endwithsomething.xyz/
 * | Twitter: https://twitter.com/EndWithSth
 * | Opensea: https://opensea.io/collection/creaturefantasy
 */
contract CreatureFantasy is
    Ownable,
    Pausable,
    ERC721AQueryable,
    ERC721ABurnable,
    ERC2981
{
    enum Status {
        INITIAL,
        PREMINTING,
        MINTING,
        REDEEMING,
        ENDED
    }

    uint256 public constant mintingPrice = 5 * 10**15;
    uint256 public constant mintingPriceByWhitelist = 10**15;
    uint256 public constant mintingCapPerAddress = 10;
    uint256 public constant maxSupply = 6000;
    uint256 public constant durationOfPreminting = 7200; // 2 hours
    uint256 public constant durationOfMinting = 172800; // 48 hours
    uint256 public constant durationOfRedeeming = 604800; // 1 week
    /// @dev durationOfPreminting + durationOfMinting + durationOfRedeeming
    uint256 public constant durationTotal = 784800;

    /// @notice track redeemption process
    uint256 public redeemedIndex;
    /// @notice record the timestamp from which preminting starts
    uint256 public startedAt;
    /// @notice record the timestamp from which redeeming starts
    uint256 public redeemingStartedAt;

    bytes32 public immutable airdropMerkleRoot;
    bytes32 public immutable whitelistMerkleRoot;
    string public baseURI;

    mapping(bytes32 => uint256) public airdropVerifiedAt;
    mapping(bytes32 => uint256) public whitelistVerifiedAt;

    /// @notice reserve for STH holders to redeem
    uint256 private constant _reservedSupply = 1000;
    mapping(address => uint256) private _addressToMinted;
    mapping(uint256 => address) private _tokenStakedIn;

    constructor(
        bytes32 airdropMerkleRoot_,
        bytes32 whitelistMerkleRoot_,
        uint96 defaultRoyalty
    ) ERC721A("Creature Fantasy", "CF") {
        airdropMerkleRoot = airdropMerkleRoot_;
        whitelistMerkleRoot = whitelistMerkleRoot_;

        _setDefaultRoyalty(msg.sender, defaultRoyalty);

        // Why preminting 1000 tokens ?
        // 0-999 are special editions reserved for all STH holders.
        // Holding 1 STH is eligible to claim 1 CF for free.
        _safeMint(address(this), reservedSupply());
    }

    modifier validateMinting(uint256 price, uint256 amount) {
        require(msg.sender == tx.origin, "EOA only");
        require(amount > 0, "amount = 0");
        require(_totalMinted() + amount <= maxSupply, "exceed maxSupply");
        require(msg.value >= price * amount, "insufficient payment");

        _;
    }

    /**
     * @notice Public sale
     */
    function mint(uint256 amount)
        external
        payable
        whenNotPaused
        validateMinting(mintingPrice, amount)
    {
        require(getCurrentStatus() == Status.MINTING, "expect MINTING status");

        uint256 amountUpdated = _addressToMinted[msg.sender] + amount;
        require(
            amountUpdated <= mintingCapPerAddress,
            "exceed mintingCapPerAddress"
        );
        _addressToMinted[msg.sender] = amountUpdated;

        _safeMint(msg.sender, amount);

        if (_totalMinted() == maxSupply) {
            redeemingStartedAt = block.timestamp;
        }
    }

    /**
     * @notice Users in the whitelist could mint with privileged price
     */
    function mintByWhitelist(
        uint256 amount,
        uint256 maxAmount,
        bytes32[] calldata proof
    )
        external
        payable
        whenNotPaused
        validateMinting(mintingPriceByWhitelist, amount)
    {
        require(
            getCurrentStatus() == Status.PREMINTING,
            "expect PREMINTING status"
        );
        bytes32 leaf = _leaf(msg.sender, maxAmount);
        require(
            _verify(whitelistMerkleRoot, leaf, proof),
            "bad whitelist merkle proof"
        );
        require(whitelistVerifiedAt[leaf] == 0, "whitelist proof used");
        require(amount <= maxAmount, "exceed maxAmount granted by the proof");
        whitelistVerifiedAt[leaf] = block.timestamp;
        _safeMint(msg.sender, amount);
    }

    /**
     * @notice Eligible STH holders per the snapshot could redeem 1:1 CF
     */
    function redeem(
        uint256 amount,
        uint256 maxAmount,
        bytes32[] calldata proof
    ) external whenNotPaused {
        require(
            getCurrentStatus() == Status.REDEEMING,
            "expect REDEEMING status"
        );
        bytes32 leaf = _leaf(msg.sender, maxAmount);
        require(
            _verify(airdropMerkleRoot, leaf, proof),
            "bad airdrop merkle proof"
        );
        require(airdropVerifiedAt[leaf] == 0, "airdrop proof used");
        require(amount <= maxAmount, "exceed maxAmount granted by the proof");
        airdropVerifiedAt[leaf] = block.timestamp;
        _redeem(amount);
    }

    function stakeFor(address user, uint256[] memory tokenIds)
        external
        whenNotPaused
    {
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            uint256 currId = tokenIds[i];
            address currOwner = ownerOf(currId);
            require(currOwner == user, "not token owner");
            require(
                isApprovedForAll(currOwner, msg.sender) ||
                    getApproved(currId) == msg.sender,
                "not approved"
            );
            require(
                _tokenStakedIn[currId] == address(0),
                "some token specified has been staked"
            );
            _tokenStakedIn[currId] = msg.sender;
        }
    }

    function unstakeFor(address user, uint256[] memory tokenIds)
        external
        whenNotPaused
    {
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            uint256 currId = tokenIds[i];
            address currOwner = ownerOf(currId);
            require(currOwner == user, "not token owner");
            require(
                _tokenStakedIn[currId] == msg.sender,
                "not staked or not custodian"
            );
            _tokenStakedIn[currId] = address(0);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }

    function enableMinting() external onlyOwner {
        require(startedAt == 0, "minting enabled already");
        startedAt = block.timestamp;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function getCurrentStatus() public view returns (Status) {
        if (startedAt == 0) {
            return Status.INITIAL;
        }

        // if sold out
        if (redeemingStartedAt > 0) {
            if (block.timestamp - redeemingStartedAt < durationOfRedeeming) {
                return Status.REDEEMING;
            } else {
                return Status.ENDED;
            }
        }

        uint256 dist = block.timestamp - startedAt;
        if (dist >= durationTotal) {
            return Status.ENDED;
        }

        if (dist < durationOfPreminting) {
            return Status.PREMINTING;
        } else if (dist < durationOfPreminting + durationOfMinting) {
            return Status.MINTING;
        }
        return Status.REDEEMING;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function getTotalMintedByUser(address user)
        external
        view
        returns (uint256)
    {
        return _addressToMinted[user];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _redeem(uint256 amount) internal {
        require(amount > 0, "amount = 0");
        uint256 tillIndex = redeemedIndex + amount - 1;
        require(tillIndex < reservedSupply(), "exceed reservedSupply");
        _batchTransferUnchecked(
            address(this),
            msg.sender,
            redeemedIndex,
            tillIndex
        );
        redeemedIndex = tillIndex + 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        // Skip checks on minting to reduce gas cost
        if (from == address(0)) {
            return;
        }
        (to);
        for (uint256 i = 0; i < quantity; i += 1) {
            require(
                _tokenStakedIn[startTokenId + i] == address(0),
                "can't transfer staked token"
            );
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reservedSupply() public pure virtual returns (uint256) {
        return _reservedSupply;
    }

    function _leaf(address account, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount));
    }

    function _verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}
