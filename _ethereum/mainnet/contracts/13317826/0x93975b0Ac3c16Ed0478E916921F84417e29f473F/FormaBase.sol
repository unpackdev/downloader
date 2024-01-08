// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

abstract contract FormaBase is ERC721Enumerable, Ownable {
    event Mint(address indexed _to, uint256 indexed _tokenId);

    mapping(address => bool) public admins;

    address public formaAddress;
    uint256 public formaPercentage = 10;

    address public artistAddress;
    uint256 public artistPercentage = 90;

    address public secondPayoutAddress;
    uint256 public secondPayoutSplit = 0;

    uint256 public maxTokens;
    uint256 public pricePerToken;
    uint256 public minPricePerToken = 10000000000000000;

    // States
    bool public locked = false;
    bool public active = false;

    // Flags
    bool public artistSet = false;
    bool public salesStarted = false;

    string public baseURI;
    string public script;
    string public scriptType = "p5js";

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
        script = _script;
    }

    function updateScriptType(string memory _scriptType) public onlyEditors {
        require(!locked, "Only unlocked");
        scriptType = _scriptType;
    }

    function updateMaxTokens(uint256 _maxTokens) public onlyAdmins {
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

    function toggleLocked() public onlyEditors {
        require(!active, "Can only toggle lock before project is active");
        require(!locked || (locked && !salesStarted), "Can't unlock contract after sales started");
        require(locked || (!locked && artistSet), "Can't lock contract without an artist set");
        locked = !locked;
    }

    function toggleActive() public onlyAdmins {
        require(locked, "Can only toggle active for locked project");
        active = !active;
    }

    function mint() public payable virtual returns (uint256 _tokenId);

    function reserve(address _toAddress) public virtual returns (uint256 _tokenId);

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
