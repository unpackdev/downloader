import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol";

pragma solidity ^0.8.4;

error NotEnoughETH();
error ExceedsMaxSupply();
error SaleNotActive();
error NotOnAllowlist();
error ExceedsMaxPerWallet();
error ExceedsMaxPerAllowlist();
error ExceedsMaxPerOG();

contract CryptodialsGenesis is ERC721A, Ownable {
    address public allowlistSigningAddress;
    address public ogSigningAddress;

    string public baseUri;

    bool public privateSaleActive = false;
    bool public publicSaleActive = false;

    uint256 public publicSalePrice = 101000000000000000;
    uint256 public allowlistSalePrice = 90900000000000000;
    uint256 public ogSalePrice = 80800000000000000;

    uint256 public maxSupply = 1010;
    uint256 public maxPerWallet = 5;
    uint256 public maxPerOG = 3;
    uint256 public maxPerAllowlist = 2;

    mapping(address => uint256) public ogMints;
    mapping(address => uint256) public allowlistMints;

    constructor() ERC721A("Cryptodials Genesis", "GENESIS") {}

    // Starting Token ID at 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Mint Amount
    function numberMinted(address _addr) external view returns (uint256) {
        return _numberMinted(_addr);
    }

    // Withdraw
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Base URI
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    // Allowlist Signing
    function setAllowlistSigningAddress(address _addr) public onlyOwner {
        allowlistSigningAddress = _addr;
    }

    function setOGSigningAddress(address _addr) public onlyOwner {
        ogSigningAddress = _addr;
    }

    function verifySignature(
        bytes32 hash,
        bytes memory signature,
        address signingAddress
    ) private pure returns (bool) {
        bytes32 signedMessage = ECDSA.toEthSignedMessageHash(hash);
        address recoveredAddress = ECDSA.recover(signedMessage, signature);
        return recoveredAddress == signingAddress;
    }

    // Toggle Mint
    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function togglePrivateSale() external onlyOwner {
        privateSaleActive = !privateSaleActive;
    }

    // Private Mint
    function allowlistMint(uint256 quantity, bytes calldata _allowlistSignature)
        external
        payable
    {
        if (!privateSaleActive) revert SaleNotActive();
        if (msg.value < quantity * allowlistSalePrice) revert NotEnoughETH();
        if (allowlistMints[msg.sender] + quantity > maxPerAllowlist)
            revert ExceedsMaxPerAllowlist();
        if (_numberMinted(msg.sender) + quantity > maxPerWallet)
            revert ExceedsMaxPerWallet();
        if (
            !verifySignature(
                keccak256(abi.encode(msg.sender)),
                _allowlistSignature,
                allowlistSigningAddress
            )
        ) revert NotOnAllowlist();

        allowlistMints[msg.sender] += quantity;
        safeMint(msg.sender, quantity);
    }

    function ogMint(uint256 quantity, bytes calldata _ogListSignature)
        external
        payable
    {
        if (!privateSaleActive) revert SaleNotActive();
        if (msg.value < quantity * ogSalePrice) revert NotEnoughETH();
        if (ogMints[msg.sender] + quantity > maxPerOG) revert ExceedsMaxPerOG();
        if (_numberMinted(msg.sender) + quantity > maxPerWallet)
            revert ExceedsMaxPerWallet();
        if (
            !verifySignature(
                keccak256(abi.encode(msg.sender)),
                _ogListSignature,
                ogSigningAddress
            )
        ) revert NotOnAllowlist();

        ogMints[msg.sender] += quantity;
        safeMint(msg.sender, quantity);
    }

    // Public Mint
    function mint(uint256 quantity) external payable {
        if (msg.value < quantity * publicSalePrice) revert NotEnoughETH();
        if (_numberMinted(msg.sender) + quantity > maxPerWallet)
            revert ExceedsMaxPerWallet();
        safeMint(msg.sender, quantity);
    }

    // Admin Mint
    function adminMint(uint256 quantity) external onlyOwner {
        safeMint(msg.sender, quantity);
    }

    // Override Safemint to ensure max supply
    function safeMint(address to, uint256 quantity) internal {
        if (totalSupply() + quantity > maxSupply) revert ExceedsMaxSupply();
        _safeMint(to, quantity);
    }
}
