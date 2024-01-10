// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./ScumbugsMetadata.sol";
import "./OpenseaProxy.sol";

/**
* @notice Smart contract for Scumbugs.
* ╭━━━┳━━━┳╮╱╭┳━╮╭━┳━━╮╭╮╱╭┳━━━┳━━━╮
* ┃╭━╮┃╭━╮┃┃╱┃┃┃╰╯┃┃╭╮┃┃┃╱┃┃╭━╮┃╭━╮┃
* ┃╰━━┫┃╱╰┫┃╱┃┃╭╮╭╮┃╰╯╰┫┃╱┃┃┃╱╰┫╰━━╮
* ╰━━╮┃┃╱╭┫┃╱┃┃┃┃┃┃┃╭━╮┃┃╱┃┃┃╭━╋━━╮┃
* ┃╰━╯┃╰━╯┃╰━╯┃┃┃┃┃┃╰━╯┃╰━╯┃╰┻━┃╰━╯┃
* ╰━━━┻━━━┻━━━┻╯╰╯╰┻━━━┻━━━┻━━━┻━━━╯
*/
contract ScumbugsNFT is ERC721A, Pausable, ScumbugsMetadata {

    // ---------------------- Variables ----------------------
    address private proxyRegistryAddress;
    uint256 public unitPrice = 0.069 ether;
    uint32 public constant supply = 15341;
    uint16 public constant maxAmount = 20;
    bool private isOpenSeaProxyActive = true;

    
    // ---------------------- Constructor ----------------------

    /**
     * @notice Constructor.
     */
    constructor(bytes32 _siteUrl, address _ScumbugsValues, address _proxyRegistryAddress) 
    ERC721A("Scumbugs", "SCUMBUGS")
    ScumbugsMetadata(_siteUrl, _ScumbugsValues)
    {
        proxyRegistryAddress = _proxyRegistryAddress;
        _safeMint(msg.sender, 341);
    }

    /**
     * @notice Returns the tokenId of the last minted Scumbug.
     */
    function currentTokenId() view external returns (uint256) {
        return _currentIndex - 1;
    }

    /**
     * @notice Mints new NFT(s).
     */
    function mintNFT(uint16 amount) external payable whenNotPaused {
        require(amount <= maxAmount, "Can't mint more than max amount");
        require(msg.value >= (unitPrice * amount), "Value should be equal or greater than unit price * amount");
        require((_currentIndex + amount - 1) < supply, "Can't mint that amount of NFTs");
        _safeMint(msg.sender, amount);
    }

    /**
     * @notice Withdraws the funds in the contract and sends them to the contract's owner
     */
    function withdraw() external {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Generates and stores metadata for given token id
     * @param metadataInput The data of the generated Scumbug
     */
    function generateMetadata_w1o(MetadataInput memory metadataInput) external onlyOwner {
        uint256 tokenId = metadataInput.tokenId;
        bool generated = isGenerated(tokenId);
        require(!generated, "Metadata already generated for tokenId");
        require(_currentIndex > tokenId, "NFT with tokenId does not exist");
        delete generated;
        attributesMap[tokenId] = Attributes({
            hand: metadataInput.hand,
            body: metadataInput.body,
            eyes: metadataInput.eyes,
            head: metadataInput.head,
            mouth: metadataInput.mouth,
            background_color: metadataInput.background_color,
            bug_type: metadataInput.bug_type,
            birthday: metadataInput.birthday
        });
        txhashes[tokenId] = metadataInput.txHash;
        mediaIds1[tokenId] = metadataInput.mediaId1;
        mediaIds2[tokenId] = metadataInput.mediaId2;
        mediaBdayIds1[tokenId] = metadataInput.mediaBdayId1;
        mediaBdayIds2[tokenId] = metadataInput.mediaBdayId2;
    }

    /**
     * @notice Sets siteUrl new value
     */
    function setSiteUrl(bytes32 _siteUrl) external onlyOwner {
        siteUrl = _siteUrl;
    }

    /**
     * @notice Sets the unit price
     */
    function setUnitPrice(uint256 _unitPrice) external onlyOwner whenPaused {
        unitPrice = _unitPrice;
    }

    /**
     * @dev Override tokenURI to return json instead of URI.
     * Taken from GenesisRepot: https://etherscan.io/address/0x5d4683ba64ee6283bb7fdb8a91252f6aab32a110#code
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return _render(tokenId);
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    // from CryptoCoven https://etherscan.io/address/0x5180db8f5c931aae63c74266b211f580155ecac8#code
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive) public onlyOwner {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     * Taken from CryptoCoven: https://etherscan.io/address/0x5180db8f5c931aae63c74266b211f580155ecac8#code
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
 
}