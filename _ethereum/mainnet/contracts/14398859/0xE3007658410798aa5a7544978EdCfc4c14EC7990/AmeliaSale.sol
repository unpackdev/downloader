// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

abstract contract AmeliaContract {
    function mintTransfer(address to, uint256 n) public virtual;

    function totalSupply() public view virtual returns (uint256);
}

contract AmeliaSale is Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public immutable maxWhitelistAmount = 6800;
    uint256 public immutable maxWhitelistPerAmount = 5;
    uint256 public immutable maxPublicSalePerAmount = 20;
    uint256 public constant whitelistSalePrice = 0.1 ether;
    uint256 public constant publicSalePrice = 0.12 ether;

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;

    // set time
    uint64 public immutable whitelistStartTime = 1647604800;
    uint64 public immutable whitelistEndTime = 1647691200;
    uint64 public immutable publicSaleStartTime = 1647691800;
    uint64 public immutable publicSaleEndTime = 1648123200;

    mapping(address => uint256) public whitelistMinted;
    uint256 public whitelistMintedAmount;

    address ameliaTokenAddress;

    constructor() {}

    // ============ MODIFIER FUNCTIONS ============
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

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier canWhitelistMint(uint256 numberOfTokens) {
        uint256 ts = whitelistMintedAmount;
        require(
            ts + numberOfTokens <= maxWhitelistAmount,
            "Purchase would exceed max whitelist round tokens"
        );
        _;
    }

    modifier canMint(uint256 numberOfTokens) {
        AmeliaContract tokenAttribution = AmeliaContract(ameliaTokenAddress);
        uint256 ts = tokenAttribution.totalSupply();
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        _;
    }

    modifier checkWhitelistTime() {
        require(
            block.timestamp >= uint256(whitelistStartTime) &&
                block.timestamp <= uint256(whitelistEndTime),
            "Outside whitelist round hours"
        );
        _;
    }
    modifier checkPublicSaleTime() {
        require(
            block.timestamp >= uint256(publicSaleStartTime) &&
                block.timestamp <= uint256(publicSaleEndTime),
            "Outside public sale hours"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mintWhitelist(uint256 n, bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(whitelistSalePrice, n)
        canWhitelistMint(n)
        checkWhitelistTime
        nonReentrant
    {
        require(
            whitelistMinted[msg.sender] + n <= maxWhitelistPerAmount,
            "NFT is already exceed max mint amount by this wallet"
        );
        AmeliaContract tokenAttribution = AmeliaContract(ameliaTokenAddress);
        tokenAttribution.mintTransfer(msg.sender, n);
        whitelistMinted[msg.sender] += n;
        whitelistMintedAmount += n;
    }

    function publicMint(uint256 n)
        public
        payable
        isCorrectPayment(publicSalePrice, n)
        canMint(n)
        checkPublicSaleTime
        nonReentrant
    {
        require(
            n <= maxPublicSalePerAmount,
            "NFT is already exceed max mint amount by this time(max=20)"
        );
        AmeliaContract tokenAttribution = AmeliaContract(ameliaTokenAddress);
        tokenAttribution.mintTransfer(msg.sender, n);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setAmeliaTokenAddress(address newAddress) public onlyOwner {
        ameliaTokenAddress = newAddress;
    }
}
