// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";


contract Abominables is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {


    address[] private teamWallets = [
        0x7724d64e062f506fb417284Cbef86bd5Bd7Cc9AD,
        0x704c7dA8D117Ff5cf3C3268EeCaB6A80188B2AAc
    ];

    uint256[] private teamShares = [80,20];


    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    mapping(address => uint256) private whitelist;

    mapping(address => uint256) private numMintedAddr;

    uint256 public MAX_ELEMENTS = 12500;
    uint256 public constant PRICE = 40 * 10**15;
    uint256 public constant MAX_BY_MINT = 20;
    uint256 public constant MAX_PER_WALLET = 20;
    string public ABOMINABLES_PROVENANCE = "";
    string public baseTokenURI;
    // bool public canChangeSupply = true;
    bool public presaleOpen = false;
    bool public mainSaleOpen = false;
    uint256 private presaleMaxPerMint = 5;

    // Reserve 100 Abominables for Team
    uint public abominablesReserveMax = 100;
    uint public preMintedAbominables = 0;

    event CreateAbominables(uint256 indexed id);

    constructor(string memory baseURI) ERC721("Abominables", "ABLES") {
        setBaseURI(baseURI); // use original sketch as baseURI egg
        pause(true); // contract starts paused
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    modifier onlyOwnerOrTeam() {
        require(
            teamWallets[0] == msg.sender || teamWallets[1] == msg.sender || owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        require(mainSaleOpen, "Public sale hasn't started!");
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");
        require((numMintedAddr[_to] + _count) <= MAX_PER_WALLET, "Exceeds max wallet");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }

        numMintedAddr[_to] = numMintedAddr[_to] + _count;
    }

    function mintPresale(address _to, uint256 _count) public payable {
        require(presaleOpen);
        require(_count <= whitelist[msg.sender]);
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= (_count * PRICE), "Value below price");
         require((numMintedAddr[_to] + _count) <= MAX_PER_WALLET, "Exceeds max wallet");

        for (uint256 i = 0; i < _count; i++) {
          _mintAnElement(_to);
          
        }
        numMintedAddr[_to] = numMintedAddr[_to] + _count;
        whitelist[msg.sender] = whitelist[msg.sender] - _count;
    }

    // Minting by team
    function preMintAbominable(address[] memory recipients) external onlyOwnerOrTeam {

        uint256 totalRecipients = recipients.length;
        uint256 total = _totalSupply();

        require(total + totalRecipients <= MAX_ELEMENTS, "Max limit");

        require(
            totalRecipients > 0,
            "Number of recipients must be greater than 0"
        );

        require(
            preMintedAbominables + totalRecipients <= abominablesReserveMax,
            "Exceeds max pre-mint Abominables"
        );

        for (uint256 i = 0; i < totalRecipients; i++) {
            address to = recipients[i];
            require(to != address(0), "receiver can not be empty address");
            _mintAnElement(to);
        }

        preMintedAbominables += totalRecipients;
    }

    function togglePresaleMint() public onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function enableMainSale() public onlyOwner {
        mainSaleOpen = true;
    }

    // adds to whitelist with specified amounts
    function addToWhitelistAmounts(address[] memory _listToAdd, uint256[] memory _amountPerAddress) public onlyOwner {
        uint256 totalAddresses = _listToAdd.length;
        uint256 totalAmounts = _amountPerAddress.length;

        require(totalAddresses == totalAmounts, "Amounts of entered items do not match");

        for (uint256 i = 0; i < totalAddresses; i++) {
          whitelist[_listToAdd[i]] = _amountPerAddress[i];
        }
    }

    function saleIsActive() public view returns (bool) {
        if(paused()) {
            return false;
        } else {
            return true;
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateAbominables(id);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        ABOMINABLES_PROVENANCE = provenanceHash;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _widthdraw(teamWallets[0], balance.mul(teamShares[0]).div(100));
        _widthdraw(teamWallets[1], address(this).balance);
     }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAllBackup() public payable onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdrawBackup(teamWallets[0], balance.mul(teamShares[0]).div(100));
        _withdrawBackup(teamWallets[1], address(this).balance);
    }

    function _withdrawBackup(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}