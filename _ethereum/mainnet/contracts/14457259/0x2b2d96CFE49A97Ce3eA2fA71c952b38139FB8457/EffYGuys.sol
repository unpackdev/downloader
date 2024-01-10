// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract EffYGuys is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public constant MAXNFTS = 5555;
    uint256 public constant freeMints = 1111;
    uint256 public maxFreeMintsPerWallet = 3;
    uint256 public constant maxPaidMintsPerWallet = 20;
    uint256 public reservedNFTs = 0;
    uint256 public MAXNFTSPurchase = 10;
    uint256 public _price = 0.01 ether;
    string public _baseTokenURI;
    bool public isSaleActive;
    address proxyRegistryAddress;

    mapping (uint256 => string) private _tokenURIs;
    mapping (address => uint256) private freeMintsWallet;

    constructor(string memory baseURI, address _proxyRegistryAddress) ERC721A("Eff You Guys", "EFF YOU GUYS") {
        setBaseURI(baseURI);
        isSaleActive = false;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function mintNFT(uint256 numberOfNFTs) external payable {
        require(isSaleActive, "Sale is not active!");
        require(numberOfNFTs >= 0 && numberOfNFTs <= MAXNFTSPurchase,
            "You can only mint 10 NFTs at a time!");
        require(totalSupply().add(numberOfNFTs) <= MAXNFTS - reservedNFTs,
            "Hold up! You would buy more NFTs than available...");

        if(totalSupply() >= freeMints){
            // Paid mints
            require(balanceOf(msg.sender).add(numberOfNFTs) <= freeMintsWallet[msg.sender].add(maxPaidMintsPerWallet),
                "You can only mint 20 paid NFTs!");
            require(msg.value >= _price.mul(numberOfNFTs),
                "Not enough ETH for this purchase!");
        }else{
            // Free mints
            require(totalSupply().add(numberOfNFTs) <= freeMints,
                "You would exceed the number of free mints");
            require(freeMintsWallet[msg.sender].add(numberOfNFTs) <= maxFreeMintsPerWallet,
                "You can only mint 3 NFTs for free!");
            freeMintsWallet[msg.sender] += numberOfNFTs;
        }
        _safeMint(msg.sender, numberOfNFTs);
    }


    function NFTOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory tokensId = new uint256[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++){
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokensId;
        }
    }

    function setNFTPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mintNFTS(address _to, uint256 _amount) external onlyOwner() {
        // Giveaway
        require(totalSupply().add(_amount) <= MAXNFTS - reservedNFTs,
            "Hold up! You would buy more NFTs than available...");
        _safeMint(_to, _amount);
    }

    function reservedMints(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= reservedNFTs, "Exceeds reserved NFT supply" );
        require(totalSupply().add(_amount) <= MAXNFTS,
            "Hold up! You would give-away more NFTs than available...");
        _safeMint(_to, _amount);
        reservedNFTs -= _amount;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance),
            "Withdraw did not work...");
    }

    function withdraw(uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(_amount < balance, "Amount is larger than balance");
        require(payable(msg.sender).send(_amount),
            "Withdraw did not work...");
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, MAXNFTS.toString()));
    }

    function isApprovedForAll(address owner, address operator) override public view returns(bool){
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setProxyRegistryAddress(address proxyAddress) external onlyOwner {
        proxyRegistryAddress = proxyAddress;
    }

    function setMaxFreeMintsPerWallet(uint256 maxFreeMintsPerWallet_) external onlyOwner {
        maxFreeMintsPerWallet = maxFreeMintsPerWallet_;
    }
}
