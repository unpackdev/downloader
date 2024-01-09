// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract NFT is Ownable, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {
    using Counters for Counters.Counter;
    using Address for address;
    using SafeMath for uint256;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    string private _teaserURI;

    uint256 private _price = 100000000000000000;
    uint256 private _available = 100000000;
    address private _treasuryWallet;
    bool private _reveal = false;

    constructor(
        string memory name,
        string memory symbol,
        string memory teaserURI,
        address treasuryWallet
    ) ERC721(name, symbol) {
        _teaserURI = teaserURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _treasuryWallet = treasuryWallet;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return _reveal == true ? bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '' : _teaserURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _reveal == true ? _baseTokenURI : _teaserURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function available() public view returns (uint256) {
        return _available;
    }

    function setAvailable(uint256 newAvailable) public onlyOwner {
        _available = newAvailable;
    }

    function revealed() public view returns (bool) {
        return _reveal;
    }

    function setReveal(bool reveal) public onlyOwner {
        _reveal = reveal;
    }

    function setTreasury(address treasuryWallet) public onlyOwner {
        _treasuryWallet = treasuryWallet;
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), 'ERC721PresetMinterPauserAutoId: must have pauser role to pause');
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), 'ERC721PresetMinterPauserAutoId: must have pauser role to unpause');
        _unpause();
    }

    function buyBatch(uint256 amount) external payable {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < amount; i++) {
            totalPrice = totalPrice.add(_price);
        }
        require(msg.value >= totalPrice, 'Incorrect payment.');

        for (uint256 i = 0; i < amount; i++) {
            require(_available > 0, 'Sold out');
            _mint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
            _available = _available.sub(1);
        }
        payable(_treasuryWallet).transfer(msg.value);
    }

    function buy() external payable {
        require(msg.value >= _price, 'Incorrect payment.');
        require(_available > 0, 'Sold out');

        _mint(_msgSender(), _tokenIdTracker.current());
        _tokenIdTracker.increment();
        _available = _available.sub(1);
        payable(_treasuryWallet).transfer(msg.value);
    }

    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), 'ERC721PresetMinterPauserAutoId: must have minter role to mint');
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
