// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
contract CyberPantherPRT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public NotRevealedUri;

    uint256 public constant MAX_PANTHERZ = 7777;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant MAX_PER_MINT = 20;
    uint256 public constant PRESALE_MAX_MINT = 10;
    uint256 public constant MAX_PANTHERZ_MINT = 1000;
    uint256 public constant RESERVED_PANTHERZ = 100;
    address public constant founderAddress = 0x0912326FE1EA40B7dAf937a5B61332F99d982749;
    address public constant devAddress = 0xBAE0f07DE520Ebdf520C35364De4C15EBE72d662;
    address public constant artistAddress = 0x9907659C90A68F0A552b9a693D3600729301fD8A;
    address public constant frdevAddress = 0xeA5e7d34E5A4B6Cba85F654b8088431fd5167AE4;
    address public constant mlmnAddress = 0xF45377D501f286A855C8Bf88D4f43f3Dc899CE61;
    address public constant phfdAddress = 0x3e909Fa113DC18943031741e391f9192D8e8FC03;
    address public constant engmdAddress = 0x378070B68eC7516A0907493E0913b414be3eee0D;
    address public constant zcshAddress = 0x0116eadB04Ed89AAdA7E9d9BAe33E0da86974Bb5;
    address public constant whodaAddress = 0x1b678D4790A2832859C0684e3EAAAb4dcaE02d83;
    address public constant altrstAddress = 0xBcDe0f8e7dfd36Fb5B71b059633ffE62511693E3;
    address public constant sngstaAddress = 0x296Ae0AEb1D1Ab5366ac80a0228F1bb538ABEBD2;
    address public constant enjAddress = 0x6427362fC46CA31bF108b6c245992ed183769f22;
    address public constant strttmAddress = 0xb686c06a9667e48e1ACc4c88a7d9727B6EE2c47a;
    uint256 public reservedClaimed;
    uint256 public numPantherzMinted;
    bool public publicSaleStarted;
    bool public revealed = false;
    bool public paused = false;
    mapping(address => bool) private whitelisted;
    mapping(address => uint256) private _totalClaimed;
    
    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfPantherz);
    event PublicSaleMint(address minter, uint256 amountOfPantherz);
    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "CyberPanther PRT Public Sale Has Not Begun");
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
        require(reservedClaimed != RESERVED_PANTHERZ, "All reserved Pantherz are already claimed");
        require(reservedClaimed + amount <= RESERVED_PANTHERZ, "Minting would exceed max Pantherz reserved");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_PANTHERZ, "Too late. Go to secondary to contribute!");
        require(totalSupply() + amount <= MAX_PANTHERZ, "Max Supply reached!");
        uint256 _nextTokenId = numPantherzMinted + 1;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numPantherzMinted += amount;
        reservedClaimed += amount;
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return whitelisted[addr];
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Cannot add null address");

        return _totalClaimed[owner];
    }

    function mint(uint256 amountOfPantherz) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_PANTHERZ, "All Pantherz have been minted");
        require(amountOfPantherz <= MAX_PER_MINT, "Amount requested is higher than the amount allowed.");
        require(totalSupply() + amountOfPantherz <= MAX_PANTHERZ, "Minting would exceed max supply");
        require(
            _totalClaimed[msg.sender] + amountOfPantherz <= MAX_PANTHERZ_MINT,
            "Purchase exceeds max allowed per address"
        );
        require(amountOfPantherz > 0, "Must mint at least one Panther");
        require(PRICE * amountOfPantherz == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfPantherz; i++) {
            uint256 tokenId = numPantherzMinted + 1;

            numPantherzMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
        emit PublicSaleMint(msg.sender, amountOfPantherz);
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
        _widthdraw(artistAddress, ((balance * 5) / 100));
        _widthdraw(devAddress, ((balance * 5) / 100));
        _widthdraw(frdevAddress, ((balance * 5) / 100));
        _widthdraw(whodaAddress, ((balance * 5) / 100));
        _widthdraw(mlmnAddress, ((balance * 5) / 100));
        _widthdraw(phfdAddress, ((balance * 5) / 100));
        _widthdraw(engmdAddress, ((balance * 5) / 100));
        _widthdraw(zcshAddress, ((balance * 3) / 100));
        _widthdraw(altrstAddress, ((balance * 3) / 100));
        _widthdraw(sngstaAddress, ((balance * 3) / 100));
        _widthdraw(enjAddress, ((balance * 3) / 100));
        _widthdraw(strttmAddress, ((balance * 3) / 100));
        _widthdraw(founderAddress, address(this).balance);
    }
    
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}