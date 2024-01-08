// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract LosPurples is ERC721Enumerable, Ownable, ERC721Pausable {
    using Strings for uint256;

    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant MAX_SUPPLY = 9991;
    uint256 public constant PRESALE_ITEMS_LIMIT = 1500;
    uint256 public constant MINT_LIMIT = 5;
    uint256 public constant PRESALE_MINT_LIMIT = 2;

    uint256 private _currentTokenId = 0;
    uint256 public presaleAt;
    uint256 public saleAt;
    string public baseTokenURI;

    mapping(address => bool) private _presaleList;
    mapping(address => uint256) private _presaleListClaimed;

    event SetBaseURI(string baseURI);

    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI, uint256 _presaleTimestamp, uint256 _saleTimestamp) ERC721(_name, _symbol) {
        _pause();
        setBaseURI(_baseTokenURI);
        setDates(_presaleTimestamp, _saleTimestamp);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;

        emit SetBaseURI(_baseTokenURI);
    }

    function setPresaleDate(uint256 _timestamp) public onlyOwner {
        presaleAt = _timestamp;
    }

    function setSaleDate(uint256 _timestamp) public onlyOwner {
        saleAt = _timestamp;
    }

    function setDates(uint256 _presaleTimestamp, uint256 _saleTimestamp) public onlyOwner {
        presaleAt = _presaleTimestamp;
        saleAt = _saleTimestamp;
    }

    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = true;
        }
    }

    function onPresaleList(address addr) external view returns (bool) {
        return _presaleList[addr];
    }

    function removeFromPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = false;
        }
    }

    function mintReserve(address _to, uint256 _amount) public onlyOwner {
        uint256 total = totalSupply();
        require(total <= MAX_SUPPLY, "Sale ended");
        require(total + _amount <= MAX_SUPPLY, string(abi.encodePacked('Max limit, there are only ', (MAX_SUPPLY - total).toString(), ' tokens left')));

        for (uint256 i = 0; i < _amount; i++) {
            _mintToken(_to);
        }
    }

    function mint (address _to, uint256 _amount) public payable {
        uint256 total = totalSupply();
        require(total <= MAX_SUPPLY, "Sale ended");
        require(_amount <= MINT_LIMIT, "Exceeds number");
        require(total + _amount <= MAX_SUPPLY, string(abi.encodePacked('Max limit, there are only ', (MAX_SUPPLY - total).toString(), ' tokens left')));
        require(block.timestamp >= saleAt, "Sale has not yet started");
        require(msg.value >= PRICE * _amount, "Value below price");

        for (uint256 i = 0; i < _amount; i++) {
            _mintToken(_to);
        }
    }

    function presaleMint(address _to, uint256 _amount) public payable {
        uint256 total = totalSupply();
        require(total + _amount <= MAX_SUPPLY, string(abi.encodePacked('Max limit, there are only ', (MAX_SUPPLY - total).toString(), ' tokens left')));
        require(total <= PRESALE_ITEMS_LIMIT, "Presale ended");
        require(block.timestamp >= presaleAt, "Presale has not yet started");
        require(_presaleList[_to], 'You are not on the Presale List');
        require(_amount <= PRESALE_MINT_LIMIT, "Exceeds number");
        require(_presaleListClaimed[_to] + _amount <= PRESALE_MINT_LIMIT, string(abi.encodePacked('You can mint only ', (PRESALE_MINT_LIMIT - _presaleListClaimed[_to]).toString(), ' presale tokens')));
        require(msg.value >= PRICE * _amount, "Value below price");

        for (uint256 i = 0; i < _amount; i++) {
            _mintToken(_to);
        }

        _presaleListClaimed[_to] += _amount;
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function _mintToken(address _to) private {
        _incrementTokenId();

        uint256 id = _currentTokenId;
        _safeMint(_to, id);
    }

    function withdraw() public onlyOwner {
        withdraw(_msgSender());
    }

    function withdraw(address _to) public onlyOwner {
        require(_to != address(0), "Can't transfer to the null address");

        uint256 balance = address(this).balance;
        require(balance > 0, "Empty balance");

        _withdraw(_to, balance);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Can't transfer to the null address");
        require(_amount > 0, "Amount can't be null");

        uint256 balance = address(this).balance;
        require(balance >= _amount, "Insufficient funds");

        _withdraw(_to, _amount);
    }

    function _withdraw(address _to, uint256 _amount) private {
        (bool success,) = _to.call{value : _amount}("");
        require(success, "Transfer failed");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
