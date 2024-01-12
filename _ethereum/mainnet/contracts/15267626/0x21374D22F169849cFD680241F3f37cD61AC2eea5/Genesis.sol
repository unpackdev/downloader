// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721ABurnable.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";

contract DeltaFloraGenesis is ERC721ABurnable, ERC2981, Ownable, Pausable {
    struct StageConfig {
        bool set; // Is stage configured
        uint16 maxPerAddress; // Max mints per address
        uint232 price; // Price per mint
        bytes32 root; // Merkle root. If this is 0 then the stage is a public mint.
    }

    /// Current stage of minting
    uint256 public currentStage;

    /// Mapping of stage ID to config
    mapping(uint256 => StageConfig) public stages;

    /// Mapping of mints per address, separated by stage.
    mapping(uint256 => mapping(address => uint256)) public stageMinted;

    /// Address to send payments to
    address payable public payoutAddress;

    /// Maximum supply of tokens
    uint256 public maxSupply;

    /// URI
    string internal baseURI;

    constructor(
        uint256 _maxSupply,
        string memory baseURI_,
        uint96 feeNumerator
    ) ERC721A(unicode"∆FLORA", "FLORA") {
        maxSupply = _maxSupply;
        baseURI = baseURI_;

        _setDefaultRoyalty(msg.sender, feeNumerator);

        _pause();
    }

    /// Pause the contract.
    function pause() public onlyOwner {
        _pause();
    }

    /// Unpause the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// Set the royalty location.
    /// @param receiver address that will receive royalties
    /// @param feeNumerator percentage of sales, in bips
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// Set the current sale stage
    /// @param _currentStage the new stage
    function setCurrentStage(uint256 _currentStage) external onlyOwner {
        currentStage = _currentStage;
    }

    /// Set config for stage.
    /// @dev config.set must be TRUE
    /// @param stage the stage to set
    /// @param config the config to store
    function setStageConfig(uint256 stage, StageConfig calldata config)
        external
        onlyOwner
    {
        stages[stage] = config;
    }

    /// Set the payout address
    /// @param _payoutAddress the new payout address
    function setPayoutAddress(address payable _payoutAddress)
        external
        onlyOwner
    {
        payoutAddress = _payoutAddress;
    }

    /// Set the maximum supply of tokens.
    /// @param _maxSupply new max supply
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// Set a new base URI.
    /// @param baseURI_ new base uri
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// Claim the balance of the contract.
    function claimBalance() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /// Mint a token.
    /// @param to address to send token to
    /// @param quantity number of tokens to mint
    function adminMint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    /// Mint a token using the allowlist
    /// @param to address to send token to
    /// @param quantity number of tokens to mint
    /// @param proof merkle proof the address `to` is in allowlist
    function allowlistMint(
        address to,
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable whenNotPaused {
        uint256 _currentStage = currentStage;

        StageConfig memory sc = stages[_currentStage];
        validate(sc, _currentStage, quantity);

        require(sc.root != 0, "not allowlist mint");
        require(_verify(_leaf(msg.sender), sc.root, proof), "bad merkle proof");

        stageMinted[_currentStage][msg.sender] += quantity;
        _safeMint(to, quantity);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(
        bytes32 leaf,
        bytes32 root,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        return MerkleProof.verifyCalldata(proof, root, leaf);
    }

    /// Public mint
    /// @param to address to mint tokens to
    /// @param quantity number of tokens to mint
    function publicMint(address to, uint256 quantity)
        external
        payable
        whenNotPaused
    {
        uint256 _currentStage = currentStage;

        StageConfig memory sc = stages[_currentStage];
        validate(sc, _currentStage, quantity);

        require(sc.root == 0, "not public mint");

        stageMinted[_currentStage][msg.sender] += quantity;
        _safeMint(to, quantity);
    }

    function validate(
        StageConfig memory sc,
        uint256 stage,
        uint256 quantity
    ) internal {
        // Not over max supply
        require(totalSupply() + quantity <= maxSupply, "over max supply");
        // Stage has been set
        require(sc.set, "invalid stage");
        // Enough funds
        require(msg.value >= sc.price * quantity, "insufficient funds sent");
        // Not over per-wallet limit
        require(
            stageMinted[stage][msg.sender] + quantity <= sc.maxPerAddress,
            "over limit"
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
