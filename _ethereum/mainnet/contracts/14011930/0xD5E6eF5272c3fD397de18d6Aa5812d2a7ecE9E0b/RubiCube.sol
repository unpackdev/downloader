// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract RubiCube is ERC721, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 10000;

    uint public price = 0.035 ether;
    uint public wlPrice = 0.03 ether;

    string public baseURI = "https://storage.googleapis.com/rubicubesnft/meta/";
    uint public reservedSupply = 100;
    uint public maxMintsPerTransaction = 20;
    uint public mintingStartTimestamp = 1642280400;
    uint public mintingEndTimestamp = 1642366800;

    address public authorizedSigner = 0xf3B00453a962441b9ED7d7f95853EeacDFdA99BF;

    mapping(address => bool) public projectProxy;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    uint public totalSupply;

    constructor() ERC721("RubiCube", "RUBI") {
        mintNFTs(msg.sender, 1);
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

    function configure(
        uint _price,
        uint _wlPrice,
        uint _reservedSupply,
        uint _maxMintsPerTransaction,
        uint _mintingStartTimestamp,
        uint _mintingEndTimestamp,
        address _authorizedSigner
    ) external onlyOwner {
        price = _price;
        wlPrice = _wlPrice;
        reservedSupply = _reservedSupply;
        maxMintsPerTransaction = _maxMintsPerTransaction;
        mintingStartTimestamp = _mintingStartTimestamp;
        mintingEndTimestamp = _mintingEndTimestamp;
        authorizedSigner = _authorizedSigner;
    }
    // endregion

    // region
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    //endregion

    //
    function hashTransaction(address minter) private pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function recoverSignerAddress(address minter, bytes calldata signature) private pure returns (address) {
        bytes32 hash = hashTransaction(minter);
        return hash.recover(signature);
    }

    // Mint and Claim functions
    modifier maxSupplyCheck(uint amount)  {
        require(totalSupply + reservedSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        _;
    }

    function mintPrice(uint amount, bytes calldata signature) public view returns (uint) {
        if (signature.length != 0 && recoverSignerAddress(msg.sender, signature) == authorizedSigner) {
            return amount * wlPrice;
        } else {
            return amount * price;
        }
    }

    function mint(uint amount, bytes calldata signature) external payable {
        require(block.timestamp >= mintingStartTimestamp && block.timestamp <= mintingEndTimestamp, "Minting is not available");
        require(amount > 0 && amount <= maxMintsPerTransaction, "Wrong amount");

        require(mintPrice(amount, signature) == msg.value, "Wrong ethers value");
        mintNFTs(msg.sender, amount);
    }

    function mintNFTs(address to, uint amount) internal maxSupplyCheck(amount) {
        uint fromToken = totalSupply + 1;
        totalSupply += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(to, fromToken + i);
        }
    }
    //endregion

    function airdrop(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            mintNFTs(addresses[i], amounts[i]);
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
        payable(0x21c6D1e7237E8a005CFe6BfC3f8019473b4F242E).transfer(balance * 8 / 100);
        payable(0xE24E767B73DC585999833Fb02debd8ACC99daF69).transfer(balance * 8 / 100);
        payable(0x612DBBe0f90373ec00cabaEED679122AF9C559BE).transfer(balance * 4 / 100);
        payable(0x5cb648aCf319381081e38137500Fb002bbEAbEFf).transfer(balance * 5 / 100);
        payable(0xA9437602c382654cbEA4D91E106c966978f13449).transfer(balance * 75 / 100);
    }

}


contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}