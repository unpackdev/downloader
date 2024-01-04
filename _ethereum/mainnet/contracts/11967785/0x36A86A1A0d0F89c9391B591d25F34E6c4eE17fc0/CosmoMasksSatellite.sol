// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./CosmoMasksERC721.sol";

interface IERC20BurnTransfer {
    function burn(uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ICosmoTokenMint {
    function mintToFond(uint256 amount) external returns (bool);
}


contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


// https://eips.ethereum.org/EIPS/eip-721 tokenURI
/**
 * @title CosmoMasks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract CosmoMasksSatellite is Ownable, CosmoMasksERC721 {
    using SafeMath for uint256;

    // This is the provenance record of all CosmoMasks artwork in existence
    uint256 public constant MAX_SUPPLY = 610;
    string public constant PROVENANCE = "d2fa4e09c05d4e578b4132118a2fb2a74247e60a1e8a95734ac3274f74923ffe";
    address private _cosmoToken = address(0xf11C2B7d28eFc6E04880D66A295d72B54fc3172d);
    address proxyRegistryAddress;
    string private _contractURI;


    constructor(address _proxyRegistryAddress) public CosmoMasksERC721("CosmoMasks Satellite", "COSMASS") {
        proxyRegistryAddress = _proxyRegistryAddress;
        _setBaseURI("https://TheCosmoMasks.com/cosmomasks-satellite-metadata/");
        _setURL("https://TheCosmoMasks.com/");
        _contractURI = "https://TheCosmoMasks.com/cosmomasks-satellite-contract-metadata.json";
    }

    function getCosmoToken() public view returns (address) {
        return _cosmoToken;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
    * @dev Mints CosmoMasks
    */
    function mint(address to, uint256 numberOfMasks) public onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "CosmoMasks: sale has already ended");
        require(totalSupply().add(numberOfMasks) <= MAX_SUPPLY, "CosmoMasks: Exceeds MAX_SUPPLY");

        for (uint256 i = 0; i < numberOfMasks; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(to, mintIndex);
            ICosmoTokenMint(_cosmoToken).mintToFond(1e24);
        }
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function setCosmoToken(address token) public onlyOwner {
        require(_cosmoToken == address(0), "CosmoMasks: CosmosToken has already setted");
        require(token != address(0), "CosmoMasks: CosmoToken is the zero address");
        _cosmoToken = token;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function setURL(string memory newUrl) public onlyOwner {
        _setURL(newUrl);
    }
}
