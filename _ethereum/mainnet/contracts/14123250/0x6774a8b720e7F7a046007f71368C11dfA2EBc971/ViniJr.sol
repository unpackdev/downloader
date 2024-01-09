// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./draft-EIP712.sol";

contract ViniJr is ERC721, EIP712, Ownable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address _signerAddress;
    string _baseUri;
    string _contractUri;
    
    uint public constant MAX_NORMAL = 1000;
    uint public constant MAX_UNIQUE = 3;
    bool public isSalesActive = true;
    bool public isWhitelist = true;
    uint public price;
    uint public uniquesPrice;
    uint public normalMintCount = 0;
    uint public uniqueMintCount = 0;

    modifier validSignature(bytes calldata signature) {
        require(!isWhitelist || recoverAddress(msg.sender, signature) == _signerAddress, "you are not whitelisted");
        _;
    }
    
    constructor() ERC721("ViniJr", "VINI") EIP712("VINI", "1.0.0") {
        _signerAddress = 0x3115fEF0931aF890bd4E600fd5f19591430663c1;
        _contractUri = "ipfs://QmTc5DBayQJssU3mMGbJjkEfJ6jxr1dEfzy6yd9TmJrBY5";
        price = 0.45 ether;
        uniquesPrice = 65 ether;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(uint quantity, bytes calldata signature) external payable validSignature(signature) {
        require(isSalesActive, "sale is not active");
        require(normalMintCount + quantity <= MAX_NORMAL, "sold out");
        require(msg.value >= price * quantity, "ether sent is under price");
        
        for (uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, 3 + normalMintCount++);
        }
    }

    function mintUnique(bytes calldata signature) external payable validSignature(signature) {
        require(isSalesActive, "sale is not active");
        require(uniqueMintCount < MAX_UNIQUE, "sold out");
        require(msg.value >= uniquesPrice, "ether sent is under price");
        
        _safeMint(msg.sender, uniqueMintCount++);
    }
    
    function totalSupply() public view returns (uint) {
        return normalMintCount + uniqueMintCount;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function toggleWhitelist() external onlyOwner {
        isWhitelist = !isWhitelist;
    }
    
    function setPrices(uint newPrice, uint newUniquesPrice) external onlyOwner {
        price = newPrice;
        uniquesPrice = newUniquesPrice;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _hash(address account) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Whitelist(address account)"),
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account), signature);
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
}