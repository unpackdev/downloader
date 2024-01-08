// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title Yokai Masks Ethereum NFT Contract for https://yokai.money
 * @dev Extends ERC721 Non-Fungible Token Standard
 */
contract YokaiMasksEthereumTest3 is ContextMixin, ERC721, ERC721Enumerable, ERC721URIStorage, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // This is the provenance record of all Yokai masks in existence
    string public yokaiMasksProvenance;

    // This is the SHA-256 hash signature of the random distribution of Yokai masks
    // that can be verified after all masks are sold with the file at https://yokai.money/mask-distribution.json
    string public constant YOKAI_MASKS_DISTRIBUTION =
        "5182000dbf7c507d1da97a3a4ea85df8430fa4ef43355e379dd5ab4dbd25b2df";

    // Base metadata URI
    string public baseURI = "https://d3cm9551gyae1g.cloudfront.net/";

    // Max supply of all masks
    uint256 public constant MAX_MASK_SUPPLY = 3001;

    // Dev address
    address public devAddr;

    // Address of the mask marketplace contract
    address public marketplaceAddress;

    // Address of the Ethereum bridge contract
    address public bridgeContract;

    // OpenSea proxy registry address
    // address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; // Mainnet
    address proxyRegistryAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; // Rinkeby

    /**
     * @dev Contract constructor
     */
    constructor() ERC721("Yokai Masks", "YM") {
        devAddr = msg.sender;
        _initializeEIP712("Yokai Masks");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) override(ERC721, ERC721URIStorage) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @dev Returns a URL for the Opensea storefront-level metadata of the contract.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract.json"));
    }

    /**
    * @dev Mints masks for the BSC bridge
    */
    function mintMaskFromBridge(address _to, uint256 _mintIndex) external {
        require(totalSupply() < MAX_MASK_SUPPLY, "Sale over");
        require(totalSupply().add(1) <= MAX_MASK_SUPPLY, "Over supply");
        require(msg.sender == bridgeContract, "Not bridge");

        _safeMint(_to, _mintIndex);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function tokenExists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev Withdraw ETH from this contract (callable by owner only)
    */
    function withdrawDevFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Update dev address by the previous dev
     */
    function setDev(address payable _devAddr) external onlyOwner {
        devAddr = _devAddr;
    }

    /**
     * @dev Set the bridge contract address
     */
    function setBridgeContract(address _address) external onlyOwner {
        bridgeContract = _address;
    }

    /**
     * @dev Set the Yokai masks provenance record
     */
    function setYokaiProvenance(string memory _provenance) external onlyOwner {
        yokaiMasksProvenance = _provenance;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Sets the baseURI
     */
    function setBaseURI(string memory _yokaiBaseURI) external onlyOwner {
        baseURI = _yokaiBaseURI;
    }

    /**
     * @dev Sets the marketplace contract address
     */
    function setMarketplaceAddress(address _marketplaceAddress) external onlyOwner {
        marketplaceAddress = _marketplaceAddress;
    }

    /**
     * @dev NFT transfer for the mask marketplace
     */
    function safeMaskTransferFrom(address _from, address _to, uint256 _tokenId) external {
        require(msg.sender == marketplaceAddress, "Caller not marketplace");
        safeTransferFrom(_from, _to, _tokenId);
    }
}