//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

contract Web3Wizards is ERC721A, Ownable, ReentrancyGuard, Pausable {
    event SaleStateChange(uint256 _newState);

    using Strings for uint256;

    bytes32 public whitelistMerkleRoot;

    uint256 public maxTokens = 1000;
    uint256 public maxTokensPerWallet = 2;

    string private baseURI;

    enum SaleState {
        NOT_ACTIVE,
        PRESALE,
        PUBLIC_SALE
    }

    SaleState public saleState = SaleState.NOT_ACTIVE;

    mapping(address => uint256) mintedPerWallet;

    constructor(string memory _ipfsCID) ERC721A("Web3 Wizards Alpha Pass", "web3wiz") {
        baseURI = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier canMint(uint256 _amount) {
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        require(
            _amount > 0 &&
                _amount + mintedPerWallet[msg.sender] <= maxTokensPerWallet,
            "Too many tokens per wallet!"
        );
        _;
    }

    modifier whenSaleNotActive() {
        require(saleState == SaleState.NOT_ACTIVE, "Sale already started!");
        _;
    }

    function _startTokenId() internal pure override returns(uint256) {
        return 1;
    }

    function startPresale() external onlyOwner whenSaleNotActive {
        saleState = SaleState.PRESALE;
        emit SaleStateChange(uint256(SaleState.PRESALE));
    }

    function startPublicSale() external onlyOwner whenSaleNotActive {
        saleState = SaleState.PUBLIC_SALE;
        emit SaleStateChange(uint256(SaleState.PUBLIC_SALE));
    }

    function endPresale() external onlyOwner {
        require(saleState == SaleState.PRESALE, "Presale is not active!");
        saleState = SaleState.NOT_ACTIVE;
        emit SaleStateChange(uint256(SaleState.NOT_ACTIVE));
    }

    function setMaxTokensPerWallet(uint256 _amount) external onlyOwner {
        maxTokensPerWallet = _amount;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function whitelistMint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        nonReentrant
        canMint(_amount)
        isValidMerkleProof(_merkleProof, whitelistMerkleRoot)
    {
        require(saleState == SaleState.PRESALE, "Presale not active!");
        _safeMint(msg.sender, _amount);
        mintedPerWallet[msg.sender] += _amount;
    }

    function mint(uint256 _amount) external nonReentrant canMint(_amount) {
        require(saleState == SaleState.PUBLIC_SALE, "Public sale not active!");
        _safeMint(msg.sender, _amount);
        mintedPerWallet[msg.sender] += _amount;
    }
}
