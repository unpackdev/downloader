// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

interface PairedWorldRDFInterface {
    
    function addSPO(uint256 tokenId, uint8 predicateIdx, uint8 objectIdx, string memory object) external;
    function removeRDF(uint256 tokenId) external;
    function rdfOf(uint256 tokenId) external view returns (string memory);

}

interface TicketAwardInterface {
    
    function calculateAward(uint256 amount, uint8 level) external returns (uint256);
    
}


contract SoulBoundToken is ERC1155, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    string public constant name = "SOUL";
    string public constant symbol = "SOUL";

    Counters.Counter public totalSupply;
    mapping (uint8 => string) public _tokenURIs;

    mapping (uint256 => address) public _ownerOf;
    mapping (address => uint256) public _ownedToken;

    mapping (uint256 => uint8) public _tokenLevels;
    address public _admin;
    address public _burner;
    PairedWorldRDFInterface public _rdfContract;
    TicketAwardInterface public _ticketAwardFunction;
    
    bytes32 public _whitelist;

    bool public _useRdfMetadatURI = false;
    string public _baseURI;

    event WhitelistUpdated(bytes32 merkle_root);
    event LevelChanged(uint256 indexed tokenId, uint256 level);

    constructor() ERC1155("SOUL") {
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin || msg.sender == owner(), "Only Admin");
        _;
    }

    modifier onlyBurner() {
        require(msg.sender == _burner || msg.sender == owner(), "Only Burner");
        _;
    }

    // MARK: - Only Owner
    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function setBurner(address burner) external onlyOwner {
        _burner = burner;
    }

    function setRdfContract(address rdf) external onlyOwner {
        _rdfContract = PairedWorldRDFInterface(rdf);
    }

    function setTicketAwardContract(address ticketAward) external onlyOwner {
        _ticketAwardFunction = TicketAwardInterface(ticketAward);
    }

    function setTokenURI(uint8 level, string memory _tokenURI) external onlyOwner {
        _tokenURIs[level] = _tokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURI = baseURI;
    }

    // MARK: - Only Burner
    function burn(uint256 tokenId, uint256 amount) external onlyBurner {
        uint256 ownerBalance = balanceOf(_ownerOf[tokenId], tokenId);
        _burn(_ownerOf[tokenId], tokenId, amount);
        if (amount == ownerBalance) {
            delete _tokenLevels[tokenId];
            delete _ownedToken[_ownerOf[tokenId]];
            delete _ownerOf[tokenId];
            _rdfContract.removeRDF(tokenId);
        } 
    }
        

    // MARK: - Only Admin
    function updateWhitelist(bytes32 merkle_root) external onlyAdmin {
        _whitelist = merkle_root;
        emit WhitelistUpdated(merkle_root);
    }

    // MARK: - Public 
    function claim(bytes32[] memory proof, uint256 amount, uint8 level) external nonReentrant {
        require(whitelisted(proof, msg.sender, amount, level) > balanceOf(msg.sender, _ownedToken[msg.sender]), "You are not whitelisted to mint tokens.");

        uint256 tokenId = _ownedToken[msg.sender];
        if (tokenId == 0) {
            totalSupply.increment();
            tokenId = totalSupply.current();
            _ownerOf[tokenId] = msg.sender;
            _ownedToken[msg.sender] = tokenId;
            _rdfContract.addSPO(tokenId, 1, 1, Strings.toHexString(msg.sender));
        } 
        
        uint256 delta = amount - balanceOf(msg.sender, _ownedToken[msg.sender]);
        _tokenLevels[tokenId] = level;
        _mint(msg.sender, tokenId, delta, "");
    }

    function changeLevel(uint256 _tokenId, uint8 _toLevel, bytes32[] memory proof) external nonReentrant {
        require(whitelisted(proof, msg.sender, balanceOf(msg.sender, _ownedToken[msg.sender]), _toLevel) > 0, "trying to change to invalid level");
        _tokenLevels[_tokenId] = _toLevel;
        emit LevelChanged(_tokenId, _toLevel);
    }

    function ownerTickets(
        address account, 
        bytes32[] memory proof, 
        uint256 amount, 
        uint8 level
        ) external returns (uint256) {
        uint256 tokenId = _ownedToken[account];
        require(whitelisted(proof, account, amount, level) > 0, "You are not whitelisted to mint tokens.");
        _tokenLevels[tokenId] = level;

        return _ticketAwardFunction.calculateAward(amount, level);
    }

    function ownerOf(uint256 tokenID) public view returns (address) {
        return _ownerOf[tokenID];
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        if (_useRdfMetadatURI) {
            return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
        }
        return _tokenURIs[_tokenLevels[tokenId]];
    }

    // MARK: - Merkle Proofs
    function whitelisted(
        bytes32[] memory proof, 
        address account, 
        uint256 amount, 
        uint256 level
        ) public view returns (uint256) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount, level))));
        uint256 val = MerkleProof.verify(proof, _whitelist, leaf) ? amount : 0;

        return val;
    }
    
    // MARK: - RDF
    function addSPO(uint256 tokenId, uint8 predicateIdx, uint8 objectIdx, string memory object) external {
        require(msg.sender == _ownerOf[tokenId], "Only owner can add RDF");
        _rdfContract.addSPO(tokenId, predicateIdx, objectIdx, object);
    }

    function rdfOf(uint256 tokenId) external view returns (string memory) {
        return _rdfContract.rdfOf(tokenId);
    }

    // MARK: - Private 
    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
        ) internal override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require(from == address(0) || to == address(0), "This a Soulbound token. It cannot be transferred.");
    }

}