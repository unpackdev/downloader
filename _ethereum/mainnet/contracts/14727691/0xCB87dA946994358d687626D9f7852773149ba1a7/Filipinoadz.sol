// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

/// @author ac019
contract Filipinoadz is ERC721A, Ownable, ReentrancyGuard {

    //management
    bytes32 private merkleRoot;
    string private baseURI;
    bool public isPublicSale;
    bool public isAllowlistSale;
    //minting params
    uint256 public constant COST = 0.04 ether;
    uint256 public constant MAX_SUPPLY = 7001;
    uint256 public constant MAX_PER_TRANSACTION = 10;
    // mapping: walletAddress => amountMinted
    mapping(address => uint256) public userMinted;

    constructor() ERC721A("Filipinoadz", "FPN") {
        isPublicSale = false;
        isAllowlistSale = false;
        _safeMint(msg.sender, 1); // public minting starts at index 1
    }

    /// Events:
    event UserMint(address indexed to, uint256 amount);
    event AirdropMint(address[] addresses, uint256 amount);
    event SetSaleState(bool isPublicSale, bool isAllowlistSale);

    //Helper Modifiers:
    /// @notice Checks if user payment is sufficient
    modifier mintCheck(uint256 mintAmount) {
        require(COST * mintAmount == msg.value, "Insufficient Eth");
        require(totalSupply() + mintAmount <= MAX_SUPPLY, "Out of stock.");
        _;
    }

    /// @notice Checks for valid merkle proof
    modifier merkleCheck(address recipient, bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(recipient));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Verification failed!"
        );
        _;
    }

    /// @notice Checks EOA
    modifier botCheck() {
        require(tx.origin == msg.sender, "Not Allowed");
        _;
    }

    /// @notice allowlist mint, allows for multiple minting stages
    function allowlistMint(
        address _recipient,
        uint256 _mintAmount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        mintCheck(_mintAmount)
        merkleCheck(_recipient, merkleProof)
        nonReentrant
    {
        require(isAllowlistSale, "Allowlist Sale closed");
        require(userMinted[_recipient] + _mintAmount <= MAX_PER_TRANSACTION, "Exceeded max allowlist mints");
        userMinted[_recipient] += _mintAmount;
        _safeMint(_recipient, _mintAmount);
        emit UserMint(_recipient, _mintAmount);
    }

    /// @notice Public mint,
    function publicMint(address _recipient, uint256 _mintAmount)
        external
        payable
        mintCheck(_mintAmount)
        botCheck
    {
        require(isPublicSale, "Public sale closed.");
        require(_mintAmount <= MAX_PER_TRANSACTION, "Exceeded max per transaction");
        userMinted[_recipient] += _mintAmount;
        _safeMint(_recipient, _mintAmount);
        emit UserMint(_recipient, _mintAmount);
    }

    //Admin functions:
    /// @notice Admin function for airdrop
    function airdropMint(address[] calldata _recipients, uint256 _mintAmount)
        external
        onlyOwner
    {
        require(
            totalSupply() + (_mintAmount * _recipients.length) <= MAX_SUPPLY,
            "Out of stock."
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            _safeMint(_recipients[i], _mintAmount);
        }
        emit AirdropMint(_recipients, _mintAmount);
    }

    /// @notice Admin function to change base URI
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @notice Admin function to start public sale
    function setSaleState(
        bool _isAllowlistSale,
        bool _isPublicSale
    ) public onlyOwner {
        isAllowlistSale = _isAllowlistSale;
        isPublicSale = _isPublicSale;
        emit SetSaleState(
            _isAllowlistSale,
            _isPublicSale);
    }

    /// @notice Admin function to set new merkle root
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    /// @notice Override ERC721A _baseURI()
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Admin withdraw function
    function withdraw() external onlyOwner {
        (bool success, ) = (msg.sender).call{ value: address(this).balance }(
            ""
        );
        require(success, "Withdraw failed");
    }
}
