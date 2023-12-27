//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721A.sol";

import "./ERC2981.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract EquityPass is ERC721A, ERC2981, ReentrancyGuard, Ownable, Pausable {
    uint256 public MAX_SUPPLY = 555;
    uint256 public MAX_MINT = 10;
    uint256 public PRICE = 0.12 ether;

    uint256 private MAX_MINT_SUPPLY = 530;
    bytes32[2] private ALLOWLIST_MERKLE_ROOT;
    string private BASE_URI;

    uint256 public MINT_PHASE;
    bool public DEV_MINTED;
    bool public BURN_ENABLED;

    mapping(address => uint256) public minters;

    event EquityPassBurned(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 timestamp
    );

    constructor(address royaltyReceiver) ERC721A("Equity Pass", "EP") {
        _setDefaultRoyalty(royaltyReceiver, 500);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "EP: contract calls not allowed.");
        _;
    }

    modifier canBurn() {
        require(BURN_ENABLED == true, "EP: burning has not been enabled.");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function mint(
        uint256 quantity,
        uint256 allocation,
        bytes32[] calldata proof
    ) external payable nonReentrant callerIsUser whenNotPaused {
        require(MINT_PHASE > 0, "EP: mint is not live.");
        require(quantity > 0, "EP: quantity cannot be zero.");
        if (DEV_MINTED) {
            require(
                _totalMinted() + quantity <= MAX_SUPPLY,
                "EP: quantity will exceed supply."
            );
        } else {
            require(
                _totalMinted() + quantity <= MAX_MINT_SUPPLY,
                "EP: quantity will exceed supply."
            );
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, allocation)))
        );
        require(
            MerkleProof.verify(
                proof,
                ALLOWLIST_MERKLE_ROOT[MINT_PHASE - 1],
                leaf
            ),
            "EP: invalid proof."
        );
        require(
            minters[msg.sender] + quantity <= MAX_MINT,
            "EP: mint quantity will exceed max mints."
        );
        require(
            minters[msg.sender] + quantity <= allocation,
            "EP: mint quantity will exceed allowlist allocation."
        );
        require(msg.value == PRICE * quantity, "EP: incorrect ether value.");

        minters[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function burn(
        uint256[] calldata tokenIds,
        address delegatee
    ) public virtual canBurn {
        address owner = delegatee != address(0) ? delegatee : msg.sender;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i], true);
            emit EquityPassBurned(tokenIds[i], owner, block.timestamp);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function devMint() external onlyOwner {
        require(DEV_MINTED == false, "EP: dev minted already.");
        uint256 quantity = MAX_SUPPLY - MAX_MINT_SUPPLY;
        require(
            _totalMinted() + quantity <= MAX_SUPPLY,
            "EP: mint quantity will exceed supply."
        );

        DEV_MINTED = true;
        _mint(msg.sender, quantity);
    }

    function setRoyalty(address receiver, uint96 value) external onlyOwner {
        _setDefaultRoyalty(receiver, value);
    }

    function setAllowlistMerkleRoot(
        bytes32[] calldata newAllowlistMerkleRoot
    ) external onlyOwner {
        require(newAllowlistMerkleRoot.length == 2, "EP: invalid merkle root");
        ALLOWLIST_MERKLE_ROOT[0] = newAllowlistMerkleRoot[0];
        ALLOWLIST_MERKLE_ROOT[1] = newAllowlistMerkleRoot[1];
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        BASE_URI = newBaseURI;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function setMaxMint(uint256 newMaxMint) external onlyOwner {
        MAX_MINT = newMaxMint;
    }

    function incrementMintPhase() external onlyOwner {
        require(MINT_PHASE < 2, "EP: already on final phase.");
        MINT_PHASE += 1;
    }

    function enableBurning() external onlyOwner {
        require(BURN_ENABLED == false, "EP: burning already enabled.");
        BURN_ENABLED = true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}
