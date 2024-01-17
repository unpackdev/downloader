// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

    error AccountNotInWhitelistOrAlreadyMint();
    error TokenIdExists();


contract NFT is ERC721, AccessControl {
    event CrossChain(address indexed from, bytes32 indexed h, bytes32 indexed f, uint256 tokenId);
    event Redeem(string from, address indexed to, uint256 indexed tokenId);

    using SafeMath for uint256;

    uint256 price = 0.01 ether;

    uint256 public teamMinted;
    uint256 public ogMinted;
    uint256 public wlMinted;

    bool public ogWhitelistMintEnabled = false;
    bool public whitelistMintEnabled = false;
    bool public publicMintEnabled = false;
    bool public crossChainEnabled = false;

    mapping(address => uint256) public teamClaimed;
    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public ogClaimed;
    mapping(address => uint256) public pubClaimed;

    bytes32 public wlRoot;
    bytes32 public ogRoot;
    bytes32 public bcRoot;

    uint256 _currentIndex;
    uint256 _burnCounter;
    string _baseTokenURI;

    uint256 MAX_SUPPLY = 2500;
    uint256 MAX_INDEX = 3000;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _currentIndex = _startTokenId();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(MINTER_ROLE, _msgSender());
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Roles: Caller does not have the MINTER role!");
        _;
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Roles:Caller does not have the ADMIN role!");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Common: Not approved nor owner");
        _;
    }

    function _reverse(bool state) internal pure returns (bool) {
        if (state) {
            return false;
        }
        return true;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure returns (uint256) {
        return 0;
    }

    function _totalMinted() internal view returns (uint256) {
    unchecked {
        return _currentIndex - _startTokenId();
    }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._afterTokenTransfer(from, to, tokenId);
        if (from == address(0)) {
            _currentIndex = _currentIndex.add(1);
        }

        if (to == address(0)) {
            _burnCounter = _burnCounter.add(1);
        }
    }

    function totalSupply() public view returns (uint256) {
    unchecked {
        return _currentIndex - _startTokenId() - _burnCounter;
    }
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function setBaseURI(string calldata newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function enable(uint256 typeId) public onlyOwner {
        if (typeId == 1) {
            publicMintEnabled = _reverse(publicMintEnabled);
        } else if (typeId == 2) {
            whitelistMintEnabled = _reverse(whitelistMintEnabled);
        } else if (typeId == 3) {
            ogWhitelistMintEnabled = _reverse(ogWhitelistMintEnabled);
        } else if (typeId == 4) {
            crossChainEnabled = _reverse(crossChainEnabled);
        }
    }

    function setRoot(uint256 typeId, bytes32 root) public onlyOwner {
        if (typeId == 1) {
            wlRoot = root;
        } else if (typeId == 2) {
            ogRoot = root;
        } else if (typeId == 3) {
            bcRoot = root;
        }
    }

    function _ensureMint(uint256 amount, uint256 p) internal view {
        require(amount > 0, "Invalid mint amount!");
        require(msg.value >= p * amount, "Insufficient funds!");
        require(_totalMinted().add(amount) <= MAX_SUPPLY, "Max supply exceeded!");
    }

    function _batchMint(address receiver, uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(receiver, _currentIndex);
        }
    }

    function teamMint(address receiver, uint256 amount) public onlyOwner {
        require(teamClaimed[receiver].add(amount) <= 10, "Address Mint Limited!");
        require(teamMinted.add(amount) <= 200, "Team Mint Total Limited!");
        teamClaimed[receiver] = teamClaimed[receiver].add(amount);
        _batchMint(receiver, amount);
    }

    function publicMint(uint256 amount) public payable {
        require(publicMintEnabled, "Mint closed!");
        require(pubClaimed[_msgSender()].add(amount) <= 10, "Address Mint Limited!");
        _ensureMint(amount, price);
        pubClaimed[_msgSender()] = pubClaimed[_msgSender()].add(amount);
        _batchMint(_msgSender(), amount);
    }

    function isBcn(bytes32[] calldata _proof, address bcn, address receiver) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(bcn));
        require(MerkleProof.verify(_proof, bcRoot, leaf));
        uint256 v = IERC721(bcn).balanceOf(receiver);
        if (v > 0) {
            return true;
        }
        return false;
    }

    function mintByBcn(bytes32[] calldata _proof, address bcn, address receiver, uint256 amount) public payable {
        require(whitelistMintEnabled, "Mint Closed!");
        require(whitelistClaimed[receiver].add(amount) <= 2, "Address Mint Limited!");
        bytes32 leaf = keccak256(abi.encodePacked(bcn));
        require(MerkleProof.verify(_proof, bcRoot, leaf));

        uint256 v = IERC721(bcn).balanceOf(receiver);
        require(v > 0, "ERC721W:not bcn family owner");

        _ensureMint(amount, 0);
        whitelistClaimed[receiver] = whitelistClaimed[receiver].add(amount);
        _batchMint(receiver, amount);
    }

    function wlMint(bytes32[] calldata _proof, uint256 amount) public payable {
        require(whitelistMintEnabled, "Mint Closed!");
        require(wlMinted.add(amount) <= 2000, "WL Mint Total Limited!");
        require(whitelistClaimed[_msgSender()].add(amount) <= 2, "Address Mint Limited!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, wlRoot, leaf));

        _ensureMint(amount, 0);
        whitelistClaimed[_msgSender()] = whitelistClaimed[_msgSender()].add(amount);
        _batchMint(_msgSender(), amount);
    }

    function ogMint(bytes32[] calldata _proof, uint256 amount) public payable {
        require(ogWhitelistMintEnabled, "Mint Closed!");
        require(ogMinted.add(amount) <= 300, "OG Mint Total Limited!");
        require(ogClaimed[_msgSender()].add(amount) <= 3, "Address Mint Limited!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, ogRoot, leaf));

        _ensureMint(amount, 0);
        ogClaimed[_msgSender()] = ogClaimed[_msgSender()].add(amount);
        _batchMint(_msgSender(), amount);
    }

    /**
    @notice Batch withdraw Token from solana to ethereum.
    */
    function withdraw(uint256[] calldata tokenIds, address[] calldata accounts, string[] calldata targets) public onlyMinter {
        require(crossChainEnabled, "Cross-chain closed!");

        for (uint256 i = 0; i < accounts.length; i++) {
            require(tokenIds[i] < MAX_INDEX, "Maximum tokenId exceeded!");

            if (exists(tokenIds[i])) revert TokenIdExists();
            _safeMint(accounts[i], tokenIds[i]);
            emit Redeem(targets[i], accounts[i], tokenIds[i]);
        }
    }

    function setRoleAdmin(bytes32 roleId, bytes32 adminRoleId) public onlyOwner {
        _setRoleAdmin(roleId, adminRoleId);
    }

    function crossChain(uint256 tokenId, bytes32 h, bytes32 f) public onlyApprovedOrOwner(tokenId) {
        require(crossChainEnabled, "Cross-chain Closed!");
        _burn(tokenId);
        emit CrossChain(_msgSender(), h, f, tokenId);
    }

    function withdraw() public onlyOwner {
        (bool success,) = payable(_msgSender()).call{value : address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool){
        return
        ERC721.supportsInterface(interfaceId) ||
        AccessControl.supportsInterface(interfaceId);
    }
}
