//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

// import "./ERC721X.sol";
import "./ERC721A.sol";

contract SNOBPASS is ERC721A, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    event SaleStateUpdate(uint256 phase);

    string public baseURI = 'ipfs://QmUEbqMaSeFTjzk4Y51YTss2c451BDv2FK5QotdsNwzcw6/1.json';
    string public unrevealedURI;

    uint256 public salePhase = 0;

    uint256 public constant MAX_SUPPLY = 1234;

    uint256 public constant price = 0 ether;
    uint256 public constant PURCHASE_LIMIT = 2;

    uint256 public constant whitelistPrice = 0 ether;
    uint256 public constant WHITELIST_PURCHASE_LIMIT = 2;

    address private _signerAddress = 0x6e04336074a63F079b05308D30cc1115B0F1E32F;

    mapping(address => mapping(uint256 => bool)) public whitelistClaimed;

    constructor() ERC721A('SNOBPASS', 'SNOBPASS', MAX_SUPPLY, 1) {
        _mint(msg.sender, 4); // team reserve
    }

    // ------------- External -------------

    function mint(uint256 amount) external payable whenPublicSaleActive noContract {
        require(amount <= PURCHASE_LIMIT, 'EXCEEDS_LIMIT');
        require(msg.value == price * amount, 'INCORRECT_VALUE');

        _mint(msg.sender, amount);
    }

    function whitelistMint(uint256 amount, bytes calldata signature)
        external
        payable
        onlyWhitelisted(signature)
        noContract
    {
        require(amount <= WHITELIST_PURCHASE_LIMIT, 'EXCEEDS_LIMIT');
        require(msg.value == whitelistPrice * amount, 'INCORRECT_VALUE');

        _mint(msg.sender, amount);
    }

    // ------------- Internal -------------

    function _validSignature(bytes memory signature, uint256 _salePhase) internal view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(address(this), _salePhase, msg.sender));
        return msgHash.toEthSignedMessageHash().recover(signature) == _signerAddress;
    }

    // ------------- Owner -------------

    function giveAway(address[] calldata accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) _mint(accounts[i], 1);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string calldata _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setSignerAddress(address _address) external onlyOwner {
        _signerAddress = _address;
    }

    function setSalePhase(uint256 phase) external onlyOwner {
        salePhase = phase;
        emit SaleStateUpdate(phase);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    // ------------- Modifier -------------

    function publicSaleActive() public view returns (bool) {
        return salePhase == 0;
    }

    modifier whenPublicSaleActive() {
        require(publicSaleActive(), 'PUBLIC_SALE_NOT_ACTIVE');
        _;
    }

    modifier noContract() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }

    modifier onlyWhitelisted(bytes memory signature) {
        require(_validSignature(signature, salePhase), 'NOT_WHITELISTED');
        require(!whitelistClaimed[msg.sender][salePhase], 'WHITELIST_USED');
        whitelistClaimed[msg.sender][salePhase] = true;
        _;
    }

    // ------------- ERC721 -------------

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return
            baseURI;
    }
}
