// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./AggregatorV3Interface.sol";

contract Gold is ERC721A, Ownable, ReentrancyGuard {
    AggregatorV3Interface public eth2usd;

    struct SettingsStruct {
        string project;
        string name;
        string symbol;
        string baseURI;
        uint256 usdPrice;
        uint256 mintingPrice;
        uint256 mintingMax;
        uint256 maxSupply;
        uint256 totalMinted;
        uint256 totalBurned;
        uint256 totalSupply;
        uint256 gasMultiplier;
        bool comingSoon;
        bool open;
    }

    using Strings for uint256;
    // Public attributes for Manageable interface
    string public baseURI;
    bool private comingSoon;
    uint256 private gasMultiplier = 4;
    uint256 private maxSupply;
    uint256 private mintingMax;
    uint256 private usdPrice;
    uint256 private _mintingPrice;
    bool private open;
    string private project;
    // Events
    event withdrawEvent(address, uint256, bool);

    constructor() ERC721A("Gold Pass", "W3BXGOLD") {
        project = "Web3 Expo NFT";
        usdPrice = 1200;
        mintingMax = 5;
        maxSupply = 7450;
        open = false;
        comingSoon = true;
        eth2usd = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    /**
     * Returns the latest price
     */
    function getETHPrice() private view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = eth2usd.latestRoundData();
        return uint256(price);
    }

    /**
     *  Minting function
     */
    function mint(uint256 tokenAmount) public payable nonReentrant {
        require(open, "Contract closed");
        require(verifyTransactionAmount(tokenAmount), "Insufficient ETH.");
        require(verifyTokensAvailability(tokenAmount), "Supply limit.");
        require(verifyTransactionLimit(tokenAmount), "Too many tokens.");
        buy(msg.sender, tokenAmount);
    }

    /**
     *  Minting function by owner
     */
    function mintByOwner(address receiver, uint256 tokenAmount)
        public
        nonReentrant
        onlyOwner
    {
        require(verifyTokensAvailability(tokenAmount), "Supply limit");
        buy(receiver, tokenAmount);
    }

    function buy(address to, uint256 quantity) internal {
        _safeMint(to, quantity);
    }

    /*
     * Owner can withdraw the contract's ETH to an external address
     */
    function withdrawETH(address _address, uint256 amount)
        public
        nonReentrant
        onlyOwner
    {
        require(_address != address(0), "200:ZERO_ADDRESS");
        require(amount <= address(this).balance, "Insufficient funds");
        (bool success, ) = _address.call{value: amount}("");
        emit withdrawEvent(_address, amount, success);
    }

    function verifyTransactionAmount(uint256 tokenAmount)
        internal
        view
        returns (bool)
    {
        return msg.value >= tokenAmount * mintingPrice();
    }

    function verifyTokensAvailability(uint256 tokenAmount)
        internal
        view
        returns (bool)
    {
        return maxSupply >= tokenAmount + _totalMinted();
    }

    function verifyTransactionLimit(uint256 tokenAmount)
        internal
        view
        returns (bool)
    {
        return mintingMax >= tokenAmount;
    }

    function burn(uint256 id) external {
        _burn(id);
    }

    function setUSDPrice(uint256 _usdPrice) external onlyOwner {
        usdPrice = _usdPrice;
        open = false;
    }

    function setGasMultiplier(uint256 _gasMultiplier) external onlyOwner {
        gasMultiplier = _gasMultiplier;
    }

    function setOpen(bool _open) external onlyOwner {
        if (_open) {
            comingSoon = false;
        }
        open = _open;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = baseURI;

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= _totalMinted(), "Total supply too low");
        maxSupply = _maxSupply;
    }

    function mintingPrice() public view returns (uint256) {
        return
            (1000000000000000000 * usdPrice * 10**eth2usd.decimals()) /
            getETHPrice();
    }

    function getSettings() public view returns (SettingsStruct memory) {
        SettingsStruct memory settings = SettingsStruct({
            project: project,
            name: name(),
            symbol: symbol(),
            baseURI: baseURI,
            usdPrice: usdPrice,
            mintingPrice: mintingPrice(),
            mintingMax: mintingMax,
            maxSupply: maxSupply,
            totalMinted: _totalMinted(),
            totalBurned: _totalBurned(),
            totalSupply: totalSupply(),
            gasMultiplier: gasMultiplier,
            comingSoon: comingSoon,
            open: open
        });
        return settings;
    }

    function setComingSoon(bool _comingSoon) external onlyOwner {
        comingSoon = _comingSoon;
    }

    function setAggregatorInterface(address _address) external onlyOwner {
        eth2usd = AggregatorV3Interface(_address);
    }

    function setMultiple(
        uint256 _maxSupply,
        uint256 _usdPrice,
        uint256 _mintingMax
    ) external onlyOwner{
        require(_maxSupply > _totalMinted(), "Total supply too low");
        maxSupply = _maxSupply;
        usdPrice = _usdPrice;
        open = (usdPrice == _usdPrice);
        if (open) {
            comingSoon = false;
        }
        mintingMax = _mintingMax;
    }
}
