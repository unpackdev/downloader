// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC2981.sol";

contract NftPublicSale is ERC721A("DENFTDAO", "DAO"), ERC721AQueryable, Ownable, ERC2981 {
    using Strings for uint256;

    uint256 public maxSupply = 5000;
    uint256 public nftsForOwner = 20;

    string public metadataIpfsLink1 = "ipfs://QmR9a4QZWbV5vRho5bKZCAhCJbuc5PSUse8WfcHUw9d5af/OG.json";
    string public metadataIpfsLink2 = "ipfs://QmdZRqbGC9CKveiAqcyxb5xTbR1DB874SCjCczdoduMxR6/memberpass.json";
    string public metadataIpfsLink3 = "ipfs://QmdZRqbGC9CKveiAqcyxb5xTbR1DB874SCjCczdoduMxR6/memberpass.json";
    string public metadataIpfsLink4 = "ipfs://QmdZRqbGC9CKveiAqcyxb5xTbR1DB874SCjCczdoduMxR6/memberpass.json";

    // id minted => meta data id
    mapping(uint256 => uint256) public metadataId;

    constructor() {
        _setDefaultRoyalty(msg.sender, 7_00); // 7.0 %
    }

    ///////////////////////////////////
    //       OVERRIDE CODE STARTS    //
    ///////////////////////////////////

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (metadataId[tokenId] == 1) return metadataIpfsLink1;
        else if (metadataId[tokenId] == 2) return metadataIpfsLink2;
        else if (metadataId[tokenId] == 3) return metadataIpfsLink3;
        else if (metadataId[tokenId] == 4) return metadataIpfsLink4;

        return "not found";
    }

    //////////////////
    //  ONLY OWNER  //
    //////////////////

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(0x672313cFFBbD435C16c741adc9D2e5A2AA013622).transfer((balance * 0.90 ether) / 1 ether); // 90%
        payable(0xAd33b98015eE6Cca65f55317f567Ed865BDd4959).transfer((balance * 0.10 ether) / 1 ether); // 10%
    }

    function withdrawERC20(IERC20 _erc20) external onlyOwner {
        uint256 balance = _erc20.balanceOf(address(this));

        _erc20.transfer(msg.sender, balance);
    }

    function giftNft(
        address[] calldata _sendNftsTo,
        uint256 _howMany,
        uint256 option1to4
    ) external onlyOwner {
        require(option1to4 >= 1 && option1to4 <= 4, "option should be 1 to 4");
        uint256 _mintAmount = _sendNftsTo.length * _howMany;
        nftsForOwner -= _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) metadataId[_currentIndex + i] = option1to4;

        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _howMany);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setMetadata1FolderIpfsLink(string memory _metadata1) public onlyOwner {
        metadataIpfsLink1 = _metadata1;
    }

    function setMetadata2FolderIpfsLink(string memory _metadata2) public onlyOwner {
        metadataIpfsLink2 = _metadata2;
    }

    function setMetadata3FolderIpfsLink(string memory _metadata3) public onlyOwner {
        metadataIpfsLink3 = _metadata3;
    }

    function setMetadata4FolderIpfsLink(string memory _metadata4) public onlyOwner {
        metadataIpfsLink4 = _metadata4;
    }

    function getToken() external payable {}

    receive() external payable {}
}

contract NftPublicSale1 is NftPublicSale {
    uint256 public sale1MaxMintAmount = 1;
    uint256 public sale1CostPerNft = 0.2 * 1e18;
    uint256 public sale1NftPerAddressLimit = 1;
    uint256 public sale1PublicMintActiveTime = 1663545600; // https://www.epochconverter.com/

    uint256 public publicSale1Supply = 100;
    uint256 public publicSale1Minted;

    function sale1PurchaseTokens(uint256 _mintAmount) public payable {
        require(block.timestamp > sale1PublicMintActiveTime, "the contract is paused");
        uint256 supply = totalSupply();

        require(_mintAmount <= sale1MaxMintAmount, "Max mint amount per session exceeded");
        require(supply + _mintAmount + nftsForOwner <= maxSupply, "Max NFT limit exceeded");
        require(msg.value == sale1CostPerNft * _mintAmount, "You are sending either low funds or more funds than needed");

        for (uint256 i = 0; i < _mintAmount; i++) metadataId[_currentIndex + i] = 1;

        publicSale1Minted += _mintAmount;
        require(publicSale1Minted <= publicSale1Supply, "Public sale limit reached");

        _safeMint(msg.sender, _mintAmount);
    }

    function setSale1NftPerAddressLimit(uint256 _limit) public onlyOwner {
        sale1NftPerAddressLimit = _limit;
    }

    function setSale1CostPerNft(uint256 _newSale1CostPerNft) public onlyOwner {
        sale1CostPerNft = _newSale1CostPerNft;
    }

    function setSale1MaxMintAmount(uint256 _newSale1MaxMintAmount) public onlyOwner {
        sale1MaxMintAmount = _newSale1MaxMintAmount;
    }

    function setSale1ActiveTime(uint256 _sale1PublicMintActiveTime) public onlyOwner {
        sale1PublicMintActiveTime = _sale1PublicMintActiveTime;
    }
}

