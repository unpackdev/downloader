// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

/**
 * @title ¥u-Gi-¥n 遊戯苑 SBT
 */
contract YuGiYnSBT is Ownable, ReentrancyGuard, Pausable, ERC721AQueryable {
    /* ============ Constants ============ */
    uint256 public constant MAX_SUPPLY = 991;

    /* ============ State Variables ============ */
    string public baseURI;
    address public treasury;
    bytes32 public merkleRoot;
    uint256 public mintPrice;
    uint256 public startTime;

    /* ============ Constructor ============ */
    constructor(address _treasury, uint256 _mintPirce)
        ERC721A("YuGiYn SBT2", "YGYSBT")
    {
        require(
            _treasury != address(0),
            "YuGiYnSBT: treasury is the zero address"
        );
        require(_mintPirce > 0, "YuGiYnSBT: mint price is 0");
        treasury = _treasury;
        mintPrice = _mintPirce;
    }

    /* ============ External Functions ============ */
    /**
     * @notice Mint a new token
     */
    function mint(bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        onlyEOA
        whenNotPaused
    {
        require(
            block.timestamp >= startTime && startTime != 0,
            "YuGiYnSBT: not start"
        );
        require(
            mintVerify(msg.sender, _merkleProof),
            "YuGiYnSBT: Address is not in allow list"
        );
        require(_totalMinted() + 1 <= MAX_SUPPLY, "YuGiYnSBT: Over max supply");
        require(msg.value >= mintPrice, "YuGiYnSBT: Insufficient ETH");
        require(
            _numberMinted(msg.sender) == 0,
            "YuGiYnSBT: Over max mint per wallet"
        );

        _mint(msg.sender, 1);
    }

    /**
     * @notice Set the baseURI for tokenURI()
     * @param _newBaseURI The URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Set the mint price
     * @param _newMintPrice The new mint price
     */
    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        require(
            _newMintPrice > 0,
            "YuGiYnSBT: mint price must be greater than 0"
        );
        mintPrice = _newMintPrice;
    }

    /**
     * @notice Set the merkle root
     * @param _newMerkleRoot The new merkle root
     */
    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    /**
     * @notice Set the start time
     * @param _newStartTime The new start time
     */
    function setStartTime(uint256 _newStartTime) external onlyOwner {
        startTime = _newStartTime;
    }

    /**
     * @notice Pause the contract
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function withdraw() public {
        require(
            msg.sender == treasury,
            "YuGiYnSBT: Caller is not the treasury"
        );
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "YuGiYnSBT: Transfer failed.");
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice SOULBOUND: Block approvals.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        require(from == address(0), "YuGiYnSBT: token transfer is BLOCKED");
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /**
     * @notice SOULBOUND: Block approvals.
     */
    function approve(address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, IERC721A)
    {
        revert("Soulbound");
    }

    /**
     * @notice SOULBOUND: Block approvals.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721A, IERC721A)
    {
        revert("Soulbound");
    }

    /**
     * @notice verify the merkle proof
     */
    function mintVerify(address addr, bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice override the start token id
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice override the base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /* ============ Modifiers ============ */
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyEOA() {
        require(
            tx.origin == msg.sender,
            "YuGiYnSBT: The caller is another contract"
        );
        _;
    }

    /* ============ External Getter Functions ============ */

    /**
     * @notice Get the total number of tokens minted
     * @return The total number of tokens minted
     */
    function allowance(address _addr) public view returns (uint256) {
        return _numberMinted(_addr) == 0 ? 1 : 0;
    }
}
