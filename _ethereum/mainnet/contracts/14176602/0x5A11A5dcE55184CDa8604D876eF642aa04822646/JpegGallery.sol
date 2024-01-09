// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract JpegGallery is EIP712, ERC721Enumerable, ERC721Burnable, ERC721Pausable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    // Constants
    uint256 public constant MAX_SUPPLY = 6969;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant PRICE = 0.069 ether;

    // Variables
    bool public whitelistIsOpen = false;
    bool public saleIsOpen = false;

    string private tokenBaseURI = '';
    mapping(address => uint8) private allowList;

    // Events
    event SetBaseURI(string indexed _baseURI);
    event CreateJpeg(uint256 indexed id);

    constructor(string memory name, string memory symbol, string memory version, string memory baseURI)
    ERC721(name, symbol) 
    EIP712(name, version) 
    {
        setBaseURI(baseURI);
        pause(true);
        emit SetBaseURI(baseURI);
    }

    function mint(address to, uint256 amount) external payable {
        uint256 total = totalSupply();
        require(saleIsOpen, 'Sale is not open');
        require(total < MAX_SUPPLY, 'Max supply exceeded');
        require(total + amount <= MAX_SUPPLY, 'Max supply exceeded');
        require(amount > 0, 'Amount must be greater than 0');
        require(amount <= PURCHASE_LIMIT, 'Max purchase limit exceeded');
        require(msg.value >= PRICE.mul(amount), 'Incorrect ether value sent');

        for (uint256 i; i < amount; i++) {
            uint id = totalSupply();
            _safeMint(to, id);
            emit CreateJpeg(id);
        }
    }

    function whitelistMint(uint8 amount) external payable {
        uint256 total = totalSupply();
        require(whitelistIsOpen, 'Whitelist is not open');
        require(total < MAX_SUPPLY, 'Max supply exceeded');
        require(total + amount <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(amount > 0, 'Amount must be greater than 0');
        require(amount <= allowList[_msgSender()], "Whitelist purchase limit exceeded");
        require(msg.value >= PRICE.mul(amount), 'Incorrect ether value sent');

        allowList[_msgSender()] -= amount;
        for (uint256 i; i < amount; i++) {
            uint id = totalSupply();
            _safeMint(_msgSender(), id);
            emit CreateJpeg(id);
        }
    }

    function setWhitelist(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function setWhitelistState(bool isOpen) external onlyOwner {
        whitelistIsOpen = isOpen;
    }

    function setSaleState(bool isOpen) external onlyOwner {
        saleIsOpen = isOpen;
    }

    function gift(address[] calldata to) external onlyOwner {
        uint256 total = totalSupply();
        require(total < MAX_SUPPLY, 'Max supply exceeded');
        require(total + to.length <= MAX_SUPPLY,'Max supply exceeded');

        for(uint256 i; i < to.length; i++) {
            uint id = totalSupply();
            _safeMint(to[i], id);
            emit CreateJpeg(id);
        }
    }

    function pause(bool pauseContract) public onlyOwner {
        pauseContract ? _pause() : _unpause();
    }

    function withdrawAll() external payable onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0);
        (bool success, ) = _msgSender().call{value: amount}('');
        require(success, 'Transfer failed.');
    }

    function walletOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return tokenBaseURI;
    }

    function setBaseURI(string memory URI) public onlyOwner {
        tokenBaseURI = URI;
        emit SetBaseURI(tokenBaseURI);
    }

    function _hash(address account, string memory name) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address account,string name)"),
            account,
            keccak256(bytes(name))
        )));
    }

    function verify(address account, uint256 id, string calldata name, bytes calldata signature) external view returns (bool) {
        address _owner = ECDSA.recover(_hash(account, name), signature);
        return (_owner == account) && (ownerOf(id) == _owner);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}