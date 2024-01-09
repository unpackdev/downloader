// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./draft-EIP712.sol";

contract Strikers is ERC721, EIP712, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    address _signerAddress;
    string _contractUri;

    uint public price;
    bool public isSalesActive;
    uint[] public bundlePrices;
    uint[] public bundleSizes;
    uint public maxSupply;

    mapping (address => uint) public accountToMintedFreeTokens;

    modifier validSignature(uint maxFreeMints, bytes calldata signature) {
        require(recoverAddress(msg.sender, maxFreeMints, signature) == _signerAddress, "user cannot mint");
        _;
    }

    constructor() ERC721("Strikers", "STRIKERS") EIP712("STRIKERS", "1.0.0") {
        _contractUri = "ipfs://QmaqHpbqJcuuadoGe4HnycoWoP7QHpGRMZnv65Y4fUWar8";
        _signerAddress = 0x3115fEF0931aF890bd4E600fd5f19591430663c1;
        
        maxSupply = 10000;
        price = 0.04 ether;
        isSalesActive = true;
        bundlePrices = [
            0.114 ether,
            0.259 ether,
            0.385 ether
        ];
        bundleSizes = [3 , 7, 11];
    }

    function mint(uint quantity) external payable {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(msg.value >= price * quantity, "ether sent is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function freeMint(uint maxFreeMints, uint quantity, bytes calldata signature) 
        external validSignature(maxFreeMints, signature) {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(quantity + accountToMintedFreeTokens[msg.sender] <= maxFreeMints, "quantity exceeds allowance");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
        
        accountToMintedFreeTokens[msg.sender] += quantity;
    }

    function mintBundle(uint bundleId) payable external {
        require(bundleId < bundlePrices.length, "invalid blundle id");
        require(msg.value >= bundlePrices[bundleId], "not enough ethers");

        uint quantity = bundleSizes[bundleId];
        require(totalSupply() + quantity <= maxSupply, "sold out");

        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    function setIsSaleActive(bool isSalesActive_) external onlyOwner {
        isSalesActive = isSalesActive_;
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

    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function setBundlePrices(uint[] memory newBundlePrices, uint[] memory newBundleSizes) external onlyOwner {
        bundlePrices = newBundlePrices;
        bundleSizes = newBundleSizes;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _hash(address account, uint maxFreeMints) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(uint256 maxFreeMints,address account)"),
                        maxFreeMints,
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, uint maxFreeMints, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, maxFreeMints), signature);
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
    
    function withdraw(uint amount) external onlyOwner {
        require(payable(msg.sender).send(amount));
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}