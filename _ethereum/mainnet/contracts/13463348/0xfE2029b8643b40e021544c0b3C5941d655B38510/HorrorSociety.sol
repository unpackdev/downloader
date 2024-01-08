// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";
import "./EIP712.sol";

abstract contract PaymentSplitter {
    function pay(uint256 id) external payable virtual;
}

abstract contract CandyCard {
    function mint(address receiver) external virtual;
}

contract HorrorSociety is ERC721, EIP712, AccessControl {
    using SafeMath for uint256;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    uint constant MAX_TO_MINT = 20;
    
    address _signerAddress;
    
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "caller does not have required role");
        _;
    }

    uint constant MAX_SUPPLY = 9950;
    uint public price = 0.03 ether;
    uint public splitterId;
    
    bool public hasSaleStarted = false;
    bool public hasPreSaleStarted = false;
    
    mapping(address => uint) _addressToMintedTokens;
    
    uint _tokenIdCounter = 50;
    uint _reservedIdCounter = 0;

    PaymentSplitter _splitter = PaymentSplitter(0xAFde32E520222C8163e9ed162167759bAE585122);
    CandyCard public candyCard = CandyCard(0x7D71252bd8bE8c8A49c265B01397670c681d2A44);

    constructor() ERC721("Horror Society", "HS") EIP712("HorrorSociety", "1.0.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        setBaseURI("https://img.horrorsociety.io/");
    }
    
    function mint(address receiver) external onlyRole(ADMIN_ROLE) {
        safeMint(receiver);
    }
    
    function mintReserved(address receiver) external onlyRole(MINTER_ROLE) {
        require(_reservedIdCounter < 50, "reserved finished");
        _safeMint(receiver, _reservedIdCounter++);
    }

    function mint(uint256 quantity) public payable {
        require(hasSaleStarted, "sale has not started yet");
        require(quantity <= MAX_TO_MINT, "invalid quantity");
        require(msg.value >= price.mul(quantity), "ether value must be greater than price");
        require(_tokenIdCounter.add(quantity) <= MAX_SUPPLY, "total supply cannot exceed MAX_SUPPLY");

        for (uint256 i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function batchMint(address[] memory recipients) public onlyRole(MINTER_ROLE) {
        require(_tokenIdCounter.add(recipients.length) <= MAX_SUPPLY, "total supply cannot exceed MAX_SUPPLY");

        for (uint256 i = 0; i < recipients.length; i++) {
            safeMint(recipients[i]);
        }
    }
    
    function preSaleMint(uint quantity, uint maxMint, bytes calldata signature) payable external {
        require(hasPreSaleStarted, "pre sale did not started yet");
        require(msg.value >= price.mul(quantity), "ether value must be greater than price");
        require(quantity.add(quantity) <= MAX_SUPPLY, "total supply cannot exceed MAX_SUPPLY");
        require(_signerAddress == recoverAddress(msg.sender, maxMint, signature), "user cannot mint");
        require(_addressToMintedTokens[msg.sender].add(quantity) <= maxMint, "quantity exceeds allowance");
        
        _addressToMintedTokens[msg.sender] += quantity;
        
        for (uint256 i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }
    
    function _hash(address account, uint256 maxMint) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(uint256 maxMint,address account)"),
                        maxMint,
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, uint256 maxMint, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, maxMint), signature);
    }
    
    function burn(uint tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId) || hasRole(BURNER_ROLE, msg.sender), "caller must be owner or approved");
        _burn(tokenId);
    }

    function safeMint(address receiver) internal {
        _safeMint(receiver, _tokenIdCounter++);
        candyCard.mint(receiver);
    }

    function toggleSale() public onlyRole(ADMIN_ROLE) {
        hasSaleStarted = !hasSaleStarted;
    }

    function togglePreSale() public onlyRole(ADMIN_ROLE) {
        hasPreSaleStarted = !hasPreSaleStarted;
    }

    function setBaseURI(string memory _baseURI) public onlyRole(ADMIN_ROLE) {
        _setBaseURI(_baseURI);
    }

    function setPrice(uint _price) external onlyRole(ADMIN_ROLE) {
        price = _price;
    }

    function setSplitterId(uint id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        splitterId = id;
    }
    
    function setSignerAddress(address signerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _signerAddress = signerAddress;
    }

    function withdraw() external payable onlyRole(ADMIN_ROLE) {
        _splitter.pay{value: address(this).balance}(splitterId);
    }
}
