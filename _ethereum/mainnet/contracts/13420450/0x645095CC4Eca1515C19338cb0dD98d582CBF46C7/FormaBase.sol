// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

abstract contract FormaBase is ERC721Enumerable, Ownable {
    event Mint(address indexed _to, uint256 indexed _tokenId);

    enum SalesState {
        Closed,
        PreSale,
        Active
    }

    mapping(address => bool) public admins;
    mapping(address => uint16) public presaleMintsLeft;

    address public formaAddress;
    uint256 public formaPercentage = 10;

    address public artistAddress;
    uint256 public artistPercentage = 90;

    address public secondPayoutAddress;
    uint256 public secondPayoutSplit = 0;

    uint64 public freshTokensMinted = 0;
    uint64 public maxTokens;
    uint256 public pricePerToken;
    uint256 public minPricePerToken = 10000000000000000;

    bool public locked = false;
    SalesState public salesState = SalesState.Closed;

    bool public artistSet = false;
    bool public scriptSet = false;
    bool public salesStarted = false;

    string public baseURI;
    string public script;
    string public scriptType = "p5js";
    string public licenseType = "NFT License";

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI,
        uint64 _pricePerToken,
        uint64 _maxTokens
    ) ERC721(_tokenName, _tokenSymbol) {
        admins[msg.sender] = true;
        formaAddress = msg.sender;
        baseURI = _baseURI;
        require(_pricePerToken >= minPricePerToken, "pricePerToken too low");
        pricePerToken = _pricePerToken;
        maxTokens = _maxTokens;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins");
        _;
    }

    modifier onlyEditors() {
        require(admins[msg.sender] || msg.sender == artistAddress, "Only editors");
        _;
    }

    function addAdmin(address _address) public onlyOwner {
        admins[_address] = true;
    }

    function removeAdmin(address _address) public onlyOwner {
        require(_address != owner(), "Can't remove owner from admins");
        admins[_address] = false;
    }

    function addWhitelist(address[] memory _addresses, uint16 _presaleMints) public onlyAdmins {
        for (uint16 i = 0; i < _addresses.length; i++) {
            presaleMintsLeft[_addresses[i]] = _presaleMints;
        }
    }

    function removeWhitelist(address[] memory _addresses) public onlyAdmins {
        for (uint16 i = 0; i < _addresses.length; i++) {
            presaleMintsLeft[_addresses[i]] = 0;
        }
    }

    function updateArtist(address _artistAddress) public onlyAdmins {
        require(!locked, "Only unlocked");
        artistSet = true;
        artistAddress = _artistAddress;
    }

    function updateSecondPayoutAddress(address _secondPayoutAddress) public onlyEditors {
        secondPayoutAddress = _secondPayoutAddress;
    }

    function updateSecondPayoutSplit(uint256 _secondPayoutSplit) public onlyEditors {
        require(_secondPayoutSplit <= 100, "Can't have more than 100% paid out");
        secondPayoutSplit = _secondPayoutSplit;
    }

    function updateScript(string memory _script) public onlyEditors {
        require(!locked, "Only unlocked");
        scriptSet = true;
        script = _script;
    }

    function updateScriptType(string memory _scriptType) public onlyEditors {
        require(!locked, "Only unlocked");
        scriptType = _scriptType;
    }

    function updateMaxTokens(uint64 _maxTokens) public onlyAdmins {
        require(!locked, "Only unlocked");
        maxTokens = _maxTokens;
    }

    function updatePricePerToken(uint256 _pricePerToken) public onlyAdmins {
        require(
            !locked || (locked && msg.sender == owner()),
            "Only owner can update price when locked"
        );
        require(_pricePerToken >= minPricePerToken, "pricePerToken too low");
        pricePerToken = _pricePerToken;
    }

    function updateBaseURI(string memory _baseURI) public onlyAdmins {
        baseURI = _baseURI;
    }

    function updateFormaAddress(address _formaAddress) public onlyOwner {
        formaAddress = _formaAddress;
    }

    function lockProject() public onlyEditors {
        require(!locked, "Contract already locked");
        require(artistSet, "Can't lock contract without an artist set");
        require(scriptSet, "Can't lock contract without a script set");
        locked = true;
    }

    function unlockProject() public onlyEditors {
        require(locked, "Contract already unlocked");
        require(salesState == SalesState.Closed, "Can only unlock Contract in Closed state");
        require(!salesStarted, "Can't unlock contract after sales started");
        locked = false;
    }

    function updateState(SalesState _state) public onlyAdmins {
        require(locked, "Can only change state for locked project");
        salesState = _state;
    }

    function mintPresale() public payable virtual returns (uint256 _tokenId) {
        require(salesState >= SalesState.PreSale, "Drop must be on Presale or Active");
        require(msg.value >= pricePerToken, "Ether amount is under set price");
        require(freshTokensMinted < maxTokens, "Must not exceed max tokens");

        if (salesState == SalesState.PreSale) {
            require(
                presaleMintsLeft[msg.sender] >= 1,
                "Sender not approved for presale"
            );
            presaleMintsLeft[msg.sender] -= 1;
        }

        salesStarted = true;
        return _mintToken(msg.sender);
    }

    function mint() public payable virtual returns (uint256 _tokenId) {
        require(salesState == SalesState.Active, "Drop must be active");
        require(msg.value >= pricePerToken, "Ether amount is under set price");
        require(freshTokensMinted < maxTokens, "Must not exceed max tokens");

        salesStarted = true;
        return _mintToken(msg.sender);
    }

    function reserve(address _toAddress) public virtual onlyAdmins returns (uint256 _tokenId) {
        require(freshTokensMinted < maxTokens, "Must not exceed max tokens");

        uint256 tokenId = _mintToken(_toAddress);
        return tokenId;
    }

    function _mintToken(address _toAddress) internal virtual returns (uint256 _tokenId);

    function _splitFunds() internal {
        uint256 refund = msg.value - pricePerToken;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        uint256 formaAmount = (pricePerToken / 100) * formaPercentage;
        if (formaAmount > 0) {
            payable(formaAddress).transfer(formaAmount);
        }

        uint256 totalArtistPayout = (pricePerToken / 100) * artistPercentage;
        uint256 artistPayout = (totalArtistPayout / 100) * (100 - secondPayoutSplit);

        if (artistPayout > 0) {
            payable(artistAddress).transfer(artistPayout);
        }

        uint256 secondPayout = (totalArtistPayout / 100) * secondPayoutSplit;

        if (secondPayout > 0) {
            payable(secondPayoutAddress).transfer(secondPayout);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }
}