contract NftPublicSale2 is NftPublicSale1 {
    uint256 public sale2MaxMintAmount = 100;
    uint256 public sale2CostPerNft = 0.2 * 1e18;
    uint256 public sale2NftPerAddressLimit = 100;
    uint256 public sale2PublicMintActiveTime = 1658188800; // https://www.epochconverter.com/

    uint256 public publicSale2Supply = 200;
    uint256 public publicSale2Minted;

    function sale2PurchaseTokens(uint256 _mintAmount) public payable {
        require(block.timestamp > sale2PublicMintActiveTime, "the contract is paused");
        uint256 supply = totalSupply();

        require(_mintAmount <= sale2MaxMintAmount, "Max mint amount per session exceeded");
        require(supply + _mintAmount + nftsForOwner <= maxSupply, "Max NFT limit exceeded");
        require(msg.value == sale2CostPerNft * _mintAmount, "You are sending either low funds or more funds than needed");

        for (uint256 i = 0; i < _mintAmount; i++) metadataId[_currentIndex + i] = 2;

        publicSale2Minted += _mintAmount;
        require(publicSale2Minted <= publicSale2Supply, "Public sale limit reached");

        _safeMint(msg.sender, _mintAmount);
    }

    function setSale2NftPerAddressLimit(uint256 _limit) public onlyOwner {
        sale2NftPerAddressLimit = _limit;
    }

    function setSale2CostPerNft(uint256 _newSale2CostPerNft) public onlyOwner {
        sale2CostPerNft = _newSale2CostPerNft;
    }

    function setSale2MaxMintAmount(uint256 _newSale2MaxMintAmount) public onlyOwner {
        sale2MaxMintAmount = _newSale2MaxMintAmount;
    }

    function setSale2ActiveTime(uint256 _sale2PublicMintActiveTime) public onlyOwner {
        sale2PublicMintActiveTime = _sale2PublicMintActiveTime;
    }
}

contract NftPublicSale3 is NftPublicSale2 {
    uint256 public sale3MaxMintAmount = 100;
    uint256 public sale3CostPerNft = 0.2 * 1e18;
    uint256 public sale3NftPerAddressLimit = 100;
    uint256 public sale3PublicMintActiveTime = 1663545600; // https://www.epochconverter.com/

    uint256 public publicSale3Supply = 2350;
    uint256 public publicSale3Minted;

    function sale3PurchaseTokens(uint256 _mintAmount) public payable {
        require(block.timestamp > sale3PublicMintActiveTime, "the contract is paused");
        uint256 supply = totalSupply();

        require(_mintAmount <= sale3MaxMintAmount, "Max mint amount per session exceeded");
        require(supply + _mintAmount + nftsForOwner <= maxSupply, "Max NFT limit exceeded");
        require(msg.value == sale3CostPerNft * _mintAmount, "You are sending either low funds or more funds than needed");

        for (uint256 i = 0; i < _mintAmount; i++) metadataId[_currentIndex + i] = 3;

        publicSale3Minted += _mintAmount;
        require(publicSale3Minted <= publicSale3Supply, "Public sale limit reached");

        _safeMint(msg.sender, _mintAmount);
    }

    function setSale3NftPerAddressLimit(uint256 _limit) public onlyOwner {
        sale3NftPerAddressLimit = _limit;
    }

    function setSale3CostPerNft(uint256 _newSale3CostPerNft) public onlyOwner {
        sale3CostPerNft = _newSale3CostPerNft;
    }

    function setSale3MaxMintAmount(uint256 _newSale3MaxMintAmount) public onlyOwner {
        sale3MaxMintAmount = _newSale3MaxMintAmount;
    }

    function setSale3ActiveTime(uint256 _sale3PublicMintActiveTime) public onlyOwner {
        sale3PublicMintActiveTime = _sale3PublicMintActiveTime;
    }
}

