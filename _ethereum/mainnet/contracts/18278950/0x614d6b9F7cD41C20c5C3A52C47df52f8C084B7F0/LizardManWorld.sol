// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721AQueryable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./OperatorFilterer.sol";
import "./IERC20.sol";

// Supply Error
error ExceedsMaxSupply();
// Sale Errors
error SaleNotActive();
error Unauthorized();
// Limit Errors
error TxnLimitReached();
error MintLimitReached();
// Utility Errors
error TimeCannotBeZero();
// General Errors
error AddressCannotBeZero();
error CallerIsAContract();
error IncorrectETHSent();

/// @title LizardManWorld NFT Contract
/// @notice This is the primary LizardManWorld NFT contract.
/// @notice This contract implements marketplace operator filtering
/// @dev This contract is used to mint Assets for the LizardManWorld project.
contract LizardManWorld is 
    ERC721AQueryable,
    Ownable,
    OperatorFilterer,
    ERC2981,
    ReentrancyGuard
{
    bytes32 private _presaleMerkleRoot;

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MINT_LIMIT_PER_ADDRESS = 5;
    uint256 public MINT_PRICE = 0.06 ether;

    bool public operatorFilteringEnabled;
    bool public publicSaleActive = false;
    bool public preSaleActive = false;
    string private _baseTokenURI;
    mapping(address => uint256) public userMinted;

    event UpdateBaseURI(string baseURI);
    event UpdateSalePrice(uint256 _price);
    event UpdatePresaleStatus(bool _preSale);
    event UpdateSaleStatus(bool _publicSale);
    event UpdatePresaleMerkleRoot(bytes32 merkleRoot);

    constructor()
        ERC721A("LizardManWorld", "LMW")
    {
        // Register for operator filtering, disable by default.
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Set default royalty to 5% (denominator out of  10000).
        _setDefaultRoyalty(0xD3c328a8cEb929fc2c743194b90EB7e1eD4d0714, 500);
    }

    //===============================================================
    //                        Modifiers
    //===============================================================

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsAContract();
        _;
    }

    modifier requireCorrectEth(uint256 _quantity) {
        if (msg.value < MINT_PRICE * _quantity) revert IncorrectETHSent();
        _;
    }

    //===============================================================
    //                    Minting Functions
    //===============================================================

    /**
     ** @dev The mint function
     ** @param _quantity The quantity to mint
     */
    function mint(uint256 quantity)
        external
        payable
        callerIsUser
        nonReentrant
        requireCorrectEth(quantity)
    {
        if (!publicSaleActive) revert SaleNotActive();

        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();

        if (userMinted[msg.sender] + quantity > MINT_LIMIT_PER_ADDRESS) revert MintLimitReached();

        userMinted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    /**
     ** @notice The presaleMint function only accepts a single transaction per wallet.
     ** it also expects a byte32 slice as calldata to provide valid proof of list.
     ** @dev The presaleMint function
     ** @param _merkleProof The merkle proof in byte32[] format
     ** @param _quantity The quantity to mint
     */
    function presaleMint(bytes32[] calldata _merkleProof, uint256 quantity)
        external
        payable
        callerIsUser
        nonReentrant
        requireCorrectEth(quantity)
    {
        if (!preSaleActive) revert SaleNotActive();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verifyCalldata(_merkleProof, _presaleMerkleRoot, leaf)) revert Unauthorized();

        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();

        if (_getAux(msg.sender) != 0) revert TxnLimitReached();

        if (userMinted[msg.sender] + quantity > MINT_LIMIT_PER_ADDRESS) revert MintLimitReached();

        userMinted[msg.sender] += quantity;
        _setAux(msg.sender, 1);
        _mint(msg.sender, quantity);
    }

    function devMint(address _to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();
        _mint(_to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //===============================================================
    //                      Setter Functions
    //===============================================================

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit UpdateBaseURI(baseURI);
    }

    function setSalePrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
        emit UpdateSalePrice(_price);
    }

    function setPresaleStatus(bool _preSale) external onlyOwner {
        preSaleActive = _preSale;
        emit UpdatePresaleStatus(_preSale);
    }

    function setSaleStatus(bool _publicSale) external onlyOwner {
        publicSaleActive = _publicSale;
        emit UpdateSaleStatus(_publicSale);
    }

    function setPresaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _presaleMerkleRoot = merkleRoot;
        emit UpdatePresaleMerkleRoot(merkleRoot);
    }

    //===============================================================
    //                  ETH and ERC20 Withdrawl
    //===============================================================

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) external onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    //===============================================================
    //                    Operator Filtering
    //===============================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) external onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    //===============================================================
    //                  ERC2981 Implementation
    //===============================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    //===============================================================
    //                   SupportsInterface
    //===============================================================

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

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}