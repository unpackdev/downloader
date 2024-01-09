// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Cyberdad is
    ERC721,
    Ownable
{
    using ECDSA for bytes32;

    mapping (address => uint256) public alreadyMinted;
    uint256 public maxSupply = 50;
    uint256 public mintPrice = 2.5 ether;
    uint256 public whitelistMintPrice = 2 ether;
    uint256 public totalSupply = 0;
    address public signerAddress = 0x7E4723A50108AC20CBE09cD9F656bd065f5B42c8; 
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address private _manager = 0xE773A927024cE71844304D284041FDd926D5D06d;

    string public baseUri = "https://cyberdad.io/api/token/";
    string public endingUri = ".json";
    bool public saleIsActive = false;

    constructor () ERC721("Cyberdad", "CYBERDAD") {
        _mint(owner(), 1); 
        totalSupply++;
    }

    receive() external payable {}

    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller not the owner or manager");
        _;
    }

    function flipSaleState() public onlyOwnerOrManager {
        saleIsActive = !saleIsActive;
    }

    function setManager(address manager) external onlyOwnerOrManager {
        _manager = manager;
    }

    function setProxyRegistry(address preg) external onlyOwnerOrManager {
        proxyRegistryAddress = preg;
    }

    function setMintPrice(uint256 newPrice) external onlyOwnerOrManager {
        mintPrice = newPrice;
    }

    function setWLMintPrice(uint256 newPrice) external onlyOwnerOrManager {
        whitelistMintPrice = newPrice;
    }

    function setSignerAddress(address signer) external onlyOwnerOrManager {
        signerAddress = signer;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwnerOrManager {
        maxSupply = newMaxSupply;
    }

    function setBaseURI(string memory _URI) external onlyOwnerOrManager {
        baseUri = _URI;
    }

    function setEndingURI(string memory _URI) external onlyOwnerOrManager {
        endingUri = _URI;
    }

    function withdraw() public onlyOwnerOrManager {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _hash(address _address) internal view returns (bytes32) {
        return keccak256(abi.encode(address(this),_address)).toEthSignedMessageHash();
    }

    function _verify( bytes memory signature) internal view returns (bool) {
        return (_hash(msg.sender).recover(signature) == signerAddress);
    }

    function mint(uint256 amount) external payable {
        require(saleIsActive == true, "Sale not live");
        require(totalSupply + amount < maxSupply +1, "sold out");
        require(mintPrice * amount == msg.value, "not enought eth");

        for (uint256 i =0; i < amount; i++) {
            totalSupply = totalSupply + 1;
            _mint(msg.sender, totalSupply);
        }
    }

    function whitelistMint(bytes calldata _signature) external payable{
        require(totalSupply + 1 < maxSupply + 1, "sold out");
        require(whitelistMintPrice  == msg.value, "not enought eth");
        require(_verify(_signature), "bad signature");
        require(alreadyMinted[msg.sender] < 1, "already minted");
        totalSupply = totalSupply + 1;
        alreadyMinted[msg.sender]++;
        _mint(msg.sender, totalSupply);
    }


    function tokenURI(uint256 tokenId) public view  virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), endingUri));
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseUri;
    }

    function renounceOwnership() public override onlyOwner {}

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}