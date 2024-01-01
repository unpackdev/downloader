// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./OperatorFilterer.sol";
import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ERC721ABurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProof.sol";

contract ChameleonTravelClub is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    ReentrancyGuardUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    ERC2981Upgradeable
{
    bool public operatorFilteringEnabled;

    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public whitelistMintStartAt;

    uint256 public whitelistMintEndAt;

    string public baseTokenURI;

    bytes32 public merkleRoot;

    error EOAOnly();
    error InvalidProof();
    error InvalidMintPeriod();
    error AlreadyMinted();
    error ExceedMaxSupply();

    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert EOAOnly();
        _;
    }

    function initialize(
        uint256 _start,
        uint256 _end
    ) public initializer initializerERC721A {
        __ERC721A_init("ChameleonTravelClub", "CTC");
        __Ownable_init(msg.sender);
        __ERC2981_init();

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _setDefaultRoyalty(msg.sender, 500);

        whitelistMintStartAt = _start;
        whitelistMintEndAt = _end;
    }

    function mint(bytes32[] calldata proof) external nonReentrant onlyEOA {
        if (
            whitelistMintStartAt > block.timestamp ||
            block.timestamp > whitelistMintEndAt
        ) revert InvalidMintPeriod();

        if (!_verify(msg.sender, proof)) revert InvalidProof();
        if (_numberMinted(msg.sender) > 0) revert AlreadyMinted();
        if (_totalMinted() + 1 > MAX_SUPPLY) revert ExceedMaxSupply();

        _mint(msg.sender, 1);
    }

    function devMint() external onlyOwner {
        if (_numberMinted(owner()) > 0) revert AlreadyMinted();
        _mint(owner(), 1);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setMintPeriod(uint256 startAt, uint256 endAt) external onlyOwner {
        whitelistMintStartAt = startAt;
        whitelistMintEndAt = endAt;
    }

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _verify(
        address account,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}
