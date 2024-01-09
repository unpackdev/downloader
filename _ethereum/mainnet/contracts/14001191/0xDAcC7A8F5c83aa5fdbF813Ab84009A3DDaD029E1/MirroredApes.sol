// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract MirroredApes is ERC721, Ownable {

    uint constant public MAX_SUPPLY = 10000;
    uint constant public PRICE = 0.0069 ether;

    mapping(address => bool) public projectProxy;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    string public baseURI = "https://storage.googleapis.com/mirroredapes/meta/";
    uint public maxMintsPerWallet = 100;
    uint public maxFreeNFTPerWallet = 2;

    uint public totalSupply;
    mapping(address => uint) public mintedNFTs;

    constructor() ERC721("Mirrored Apes", "MAPES") {
        _mint(msg.sender, ++totalSupply);
    }

    // Setters region
    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function toggleProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setMaxMintsPerWallet(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setMaxFreeNFTPerWallet(uint _maxFreeNFTPerWallet) external onlyOwner {
        maxFreeNFTPerWallet = _maxFreeNFTPerWallet;
    }
    // endregion

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Mint and Claim functions
    function mintPrice(uint amount) public view returns (uint) {
        uint minted = mintedNFTs[msg.sender];
        uint remainingFreeMints = maxFreeNFTPerWallet > minted ? maxFreeNFTPerWallet - minted : 0;
        if (remainingFreeMints >= amount) {
            return 0;
        } else {
            return (amount - remainingFreeMints) * PRICE;
        }
    }

    function mint(uint amount) external payable {
        require(amount > 0 && amount <= 10, "Wrong amount");
        require(totalSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "maxMintsPerWallet constraint violation");
        require(mintPrice(amount) == msg.value, "Wrong ethers value");
        mintedNFTs[msg.sender] += amount;

        uint fromToken = totalSupply + 1;
        totalSupply += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, fromToken + i);
        }
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    receive() external payable {

    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0x81a83D6dBB98D10de957f44775285398e18866e8).transfer(balance * 10 / 100);
        payable(0x333F389B3044bEc989Df27d23beEBC7F973EE1D7).transfer(balance * 20 / 100);
        payable(0x632107C7F542c738fcF864466A4Fb154f6f78E75).transfer(balance * 20 / 100);
        payable(0x80B69a849cEE64bCEF6c6dA5A809fA521Aef6091).transfer(balance * 2 / 100);
        payable(0x612DBBe0f90373ec00cabaEED679122AF9C559BE).transfer(balance * 20 / 100);
        payable(0x5cb648aCf319381081e38137500Fb002bbEAbEFf).transfer(balance * 28 / 100);
    }

}


contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}