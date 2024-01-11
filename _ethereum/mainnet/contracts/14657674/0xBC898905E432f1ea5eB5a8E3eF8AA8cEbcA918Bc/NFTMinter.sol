//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./console.sol";

contract NFTMinter is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_MINT_PER_TX = 5;

    enum SaleStatus {
        NONE,
        PRE_SALE,
        PUBLIC_SALE
    }

    SaleStatus public saleStatus = SaleStatus.NONE;

    struct Config {
        uint200 price;
        uint8 minted;
        uint8 maxSupply;
    }

    string private _mintInfoURI;

    mapping(address => uint8) private _whitelist;
    mapping(uint8 => Config) private _configs;

    mapping(uint256 => uint8) private _tidToPid;

    event NewNFTMinted(address sender, uint256 tokenId);

    constructor() ERC721("ZIBEZI", "ZBZ") {
        console.log("NFT Contract Generation");
        _configs[1] = Config(2.3 ether, 0, 1);
        _configs[2] = Config(0.5 ether, 0, 1);
        _configs[3] = Config(2.3 ether, 0, 1);
        _configs[4] = Config(1.5 ether, 0, 1);
        _configs[5] = Config(1.1 ether, 0, 1);
        _configs[6] = Config(0.8 ether, 0, 1);
        _configs[7] = Config(0.7 ether, 0, 1);
        _configs[8] = Config(0.6 ether, 0, 1);
        _configs[9] = Config(1.6 ether, 0, 1);
        _configs[10] = Config(0.7 ether, 0, 1);
        _configs[11] = Config(0.1 ether, 0, 32);
        _configs[12] = Config(0.1 ether, 0, 32);
        _configs[13] = Config(0.1 ether, 0, 32);
        _configs[14] = Config(0.1 ether, 0, 32);
        _configs[15] = Config(0.1 ether, 0, 32);
        _configs[16] = Config(0.1 ether, 0, 32);
        _configs[17] = Config(0.1 ether, 0, 32);
        _configs[18] = Config(0.1 ether, 0, 32);
        _configs[19] = Config(0.1 ether, 0, 32);
        _configs[20] = Config(0.1 ether, 0, 32);
        _configs[21] = Config(0.1 ether, 0, 32);
        _configs[22] = Config(0.1 ether, 0, 32);
        _configs[23] = Config(0.1 ether, 0, 32);
        _configs[24] = Config(0.1 ether, 0, 1);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NFTMinter: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(_tidToPid[tokenId]),
                        ".json"
                    )
                )
                : "";
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _mintInfoURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _mintInfoURI;
    }

    function setSaleStatus(SaleStatus status) public onlyOwner {
        saleStatus = status;
    }

    function setWhitelist(address[] calldata addresses, uint8 numAllowedToMint)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = numAllowedToMint;
        }
    }

    function getTotalNFTsMintedSoFar() public view returns (uint256) {
        return uint256(_tokenIds.current());
    }

    function getProductPrice(uint8 productIndex) public view returns (uint200) {
        return _configs[productIndex].price;
    }

    function getProductMintedSoFar(uint8 productIndex)
        public
        view
        returns (uint8)
    {
        return _configs[productIndex].minted;
    }

    function getProductMaxMint(uint8 productIndex) public view returns (uint8) {
        return _configs[productIndex].maxSupply;
    }

    function getWhitelistAvailableToMint(address addr)
        public
        view
        returns (uint8)
    {
        return _whitelist[addr];
    }

    function mintAirdropNFT(
        uint8[] calldata productIndexList,
        uint8[] calldata numberOfTokensList
    ) public payable onlyOwner {
        for (uint256 i = 0; i < productIndexList.length; i++) {
            uint8 productIndex = productIndexList[i];
            uint8 numberOfTokens = numberOfTokensList[i];
            Config memory config = _configs[productIndex];
            require(config.maxSupply > 0, "Invalid product index");

            require(
                config.minted + numberOfTokens <= config.maxSupply,
                "Purchase would exceed max tokens"
            );
            _configs[productIndex].minted += numberOfTokens;
            _rawBatchMint(productIndex, numberOfTokens);
        }
    }

    function mintWhitelistNFT(uint8 productIndex, uint8 numberOfTokens)
        public
        payable
    {
        require(saleStatus != SaleStatus.NONE, "Sale is not active");
        require(
            numberOfTokens <= _whitelist[msg.sender],
            "Exceeded max available to purchase"
        );

        _batchMint(productIndex, numberOfTokens, true);
    }

    function mintNFT(uint8 productIndex, uint8 numberOfTokens) public payable {
        require(
            saleStatus == SaleStatus.PUBLIC_SALE,
            "Public sale is not active"
        );

        _batchMint(productIndex, numberOfTokens, false);
    }

    function _batchMint(
        uint8 productIndex,
        uint8 numberOfTokens,
        bool whitelist
    ) private {
        require(
            numberOfTokens <= MAX_MINT_PER_TX,
            "Exceeded max token purchase"
        );

        Config memory config = _configs[productIndex];
        require(config.maxSupply > 0, "Invalid product index");

        require(
            config.minted + numberOfTokens <= config.maxSupply,
            "Purchase would exceed max tokens"
        );

        require(msg.value == config.price * numberOfTokens, "Incorrect amount");

        if (whitelist) {
            _whitelist[msg.sender] -= numberOfTokens;
        }

        _configs[productIndex].minted += numberOfTokens;
        _rawBatchMint(productIndex, numberOfTokens);

        payable(owner()).transfer(msg.value);
    }

    function _rawBatchMint(uint8 productIndex, uint8 numberOfTokens) private {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            uint256 tid = _tokenIds.current();

            _safeMint(msg.sender, tid);
            _tidToPid[tid] = productIndex;
            emit NewNFTMinted(msg.sender, tid);
        }
    }
}
