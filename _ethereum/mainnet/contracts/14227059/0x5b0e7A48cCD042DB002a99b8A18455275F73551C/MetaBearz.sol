// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ERC721Pausable.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";

contract MetaBearz is ERC721, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;

    uint256 private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 6777;
    uint256 public constant GENESIS_PRICE = 0.09 ether;
    uint256 public constant OG_PRICE = 0.14 ether;
    uint256 public constant PRICE = 0.16 ether;
    uint256 public constant MAX_BY_MINT = 3;
    uint256 public constant genesisMaxMint = 2;
    uint256 public constant ogMaxMint = 3;
    uint256 public constant maxMintTotal = 6;
    
    string public baseTokenURI;

    address public constant creatorAddress = 0xbe21Fc6FB38c22f76E1425cA7a3Aa32d71a1c37c;
    address public constant devAddress = 0x1df6BE18f999504156D40ec8c058e1d4A54ff04D;

    bytes32 public tierOneMerkleRoot;
    bytes32 public tierTwoMerkleRoot;

    mapping(address => uint256) public tokensClaimed;

    bool public publicSaleOpen;

    event CreateItem(uint256 indexed id);
    constructor()
    ERC721("Meta Bearz Syndicate", "BEAR") 
    {
        pause(true);
    }

    modifier saleIsOpen {
        require(_tokenIdTracker <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    modifier noContract() {
        address account = msg.sender;
        require(account == tx.origin, "Caller is a contract");
        require(account.code.length == 0, "Caller is a contract");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker;
    }

    function setPublicSale(bool val) public onlyOwner {
        publicSaleOpen = val;
    }

    function mint(uint256 _count) public payable saleIsOpen noContract {
        uint256 total = totalSupply();
        require(publicSaleOpen, "Public sale not open yet");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(tokensClaimed[msg.sender] + _count <= maxMintTotal, "You have already minted the max amount.");
        require(msg.value == PRICE * _count, "Value is over or under price.");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    function presaleMint(uint256 _count, bytes32[] calldata _proof, uint256 _tier) public payable saleIsOpen noContract {
        if (_tier == 1) {
            require(msg.value == GENESIS_PRICE * _count, "Value is over or under price.");   
        } else if (_tier == 2) {
            require(msg.value == OG_PRICE * _count, "Value is over or under price.");
        } else {
            revert('Invalid tier');
        }
        require(verifySender(_proof, _tier), "Sender is not whitelisted");
        require(canMintPresaleAmount(_count, _tier), "Sender max presale mint amount already met");

        tokensClaimed[msg.sender] += _count;
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    function ownerMint(uint256 _count) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Sale end");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }

    }

    function _mintAnElement(address _to) private {
        uint id = totalSupply();
        _tokenIdTracker += 1;
        _mint(_to, id);
        emit CreateItem(id);
    }

    function canMintPresaleAmount(uint256 _count, uint256 _tier) public view returns (bool) {
        uint256 maxMintAmount;

        if (_tier == 1) {
            maxMintAmount = genesisMaxMint;
        } else if (_tier == 2) {
            maxMintAmount = ogMaxMint;
        }

        return tokensClaimed[msg.sender] + _count <= maxMintAmount;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot, uint256 _tier) external onlyOwner {
        require(_tierExists(_tier), "Tier does not exist");

        if (_tier == 1) {
            tierOneMerkleRoot = _merkleRoot;
        } else if (_tier == 2) {
            tierTwoMerkleRoot = _merkleRoot;
        }
    }

    function _tierExists(uint256 _tier) private pure returns (bool) {
        return _tier <= 3;
    }

    function verifySender(bytes32[] calldata proof, uint256 _tier) public view returns (bool) {
        return _verify(proof, _hash(msg.sender), _tier);
    }

    function _verify(bytes32[] calldata proof, bytes32 addressHash, uint256 _tier) internal view returns (bool) {
        bytes32 whitelistMerkleRoot;

        if (_tier == 1) {
            whitelistMerkleRoot = tierOneMerkleRoot;
        } else if (_tier == 2) {
            whitelistMerkleRoot = tierTwoMerkleRoot;
        }

        return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);
    }

    function _hash(address _address) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 creatorShare = balance.mul(80).div(100);
        uint256 devShare = balance.mul(20).div(100);
        require(balance > 0);
        _withdraw(creatorAddress, creatorShare);
        _withdraw(devAddress, devShare);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}