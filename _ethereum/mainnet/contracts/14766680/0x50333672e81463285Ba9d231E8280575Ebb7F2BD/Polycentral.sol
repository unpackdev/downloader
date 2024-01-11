// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";

contract Polycentral is ERC721A, ERC2981, Ownable {
    /// Address to send payments to
    address payable public payoutAddress;

    /// Maximum supply of tokens
    uint256 public immutable maxSupply;

    /// Root hash for whitelist merkle tree
    bytes32 public root;

    /// Mapping of how many mints greenlist members have used already
    mapping(address => uint256) public greenlistMinted;

    /// Mint price
    uint256 public mintPrice;

    /// URI
    string internal baseURI;

    /// Stage of the contract.
    /// Premint: only admin may mint
    /// Greenlist: only those on greenlist may mint
    /// Public: anyone may mint
    enum MintingStage {
        Premint,
        Greenlist,
        Public
    }

    /// The current minting stage of the contract
    MintingStage public currentStage;

    /// Max mintable per address
    uint256 public maxInGreenlist;

    constructor(
        bytes32 _root,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _maxInGreenlist,
        uint96 feeNumerator,
        address payable _payoutAddress,
        string memory baseURI_
    ) ERC721A("Polycentral", "POLYCENTRAL") {
        root = _root;
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        maxInGreenlist = _maxInGreenlist;
        payoutAddress = _payoutAddress;
        baseURI = baseURI_;

        _setDefaultRoyalty(msg.sender, feeNumerator);
    }

    modifier sufficientFunds(uint256 quantity) {
        require(msg.value >= mintPrice * quantity, "Insufficient funds sent");
        _;
    }

    modifier atStage(MintingStage stage) {
        require(currentStage == stage, "Bad stage");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// Set a new base URI.
    /// @param baseURI_ new base uri
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// Premint a token.
    /// @param to address to send token to
    /// @param quantity number of tokens to mint
    function safeMint(address to, uint256 quantity)
        external
        onlyOwner
        atStage(MintingStage.Premint)
    {
        _safeMint(to, quantity);
    }

    /// Mint a token using the greenlist
    /// @param to address to send token to
    /// @param quantity number of tokens to mint
    /// @param proof merkle proof the address `to` is in greenlist
    function greenlistMint(
        address to,
        uint256 quantity,
        bytes32[] calldata proof
    )
        external
        payable
        sufficientFunds(quantity)
        atStage(MintingStage.Greenlist)
    {
        require(_verify(_leaf(to), proof), "Bad merkle proof");
        require(
            greenlistMinted[to] + quantity <= maxInGreenlist,
            "Over greenlist limit"
        );

        greenlistMinted[to] += quantity;
        _safeMint(to, quantity);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] calldata proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    /// Public mint
    /// @param to address to mint tokens to
    /// @param quantity number of tokens to mint
    function publicMint(address to, uint256 quantity)
        external
        payable
        sufficientFunds(quantity)
        atStage(MintingStage.Public)
    {
        require(
            totalSupply() + quantity <= maxSupply,
            "Would exceed max supply"
        );
        _safeMint(to, quantity);
    }

    /// Claim the balance of the contract.
    function claimBalance() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /// Set the payout address
    /// @param _payoutAddress the new payout address
    function setPayoutAddress(address payable _payoutAddress)
        external
        onlyOwner
    {
        payoutAddress = _payoutAddress;
    }

    /// Set the current sale stage
    /// @param _currentStage the new stage
    function setCurrentStage(MintingStage _currentStage) external onlyOwner {
        currentStage = _currentStage;
    }

    /// Set the Merkle tree root
    /// @param _root the new root
    function setRoot(bytes32 _root)
        external
        onlyOwner
        atStage(MintingStage.Premint)
    {
        root = _root;
    }

    /// Set the mint price
    /// @param _mintPrice the new mint price
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /// Set the greenlist mint per address
    /// @param _maxInGreenlist the new max per address
    function setMaxInGreenlist(uint256 _maxInGreenlist) external onlyOwner {
        maxInGreenlist = _maxInGreenlist;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // Overrides

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
