// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract KidsOfWar is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string public name;
    string public symbol;

    bool public isActive = true;
    bool public isRevealed = false;

    uint256 public price = 0.05 ether;
    uint256 public artworks = 200;
    uint256 public maxSupply = artworks * 50;
    uint256 public maxPerTransaction = 50;

    string private _uri = "";
    string private suffix = ".json";

    string private hiddenUri = "ipfs://QmWCXKMYAvLieiJTPNHrfzrFnWJZYgHvcVDDbZrN4F43LP/hidden.json";

    Counters.Counter private _counter;

    constructor() ERC1155(_uri) {
        name = "Kids of War";
        symbol = "KOW";
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_msgSender() == tx.origin, "You cannot mint from a smart contract");
        require(_mintAmount > 0 && _mintAmount <= maxPerTransaction, "Invalid mint amount!");
        require(_counter.current() + _mintAmount <= maxSupply, "Max supply exceeded!");

        _;
    }

    function mint(uint256 _amount) public payable nonReentrant mintCompliance(_amount) {
        require(isActive, "Minting is closed");

        require(msg.value >= price * _amount, "Not enough eth");

        _mintLoop(_msgSender(), _amount);
    }

    function mintForAddress(address _receiver, uint256 _amount) public onlyOwner nonReentrant mintCompliance(_amount) {
        _mintLoop(_receiver, _amount);
    }

    function _mintLoop(address _receiver, uint256 _amount) internal {
        for (uint i = 0; i < _amount; ++i) {
            uint256 tokenId = (_counter.current() % artworks) + 1;
            _counter.increment();
            _mint(_receiver, tokenId, 1, "");
        }
    }

    // Getters
    function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
        if (!isRevealed) {
            return hiddenUri;
        }

        return string(abi.encodePacked(super.uri(_id), _id.toString(), suffix));
    }

    function totalSupply() public view returns (uint256) {
        return _counter.current();
    }

    // Setters
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function toggleActive() external onlyOwner {
        isActive = !isActive;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function setURI(string memory newUri, string memory _suffix) public onlyOwner {
        _setURI(newUri);
        suffix = _suffix;
    }

    function setHiddenURI(string memory newHiddenUri) public onlyOwner {
        hiddenUri = newHiddenUri;
    }

    function setArtworks(uint256 _artworks) public onlyOwner {
        artworks = _artworks;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) public onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    // Withdraw
    function withdraw(address payable withdrawAddress) external payable nonReentrant onlyOwner {
        require(withdrawAddress != address(0), "Withdraw address cannot be zero");
        require(address(this).balance >= 0, "Not enough eth");
        payable(withdrawAddress).transfer(address(this).balance);
    }
}
