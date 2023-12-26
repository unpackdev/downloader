// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract CryptoRangers is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public NotRevealedUri;

    uint256 public constant MAX_RANGERS = 10000;
    uint256 public constant PRICE = 0.08 ether;
    uint256 public constant MAX_PER_MINT = 10;
    uint256 public constant PRESALE_MAX_MINT = 5;
    uint256 public constant MAX_RANGERS_MINT = 100;
    uint256 public constant RESERVED_RANGERS = 200;

    address public constant founderAddress = 0xeaa020527B7051A9703d8b1325126057aF2D3204;
    address public constant devAddress = 0xEB01a6Bda263E85E62c45Bb409fd813F6a669394;
    address public constant devtwoAddress = 0x232F32A4C6559bf4b9cB3D6614C916C8B27ACf70;
    address public constant devthreeAddress = 0x5DB7D6bD2dDcFE80D641647Eb0bFb54Af0Ff075d;
    address public constant teamoneAddress = 0x2E101Af54dB3a8dB0142a75058a877231B6FBD0B;
    address public constant teamtwoAddress = 0xBd2440e2F8dDc9f03d7E2B37DD9Bb780Cb8eEb7C;
    address public constant teamthreeAddress = 0xB56b7DE403Cad004B02f67474043E7972049E3E1;
    address public constant teamfourAddress = 0x65131347c08242559e9CBD2e37Dc11b8C88e29C4;

    uint256 public reservedClaimed;
    uint256 public numRangersMinted;

    bool public publicSaleStarted;
    bool public presaleStarted;
    bool public revealed = false;
    bool public paused = false;

    mapping(address => bool) private whitelisted;
    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfRangers);
    event PublicSaleMint(address minter, uint256 amountOfRangers);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Crypto Rangers Public Sale Has Not Begun");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        require(reservedClaimed != RESERVED_RANGERS, "All reserved Rangers are already claimed");
        require(reservedClaimed + amount <= RESERVED_RANGERS, "Minting would exceed max Rangers reserved");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_RANGERS, "All Crypto Rangers have been minted!");
        require(totalSupply() + amount <= MAX_RANGERS, "Max Supply reached!");

        uint256 _nextTokenId = numRangersMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }

        numRangersMinted += amount;
        reservedClaimed += amount;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;

            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return whitelisted[addr];
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Cannot add null address");

        return _totalClaimed[owner];
    }

    function mintPresale(uint256 amountOfRangers) external payable whenPresaleStarted {
        require(whitelisted[msg.sender], "You are not a Pre-Sale Ranger");
        require(totalSupply() < MAX_RANGERS, "All tokens have been minted");
        require(amountOfRangers <= PRESALE_MAX_MINT, "Cannot purchase this many tokens during presale");
        require(totalSupply() + amountOfRangers <= MAX_RANGERS, "Minting would exceed max supply");
        require(_totalClaimed[msg.sender] + amountOfRangers <= PRESALE_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfRangers > 0, "Must mint at least one Ranger");
        require(PRICE * amountOfRangers == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfRangers; i++) {
            uint256 tokenId = numRangersMinted + 1;

            numRangersMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PresaleMint(msg.sender, amountOfRangers);
    }

    function mint(uint256 amountOfRangers) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_RANGERS, "All Rangers have been minted");
        require(amountOfRangers <= MAX_PER_MINT, "Amount requested is higher than the amount allowed.");
        require(totalSupply() + amountOfRangers <= MAX_RANGERS, "Minting would exceed max supply");
        require(
            _totalClaimed[msg.sender] + amountOfRangers <= MAX_RANGERS_MINT,
            "Purchase exceeds max allowed per address"
        );
        require(amountOfRangers > 0, "Must mint at least one Ranger");
        require(PRICE * amountOfRangers == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfRangers; i++) {
            uint256 tokenId = numRangersMinted + 1;

            numRangersMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfRangers);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return NotRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _initBaseURI) public onlyOwner {
        baseURI = _initBaseURI;
    }

    function setNotRevealedURI(string memory _NotRevealedURI) public onlyOwner {
        NotRevealedUri = _NotRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function whitelistUser(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            whitelisted[addresses[i]] = true;
            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function removeWhitelistUser(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            whitelisted[addresses[i]] = false;
        }
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(devAddress, ((balance * 11) / 100));
        _widthdraw(devtwoAddress, ((balance * 2) / 100));
        _widthdraw(devthreeAddress, ((balance * 2) / 100));
        _widthdraw(teamoneAddress, ((balance * 1) / 100));
        _widthdraw(teamtwoAddress, ((balance * 5) / 100));
        _widthdraw(teamthreeAddress, ((balance * 10) / 100));
        _widthdraw(teamfourAddress, ((balance * 5) / 100));
        _widthdraw(founderAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}