contract NftPublicSale4 is NftPublicSale3 {
    uint256 public sale4MaxMintAmount = 100;
    uint256 public sale4CostPerNft = 0.2 * 1e18;
    uint256 public sale4NftPerAddressLimit = 100;
    uint256 public sale4PublicMintActiveTime = 1663545600; // https://www.epochconverter.com/

    uint256 public publicSale4Supply = 2350;
    uint256 public publicSale4Minted;

    function sale4PurchaseTokens(uint256 _mintAmount) public payable {
        require(block.timestamp > sale4PublicMintActiveTime, "the contract is paused");
        uint256 supply = totalSupply();

        require(_mintAmount <= sale4MaxMintAmount, "Max mint amount per session exceeded");
        require(supply + _mintAmount + nftsForOwner <= maxSupply, "Max NFT limit exceeded");
        require(msg.value == sale4CostPerNft * _mintAmount, "You are sending either low funds or more funds than needed");

        for (uint256 i = 0; i < _mintAmount; i++) metadataId[_currentIndex + i] = 4;

        publicSale4Minted += _mintAmount;
        require(publicSale4Minted <= publicSale4Supply, "Public sale limit reached");

        _safeMint(msg.sender, _mintAmount);
    }

    function setSale4NftPerAddressLimit(uint256 _limit) public onlyOwner {
        sale4NftPerAddressLimit = _limit;
    }

    function setSale4CostPerNft(uint256 _newSale4CostPerNft) public onlyOwner {
        sale4CostPerNft = _newSale4CostPerNft;
    }

    function setSale4MaxMintAmount(uint256 _newSale4MaxMintAmount) public onlyOwner {
        sale4MaxMintAmount = _newSale4MaxMintAmount;
    }

    function setSale4ActiveTime(uint256 _sale4PublicMintActiveTime) public onlyOwner {
        sale4PublicMintActiveTime = _sale4PublicMintActiveTime;
    }
}

contract NftWhitelist1Sale is NftPublicSale4 {
    uint256 public whitelist1Supply = 100;
    uint256 public whitelist1Minted;

    uint256 public whitelist1ActiveTime = 1663545600; // https://www.epochconverter.com/;
    uint256 public whitelist1MaxMint = 1;
    uint256 public itemPriceWhitelist1 = 0.2 * 1e18;

    mapping(address => uint256) public whitelist1ClaimedBy;
    mapping(address => bool) public onWhitelist1;

    function setWhitelist1(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) onWhitelist1[addresses[i]] = true;
    }

    function removeFromWhitelist1(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) onWhitelist1[addresses[i]] = false;
    }

    function purchaseTokensWhitelist1(uint256 _howMany) external payable {
        require(whitelist1Minted + _howMany <= whitelist1Supply, "whitelist limit reached");
        require(_totalMinted() + _howMany + nftsForOwner <= maxSupply, "Max NFT limit exceeded");

        require(onWhitelist1[msg.sender], "You are not in whitelist");
        require(block.timestamp > whitelist1ActiveTime, "Whitelist is not active");
        require(msg.value == _howMany * itemPriceWhitelist1, "You are sending either low funds or more funds than needed");

        whitelist1Minted += _howMany;
        whitelist1ClaimedBy[msg.sender] += _howMany;

        require(whitelist1ClaimedBy[msg.sender] <= whitelist1MaxMint, "Purchase exceeds max allowed");

        for (uint256 i = 0; i < _howMany; i++) metadataId[_currentIndex + i] = 1;

        _safeMint(msg.sender, _howMany);
    }

    function setWhitelist1MaxMint(uint256 _whitelist1MaxMint) external onlyOwner {
        whitelist1MaxMint = _whitelist1MaxMint;
    }

    function setPriceWhitelist1(uint256 _itemPriceWhitelist1) external onlyOwner {
        itemPriceWhitelist1 = _itemPriceWhitelist1;
    }

    function setWhitelist1ActiveTime(uint256 _whitelist1ActiveTime) external onlyOwner {
        whitelist1ActiveTime = _whitelist1ActiveTime;
    }
}

contract NftAutoApproveMarketPlaces is NftWhitelist1Sale {
    mapping(address => bool) public projectProxy;

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721A, IERC721) returns (bool) {
        return projectProxy[_operator] ? true : super.isApprovedForAll(_owner, _operator);
    }
}

contract DENFTDAO is NftAutoApproveMarketPlaces {}
