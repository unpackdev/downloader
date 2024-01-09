// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract FudgyPenguins is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _publicTokenTracker;

    uint256 public constant MAX_ELEMENTS = 8888;
    uint256 public maxPublic = 7777;
    uint256 public constant MAX_BY_MINT = 20;
    string public baseTokenURI;
    
    IERC721 internal constant OG_PUDGY_CONTRACT = IERC721(0xBd3531dA5CF5857e7CfAA92426877b022e612cf8);
    uint256[] public fudgiesThatAreOG;
    uint256[] public OGPudgiesReserved;
    mapping(uint256 => bool) internal OGAlreadyClaimed;
    mapping(address => bool) public whitelistClaimed;
    
    bytes32 public merkleRoot;
    

    event CreatePenguin(uint256 indexed id);
    constructor(string memory baseURI) ERC721("FudgyPenguins", "FPG") {
        setBaseURI(baseURI);
        pause(true);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }
    modifier whitelisted(bytes32[] calldata _merkleProof) {
        require(!whitelistClaimed[msg.sender], "Address has already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Sorry, you are not whitelisted");
        _;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }
    function _totalPublicSupply() internal view returns (uint256) {
        return _publicTokenTracker.current();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    function whitelistMint(address _to, bytes32[] calldata _merkleProof) public whitelisted(_merkleProof) saleIsOpen {
        uint256 total = _totalSupply();
        require(total < MAX_ELEMENTS, "Max limit");
        whitelistClaimed[msg.sender] = true;
        _mintAnElement(_to);
    }
    function whitelistMintPudgy(address _to, bytes32[] calldata _merkleProof, uint256 _specificPudgy) public whitelisted(_merkleProof) saleIsOpen {
        uint256 total = _totalSupply();
        require(total < MAX_ELEMENTS, "Max limit");
        require(msg.sender == OG_PUDGY_CONTRACT.ownerOf(_specificPudgy), "You do not own the original Pudgy you are trying to mint");
        require(!OGAlreadyClaimed[_specificPudgy], "This pudgy was already claimed");
        whitelistClaimed[msg.sender] = true;
        
        _mintASpecificFudgy(_to, _specificPudgy);
    }
    
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        uint256 public_total = _totalPublicSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(public_total + _count <= maxPublic, "Max limit");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _publicTokenTracker.increment();
            _mintAnElement(_to);
        }
    }
    function setMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        merkleRoot = newMerkleRoot;
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreatePenguin(id);
    }
    function mintMyPudgies(address _to, uint256[] memory _pudgies) public payable saleIsOpen {
        uint256 total = _totalSupply();
        uint256 public_total = _totalPublicSupply();
        uint256 count = _pudgies.length;
        require(total + count <= MAX_ELEMENTS, "Max limit");
        require(public_total + count <= maxPublic, "Max limit");
        require(count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= (1 * 10**16 * count), "Value below price");

        for (uint256 i = 0; i < count; i++){
            require(msg.sender == OG_PUDGY_CONTRACT.ownerOf(_pudgies[i]), "You do not own the original Pudgy you are trying to mint");
            require(!OGAlreadyClaimed[_pudgies[i]], "This pudgy was already claimed");
            _publicTokenTracker.increment();
            _mintASpecificFudgy(_to, _pudgies[i]);
        }
    }
    function _mintASpecificFudgy(address _to, uint256 _og) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        fudgiesThatAreOG.push(id);
        OGPudgiesReserved.push(_og);
        OGAlreadyClaimed[_og] = true;
        _safeMint(_to, id);
        emit CreatePenguin(id);
    }
    function price(uint256 _count) public view returns (uint256) {
        if (_totalPublicSupply() < 1111){
            return 1 * 10**16 * _count;
        } else if (_totalPublicSupply() < 3333) {
            return 2 * 10**16 * _count;
        } else {
            return 3 * 10**16 * _count;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMaxPublic(uint256 _maxPublic) public onlyOwner {
        maxPublic = _maxPublic;
    }

    function tokensOwnedByAddress(address _owner) external view returns (uint256[] memory) {
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

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
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
