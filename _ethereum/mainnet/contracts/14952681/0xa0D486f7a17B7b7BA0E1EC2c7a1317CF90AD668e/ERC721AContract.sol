// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

abstract contract MintPass {
    function balanceOf(address owner, uint256 id)
        public
        view
        virtual
        returns (uint256 balance);
    function burnForAddress(
        uint256 _id, 
        uint256 _quantity,
        address _address
    ) public virtual;
}

contract ERC721AContract is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {

    using Strings for uint256;

    struct Token {
        uint16 maxSupply;
        uint16 maxPerWallet;
        uint16 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool preSaleIsActive;
        bool saleIsActive;
        bool claimIsActive;
        bool supplyLock;
        uint8 salePhase;
    }

    mapping(address => bool) public fiatAllowlist;
    mapping(address => uint16) public hasMinted;
    mapping(address => uint16) public hasClaimed;
    bytes32 public merkleRoot;
    Token public token;
    string private baseURI;
    bool public burnMintPass;
    uint16 public mintpassId;
    address public mintpassAddress;
    MintPass mintpass;

    modifier onlyFiatMinter() {
        require(fiatAllowlist[msg.sender], "Not authorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        Token memory _token
    ) ERC721A(_name, _symbol)
      PaymentSplitter(_payees, _shares) {
        baseURI = _uri;
        token = _token;
        transferOwnership(_owner);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function getClaimIneligibilityReason(address _address, uint256 _quantity) public view returns (string memory) {
        if (totalSupply() + _quantity > uint256(token.maxSupply)) return "NOT_ENOUGH_SUPPLY";
        if (token.preSaleIsActive || !token.saleIsActive) return "NOT_LIVE";
        if (!token.preSaleIsActive && token.saleIsActive) return "";
    }

    function unclaimedSupply() public view returns (uint256) {
        return uint256(token.maxSupply - uint16(totalSupply()));
    }

    function price() public view returns (uint256) {
        return token.preSaleIsActive ? token.preSalePrice : token.pubSalePrice;
    }

    function addFiatMinter(address _address) public onlyOwner {
        fiatAllowlist[_address] = true;
    }

    function removeFiatMinter(address _address) public onlyOwner {
        delete fiatAllowlist[_address];
    }

    function setMintPass(uint16 _id, address _address, bool _burn) external onlyOwner {
        mintpassId = _id;
        burnMintPass = _burn;
        mintpassAddress = _address;
        mintpass = MintPass(_address);
    }

    function setRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function lockSupply() public onlyOwner {
        token.supplyLock = true;
    }

    function updateConfig(
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint16 _maxPerTransaction,
        uint72 _preSalePrice,
        uint72 _pubSalePrice
    ) public onlyOwner {
        require(_maxSupply >= totalSupply(), "Invalid supply");
        token.maxSupply = _maxSupply;
        token.maxPerWallet = _maxPerWallet;
        token.maxPerTransaction = _maxPerTransaction;
        token.preSalePrice = _preSalePrice;
        token.pubSalePrice = _pubSalePrice;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function updateSaleState(
        bool _preSaleIsActive,
        bool _saleIsActive,
        bool _claimIsActive,
        uint8 _salePhase
    ) public onlyOwner {
        require(_salePhase == 0 || _salePhase == 1 || _salePhase == 2, "Invalid phase.");
        if (_preSaleIsActive && _salePhase == 1) require(mintpassAddress != address(0), "MintPass undefined.");
        if (_preSaleIsActive && _salePhase == 2) require(merkleRoot != "", "Root undefined");
        if (_claimIsActive) require(merkleRoot != "", "Root undefined");
        token.preSaleIsActive = _preSaleIsActive;
        token.saleIsActive = _saleIsActive;
        token.claimIsActive = _claimIsActive;
        token.salePhase = _salePhase;
    }

    function mint(uint16 _quantity, bytes32[] memory _proof) public payable nonReentrant {
        require(price() * _quantity <= msg.value, "ETH incorrect");
        uint16 _maxSupply = token.maxSupply;
        uint16 _maxPerWallet = token.maxPerWallet;
        uint16 _maxPerTransaction = token.maxPerTransaction;
        bool _saleIsActive = token.saleIsActive;
        bool _preSaleIsActive = token.preSaleIsActive;
        uint16 _currentSupply = uint16(totalSupply());
        require(_currentSupply + _quantity <= _maxSupply, "Insufficient supply");
        require(_saleIsActive, "Sale inactive");
        if(_preSaleIsActive) {
            uint16 mintedAmount = hasMinted[msg.sender] + _quantity;
            require(mintedAmount <= _maxPerWallet, "Invalid quantity");
            if (token.salePhase == 1) {
                require(mintpass.balanceOf(msg.sender, mintpassId) > 0, "MintPass required");
                require(_quantity <= mintpass.balanceOf(msg.sender, mintpassId), "Invalid quantity");
                if (burnMintPass) mintpass.burnForAddress(mintpassId, _quantity, msg.sender);
            }
            if (token.salePhase == 2) {
                require(_quantity <= _maxPerWallet, "Invalid quantity");
                bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
                require(MerkleProof.verify(_proof, merkleRoot, leaf), "Not whitelisted");
            }
            hasMinted[msg.sender] = mintedAmount;
        } else {
            require(_quantity <= _maxPerTransaction, "Invalid quantity");
        }
        _safeMint(msg.sender, _quantity);
    }

    function claimTo(address _address, uint256 _quantity) public payable nonReentrant onlyFiatMinter {
        require(token.saleIsActive, "Sale is not active.");
        require(totalSupply() + _quantity <= uint256(token.maxSupply), "Insufficient supply");
        require(price() * _quantity <= msg.value, "ETH incorrect");
        _safeMint(_address, _quantity);
    }

    function claimFree(uint16 _maxMint, uint16 _quantity, bytes32[] memory _proof) public {
        require(token.claimIsActive, "Claim inactive");
        uint16 _hasClaimed = hasClaimed[msg.sender];
        uint16 _currentSupply = uint16(totalSupply());
        require(_currentSupply + _quantity <= token.maxSupply, "Insufficient supply");
        bytes32 leaf = keccak256(abi.encode(msg.sender, _maxMint));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Not whitelisted");
        uint16 _claimable = _maxMint - _hasClaimed;
        require(_quantity <= _claimable, "Invalid quantity");
        hasClaimed[msg.sender] = _hasClaimed + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserve(address _address, uint16 _quantity) public nonReentrant onlyOwner {
        require(totalSupply() + _quantity <= token.maxSupply, "Insufficient supply");
        _safeMint(_address, _quantity);
    }
}
