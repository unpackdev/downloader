// UNDERGROUND APE CLUB

// Website: https://undergroundape.club/
// Twitter: https://twitter.com/undergroundapes
// Medium:  https://medium.com/@undegroundapeclub
// Discord: https://discord.com/invite/undergroundapes
// Opensea: https://opensea.io/assets/0xb94b38fcb227350989f95f54f54f43b5fcc3ccff/0

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";

contract UAC is ERC721A("Underground Ape Club", "UAC") {
    string public baseURI = "ipfs://QmVTNcKHkqF9LBAKsUJ5AjuRzNMLGwpgqmtE445drcktnx/";
    
    bool public isSaleActive;
    uint256 public itemPrice = 0.06 ether;
    uint256 public itemPricePresale = 0.03 ether;
    uint256 public immutable maxSupply = 10000;

    address public owner = msg.sender;


    ///////////////////////////////
    //    PRESALE CODE STARTS    //
    ///////////////////////////////

    bool public isAllowlistActive;
    uint256 public allowlistMaxMint = 3;
    mapping(address => bool) public onAllowlist;
    mapping(address => uint256) public allowlistClaimedBy;

    function addToAllowlist(address[] calldata addresses, bool _add)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++)
            onAllowlist[addresses[i]] = _add;
    }

    // Purchase multiple NFTs at once
    function purchasePresaleTokens(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(isAllowlistActive, "Allowlist is not active");
        require(onAllowlist[msg.sender], "You are not in allowlist");
        require(
            allowlistClaimedBy[msg.sender] + _howMany <= allowlistMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            msg.value >= _howMany * itemPricePresale,
            "Try to send more ETH"
        );

        allowlistClaimedBy[msg.sender] += _howMany;

        _safeMint(msg.sender, _howMany);
    }

    // set limit of allowlist
    function setAllowlistMaxMint(uint256 _allowlistMaxMint) external onlyOwner {
        allowlistMaxMint = _allowlistMaxMint;
    }

    // Change presale price in case of ETH price changes too much
    function setPricePresale(uint256 _itemPricePresale) external onlyOwner {
        itemPricePresale = _itemPricePresale;
    }

    function setIsAllowlistActive(bool _isAllowlistActive) external onlyOwner {
        isAllowlistActive = _isAllowlistActive;
    }

    ///////////////////////////////////
    //    PUBLIC SALE CODE STARTS    //
    ///////////////////////////////////

    // Purchase multiple NFTs at once
    function purchaseTokens(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(isSaleActive, "Sale is not active");
        require(_howMany > 0 && _howMany <= 20, "Mint min 1, max 20");
        require(msg.value >= _howMany * itemPrice, "Try to send more ETH");

        _safeMint(msg.sender, _howMany);
    }

    //////////////////////////
    // ONLY OWNER METHODS   //
    //////////////////////////

    // Owner can withdraw from here
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(owner).transfer(balance);
    }

    // Change price in case of ETH price changes too much
    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    // Hide identity or show identity from here
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    ///////////////////////////////////
    //       AIRDROP CODE STARTS     //
    ///////////////////////////////////

    // Send NFTs to a list of addresses
    function giftNftToList(address[] calldata _sendNftsTo, uint256 _howMany)
        external
        onlyOwner
        tokensAvailable(_sendNftsTo.length)
    {
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _safeMint(_sendNftsTo[i], _howMany);
    }

    // Send NFTs to a single address
    function giftNftToAddress(address _sendNftsTo, uint256 _howMany)
        external
        onlyOwner
        tokensAvailable(_howMany)
    {
        _safeMint(_sendNftsTo, _howMany);
    }

    ///////////////////
    // QUERY METHOD  //
    ///////////////////

    function tokensRemaining() public view returns (uint256) {
        return maxSupply - totalSupply() - 200; // reserve 200 mints for the team
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++)
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);

        return tokenIds;
    }

    ///////////////////
    //  HELPER CODE  //
    ///////////////////

    modifier tokensAvailable(uint256 _howMany) {
        require(_howMany <= tokensRemaining(), "Try minting less tokens");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    //////////////////////////////
    // WHITELISTING FOR STAKING //
    //////////////////////////////

    // tokenId => staked (yes or no)
    mapping(address => bool) public whitelisted;

    // add / remove from whitelist who can stake / unstake
    function addToWhitelist(address _address, bool _add) external onlyOwner {
        whitelisted[_address] = _add;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Caller is not whitelisted");
        _;
    }

    /////////////////////
    // STAKING METHOD  //
    /////////////////////

    mapping(uint256 => bool) public staked;

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        for (uint256 i = startTokenId; i < startTokenId + quantity; i++)
            require(!staked[i], "Unstake tokenId it to transfer");
    }

    // stake / unstake nfts
    function stakeNfts(uint256[] calldata _tokenIds, bool _stake)
        external
        onlyWhitelisted
    {
        for (uint256 i = 0; i < _tokenIds.length; i++)
            staked[_tokenIds[i]] = _stake;
    }

    ///////////////////////////
    // AUTO APPROVE OPENSEA  //
    ///////////////////////////

    // Opensea Registerar Mainnet 0xa5409ec958C83C3f309868babACA7c86DCB077c1
    // Opensea Registerar Rinkeby 0xF57B2c51dED3A29e6891aba85459d600256Cf317
    address openSeaRegistrar = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        if (ProxyRegisterar(openSeaRegistrar).proxies(_owner) == _operator)
            return true;

        return super.isApprovedForAll(_owner, _operator);
    }

    // infuture address changes for opensea registrar
    function editOpenSeaRegisterar(address _openSeaRegistrar)
        external
        onlyOwner
    {
        openSeaRegistrar = _openSeaRegistrar;
    }

    // just in case openSeaRegistrar is not present we use this contract
    function proxies(address) external pure returns (address) {
        return address(0);
    }
}

interface ProxyRegisterar {
    function proxies(address) external view returns (address);
}
