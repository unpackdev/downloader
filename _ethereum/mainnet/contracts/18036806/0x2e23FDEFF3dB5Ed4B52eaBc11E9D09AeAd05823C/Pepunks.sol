// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ERC721ABurnableUpgradeable.sol";
import "./OperatorFilterer.sol";
import "./OwnableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";

import "./ECDSAUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract Pepunks is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    bool public operatorFilteringEnabled;

    address public signer;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant MINT_PRICE = 0.0069 ether;
    uint256 public constant RESERVE = 420;

    string public baseTokenURI;

    error AlreadyMinted();
    error EOAOnly();
    error InvalidSignature();
    error InvalidMintAmount();
    error MaxSupplyExceeded();
    error InsufficientFunds();
    error WalletMintLimitExceeded();

    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert EOAOnly();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _signer) public initializer initializerERC721A {
        __ERC721A_init("Pepunks", "PEPUNKS");
        __Ownable_init();
        __ERC2981_init();
        __ReentrancyGuard_init();

        signer = _signer;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _setDefaultRoyalty(msg.sender, 500);
    }

    function mint(uint256 _quantity, bytes calldata _signature) external payable nonReentrant onlyEOA {
        if (_totalMinted() + _quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (_numberMinted(msg.sender) + _quantity > MAX_PER_WALLET) revert WalletMintLimitExceeded();

        if (_numberMinted(msg.sender) == 0) {
            if (msg.value < (_quantity - 1) * MINT_PRICE) revert InsufficientFunds();
        } else {
            if (msg.value < _quantity * MINT_PRICE) revert InsufficientFunds();
        }

        _mint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable nonReentrant onlyEOA {
        if (_totalMinted() + _quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (_numberMinted(msg.sender) + _quantity > 5) revert WalletMintLimitExceeded();

        _mint(msg.sender, _quantity);
    }

    function reverseMint(address _pepe, uint256 _num) external onlyOwner {
        if (_totalMinted() + _num > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (_numberMinted(_pepe) + _num > RESERVE) revert InvalidMintAmount();
        _mint(_pepe, _num);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function withdraw(address _reciver) external onlyOwner {
        payable(_reciver).transfer(address(this).balance);
    }

    function numberMinted(address _pepe) external view returns (uint256) {
        return _numberMinted(_pepe);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _mintVerify(bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encode(msg.sender, signer)).toEthSignedMessageHash().recover(signature) == signer;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}
