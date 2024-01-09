// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract ThePicsOfPigs is ERC721A, ReentrancyGuard, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 3000;

    string public baseURI = "https://storage.googleapis.com/thepicsofpigs/meta/";

    uint public price = 0.04 ether;
    uint public presalePrice = 0.035 ether;

    uint public maxPresaleMintsPerWallet = 10;
    uint public presaleStartTimestamp = 1643144400;
    uint public mintingStartTimestamp = 1643410800;

    mapping(address => uint) public mintedNFTs;

    address public authorizedSigner = 0x2D75f4563DEc2bDA23B50815c0b9779287407B50;

    mapping(address => bool) public projectProxy;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    constructor() ERC721A("The Pics Of Pigs", "PIGS", 15) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function toggleProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function configure(
        uint _price,
        uint _presalePrice,
        uint _maxPresaleMintsPerWallet,
        uint _presaleStartTimestamp,
        uint _mintingStartTimestamp,
        address _authorizedSigner
    ) external onlyOwner {
        price = _price;
        presalePrice = _presalePrice;
        maxPresaleMintsPerWallet = _maxPresaleMintsPerWallet;
        presaleStartTimestamp = _presaleStartTimestamp;
        mintingStartTimestamp = _mintingStartTimestamp;
        authorizedSigner = _authorizedSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function hashTransaction(address minter) private pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function recoverSignerAddress(address minter, bytes calldata signature) private pure returns (address) {
        bytes32 hash = hashTransaction(minter);
        return hash.recover(signature);
    }


    function mint(uint amount, bytes calldata signature) public payable nonReentrant {
        require(tx.origin == _msgSender(), "The caller is another contract");
        require(totalSupply() + amount <= MAX_SUPPLY, "Tokens supply reached limit");

        if (signature.length != 0) {
            require(block.timestamp >= presaleStartTimestamp && block.timestamp <= presaleStartTimestamp + 2 days, "Presale minting is not available");
            require(recoverSignerAddress(_msgSender(), signature) == authorizedSigner, "You have not access to presale");
            require(presalePrice * amount == msg.value, "Wrong ethers value");

            require(mintedNFTs[_msgSender()] + amount <= maxPresaleMintsPerWallet, "maxPresaleMintsPerWallet constraint violation");
            mintedNFTs[_msgSender()] += amount;
        } else {
            require(block.timestamp >= mintingStartTimestamp, "Minting is not available");
            require(price * amount == msg.value, "Wrong ethers value");
        }

        _safeMint(_msgSender(), amount);
    }
    //endregion

    function airdrop(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + amounts[i] <= MAX_SUPPLY, "Tokens supply reached limit");
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }


    receive() external payable {

    }

    function withdraw(uint toOwner) external onlyOwner {
        uint balance = address(this).balance - toOwner;
        payable(0xf58869D5d816AdB968a86A17D0cf4CeFEe64ba28).transfer(balance * 7 / 100 + toOwner);
        payable(0x82C71278733e4F8B938594C90269486b88Fb03B6).transfer(balance * 7 / 100);
        payable(0xC3be209B0DB8bA3d4DE1151A4FF64355B3b3BE70).transfer(balance * 5 / 100);
        payable(0xf91157DD45fB287f56E03C6643626db70b8acB18).transfer(balance * 81 / 100);
    }

}


contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}