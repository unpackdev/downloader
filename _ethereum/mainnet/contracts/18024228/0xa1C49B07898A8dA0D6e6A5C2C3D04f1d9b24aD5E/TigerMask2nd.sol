// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./MerkleProof.sol";
import "./ERC721AQueryable.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";
import "./IERC4906.sol";
import "./OperatorFilterer.sol";
import "./AccessControl.sol";

enum TicketID {
    FreeMint,
    AllowList1,
    AllowList2,
    GAAL
}

error PreMaxExceed(uint256 _presaleMax);
error MaxSupplyOver();
error NotEnoughFunds(uint256 balance);
error NotMintable();
error InvalidMerkleProof();
error AlreadyClaimedMax();
error MintAmountOver();

contract TigerMask2nd is
    ERC721A,
    IERC4906,
    ERC721AQueryable,
    OperatorFilterer,
    AccessControl,
    ERC2981
{
    uint256 private constant PUBLIC_MAX_PER_TX = 10;
    uint256 private constant PRE_MAX_CAP = 100;
    uint256 public constant MAX_SUPPLY = 2555;
    string private constant BASE_EXTENSION = ".json";
    address private constant FUND_ADDRESS =
        0x37df2D6523265a68975e2429e74E841d524b6BB9;
    address private constant ADMIN_ADDRESS =
        0x8b7fFdC69a06e06eba7352F012cdCf717Dcb11B4;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PIE_ROLE = keccak256("PIE_ROLE");

    bool public publicSale = false;
    bool public callerIsUserFlg = false;
    bool public mintable = false;
    bool public operatorFilteringEnabled = true;
    bool public renounceOwnerMintFlag = false;

    uint256 public publicCost = 0.04 ether;
    string private baseURI =
        "ar://czNTHk837IV9OOPXHG_C9LybepEL9vkvRTVUy6p76KU/";

    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(uint256 => string) private metadataURI;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    constructor(bool _callerIsUserFlg) ERC721A("TigerMask2nd", "TIGER2ND") {
        _registerForOperatorFiltering();
        _setDefaultRoyalty(ADMIN_ADDRESS, 1000);
        callerIsUserFlg = _callerIsUserFlg;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

        presaleCost[TicketID.AllowList1] = 0.035 ether;
        presaleCost[TicketID.AllowList2] = 0.04 ether;
        presaleCost[TicketID.GAAL] = 0.04 ether;
    }

    modifier whenMintable() {
        if (mintable == false) revert NotMintable();
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        if (callerIsUserFlg == true) {
            require(tx.origin == msg.sender, "The caller is another contract");
        }
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(metadataURI[tokenId]).length == 0) {
            return
                string(
                    abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION)
                );
        } else {
            return metadataURI[tokenId];
        }
    }

    function setTokenMetadataURI(
        uint256 tokenId,
        string memory metadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(
        bytes32 _merkleRoot,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot[ticket] = _merkleRoot;
    }

    function setCallerIsUserFlg(
        bool flg
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        callerIsUserFlg = flg;
    }

    function publicMint(
        address _to,
        uint256 _mintAmount
    ) external payable callerIsUser whenMintable {
        if (_totalMinted() + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (msg.value < publicCost * _mintAmount)
            revert NotEnoughFunds(msg.value);
        if (!publicSale) revert NotMintable();
        if (_mintAmount > PUBLIC_MAX_PER_TX) revert MintAmountOver();

        _mint(_to, _mintAmount);
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        TicketID ticket
    ) external payable whenMintable {
        _preMint(_mintAmount, _presaleMax, _merkleProof, msg.sender, ticket);
    }

    function _preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        address _recipient,
        TicketID ticket
    ) internal {
        if (_presaleMax > PRE_MAX_CAP) revert PreMaxExceed(_presaleMax);
        if (_totalMinted() + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (msg.value < presaleCost[ticket] * _mintAmount)
            revert NotEnoughFunds(msg.value);
        if (!presalePhase[ticket]) revert NotMintable();
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _presaleMax));
        if (whiteListClaimed[ticket][_recipient] + _mintAmount > _presaleMax)
            revert AlreadyClaimedMax();
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf))
            revert InvalidMerkleProof();

        _mint(_recipient, _mintAmount);
        whiteListClaimed[ticket][_recipient] += _mintAmount;
    }

    function mintPie(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        address _recipient,
        TicketID ticket
    ) external payable whenMintable onlyRole(PIE_ROLE) {
        _preMint(_mintAmount, _presaleMax, _merkleProof, _recipient, ticket);
    }

    function ownerMint(
        address _address,
        uint256 count
    ) external onlyRole(MINTER_ROLE) {
        require(!renounceOwnerMintFlag, "owner mint renounced");
        _safeMint(_address, count);
    }

    function setPresalePhase(
        bool _state,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setPresaleCost(
        uint256 _cost,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleCost[ticket] = _cost;
    }

    function setPublicCost(
        uint256 _publicCost
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSale = _state;
    }

    function setMintable(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    function setBaseURI(
        string memory _newBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(_startTokenId(), totalSupply());
    }

    function withdraw() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(FUND_ADDRESS).transfer(address(this).balance);
    }

    function renounceOwnerMint() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        renounceOwnerMintFlag = true;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(
        bool value
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorFilteringEnabled = value;
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
