// Bastard Penguins Comics

// Website:  http://bastardpenguins.club/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";

contract BastardPenguinsComics is ERC721A("Bastard Penguins Comics", "BPC") {
    //
    uint256 public maxSupply = 20_000;
    uint256 public itemPrice = 0.02 ether;
    uint256 public itemPriceErc20 = 200 ether;
    uint256 public itemPriceHolder = 0.01 ether;
    uint256 public saleActiveTime = block.timestamp + 1 days;
    uint256 public saleActiveTimeErc20 = block.timestamp + 365 days;
    string public baseURI = "ipfs://QmZdX7nh6CEcXzaicfUm1Qt6o4YsFEvTM6jueyNce5Uwjf/";
    address public erc20 = 0xc3D6F4b97292f8d48344B36268BDd7400180667E; // Igloo Token
    address public erc721 = 0x350b4CdD07CC5836e30086b993D27983465Ec014; // Bastard Penguins

    ///////////////////////////////////
    //    PUBLIC SALE CODE STARTS    //
    ///////////////////////////////////

    /// @notice Purchase multiple NFTs at once
    function purchaseTokens(uint256 _howMany)
        external
        payable
        saleActive
        mintLimit(_howMany)
        priceAvailable(_howMany)
        tokensAvailable(_howMany)
    {
        _safeMint(msg.sender, _howMany);
    }

    /// @notice Purchase multiple NFTs at once
    function purchaseTokensErc20(uint256 _howMany)
        external
        saleActiveErc20
        mintLimit(_howMany)
        tokensAvailable(_howMany)
        priceAvailableERC20(_howMany)
    {
        _safeMint(msg.sender, _howMany);
    }

    //////////////////////////
    // ONLY OWNER METHODS   //
    //////////////////////////

    modifier onlyOwner() {
        require(0xe2c135274428FF8183946c3e46560Fa00353753A == msg.sender, "Caller is not the owner");
        _;
    }

    /// @notice Owner can withdraw from here
    function withdraw() external onlyOwner {
        payable(0xe2c135274428FF8183946c3e46560Fa00353753A).transfer(address(this).balance);
    }

    /// @notice Change price in case of ETH price changes too much
    function setPrice(uint256 _newPrice, uint256 _newPriceHolder) external onlyOwner {
        itemPrice = _newPrice;
        itemPriceHolder = _newPriceHolder;
    }

    /// @notice set sale active time
    function setSaleActiveTime(uint256 _saleActiveTime, uint256 _saleActiveTimeErc20) external onlyOwner {
        saleActiveTime = _saleActiveTime;
        saleActiveTimeErc20 = _saleActiveTimeErc20;
    }

    /// @notice Hide identity or show identity from here, put images folder here, ipfs folder cid
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    /// @notice set max supply of nft
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /// @notice set itemPrice in Erc20
    function setErc20(address _erc20) external onlyOwner {
        erc20 = _erc20;
    }

    /// @notice set itemPrice in Erc20
    function setItemPriceErc20(uint256 _itemPriceErc20) external onlyOwner {
        itemPriceErc20 = _itemPriceErc20;
    }

    ///////////////////////////////////
    //       AIRDROP CODE STARTS     //
    ///////////////////////////////////

    /// @notice Send NFTs to a list of addresses
    function giftNft(address[] calldata _sendNftsTo, uint256 _howMany) external onlyOwner tokensAvailable(_sendNftsTo.length * _howMany) {
        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _howMany);
    }

    ///////////////////
    // QUERY METHOD  //
    ///////////////////

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice get all nfts of a person
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) tokenIds[i] = tokenOfOwnerByIndex(_owner, i);

        return tokenIds;
    }

    ///////////////////
    //  HELPER CODE  //
    ///////////////////

    modifier saleActive() {
        require(block.timestamp > saleActiveTime, "Sale is not active");
        _;
    }

    modifier saleActiveErc20() {
        require(block.timestamp > saleActiveTimeErc20, "Sale is not active");
        _;
    }

    modifier mintLimit(uint256 _howMany) {
        require(_howMany >= 1 && _howMany <= 20, "Mint min 1, max 20");
        _;
    }

    modifier tokensAvailable(uint256 _howMany) {
        require(_howMany <= maxSupply - totalSupply(), "Try minting less tokens");
        _;
    }

    modifier priceAvailable(uint256 _howMany) {
        if (IERC721(erc721).balanceOf(msg.sender) > 0) require(msg.value >= _howMany * itemPriceHolder, "Try to send more ETH");
        else require(msg.value >= _howMany * itemPrice, "Try to send more ETH");
        _;
    }

    modifier priceAvailableERC20(uint256 _howMany) {
        require(IERC20(erc20).transferFrom(msg.sender, address(this), _howMany * itemPriceErc20), "Try to send more ERC20");
        _;
    }

    //////////////////////////
    // AUTO APPROVE OPENSEA //
    //////////////////////////

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        if (_operator == OpenSea(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(_owner)) return true; // OPENSEA
        return super.isApprovedForAll(_owner, _operator);
    }

    // send multiple nfts
    function bulkERC721Nfts(
        IERC721 _token,
        address[] calldata _to,
        uint256[] calldata _id
    ) external {
        require(_to.length == _id.length, "Receivers and IDs are different length");

        for (uint256 i = 0; i < _to.length; i++) _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
    }
}

interface OpenSea {
    function proxies(address) external view returns (address);
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}
