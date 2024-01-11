pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

contract InvestManJustForFun is ERC1155Supply, ERC1155Burnable, Ownable, Pausable, ReentrancyGuard {
    string public name;
    string public symbol;

    mapping(uint256 => uint256) public maxSupply;
    mapping(address => mapping(uint256 => uint256)) private _minted;

    uint256 public maxFreeMint = 1;
    uint256 public maxAllowlistMint = 20;
    uint256 public maxPublicMint = 20;

    uint256 public maxQuantityPublicMint = 20;

    bytes32 public freeMerkleRoot;
    bytes32 public allowlistMerkleRoot;

    uint256 public allowlistPrice = 0.13 ether;
    uint256 public publicPrice = 0.14 ether;

    enum Phase {
        DEV,
        FREE,
        ALLOWLIST,
        PUBLIC
    }

    struct PhaseConfig {
        uint256 startTime;
        uint256 duration;
    }

    mapping(Phase => PhaseConfig) public phases;

    constructor(string memory _baseUri, bytes32 _freeMerkleRoot, bytes32 _allowlistMerkleRoot) ERC1155(_baseUri) {
        name = "InvestMan_JustForFun";
        symbol = "JFF";

        createToken(1, 1000);

        freeMerkleRoot = _freeMerkleRoot;
        allowlistMerkleRoot = _allowlistMerkleRoot;

        phases[Phase.DEV] = PhaseConfig(1650186000, 21600);
        phases[Phase.FREE] = PhaseConfig(1650186000, 5400);
        phases[Phase.ALLOWLIST] = PhaseConfig(1650191400, 9000);
        phases[Phase.PUBLIC] = PhaseConfig(1650200400, 7200);
    }

    // mint functions
    function _isMintable(uint256 id, uint256 quantity, Phase phase, uint256 price, uint256 limit) internal {
        // solhint-disable not-rely-on-time
        require(block.timestamp >= phases[phase].startTime && block.timestamp <= phases[phase].startTime + phases[phase].duration,  "Minting is closed");
        require(maxSupply[id] > 0, "Token is not defined");
        require(totalSupply(id) + quantity <= maxSupply[id], "Reached max supply");
        require(_minted[msg.sender][id] + quantity <= limit, "Exceed mint limit");
        require(price * quantity == msg.value, "Invalid amount");
    }

    function devMint(uint256 id, uint256 quantity) external onlyOwner {
        _isMintable(id, quantity, Phase.DEV, 0, maxSupply[id]);

        _mint(owner(), id, quantity, "");
    }

    function freeMint(uint256 id, uint256 quantity, bytes32[] calldata _merkleProof) external whenNotPaused {
        _isMintable(id, quantity, Phase.FREE, 0, maxFreeMint);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf), "Invalid Proof");

        _mint(msg.sender, id, quantity, "");
    }

    function allowlistMint(uint256 id, uint256 quantity, bytes32[] calldata _merkleProof) external payable whenNotPaused {
        _isMintable(id, quantity, Phase.ALLOWLIST, allowlistPrice, maxAllowlistMint);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf), "Invalid Proof");

        _mint(msg.sender, id, quantity, "");
    }

    function publicMint(uint256 id, uint256 quantity) external payable whenNotPaused {
        require(quantity <= maxQuantityPublicMint, "Reached max quantity per tx");
        _isMintable(id, quantity, Phase.PUBLIC, publicPrice, maxPublicMint);

        _mint(msg.sender, id, quantity, "");
    }

    // admin functions
    function withdraw() external onlyOwner nonReentrant {
        // solhint-disable avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setURI(string memory _newURI) external onlyOwner {
        _setURI(_newURI);
    }

     function setFreeMerkleRoot(bytes32 _freeMerkleRoot) external onlyOwner {
        freeMerkleRoot = _freeMerkleRoot;
    }

    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function setPhases(Phase[] calldata _phases, uint256[] calldata _startTime, uint256[] calldata _duration) external onlyOwner {
        require(_phases.length == _startTime.length || _phases.length == _duration.length, "Invalid length");
        for (uint256 i = 0; i < _phases.length; i++) {
            phases[_phases[i]].startTime = _startTime[i];
            phases[_phases[i]].duration = _duration[i];
        }
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setAllowlistPrice(uint256 _allowlistPrice) external onlyOwner {
        allowlistPrice = _allowlistPrice;
    }

    function setMaxFreeMint(uint256 _maxFreeMint) external onlyOwner {
        maxFreeMint = _maxFreeMint;
    }

    function setMaxAllowlistMint(uint256 _maxAllowlistMint) external onlyOwner {
        maxAllowlistMint = _maxAllowlistMint;
    }

    function setMaxPublicMint(uint256 _maxPublicMint) external onlyOwner {
        maxPublicMint = _maxPublicMint;
    }

    function createToken(uint256 id, uint256 _totalSupply) public onlyOwner {
        require(!exists(id), "Token is existed");
        maxSupply[id] = _totalSupply;
    }
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _minted[to][ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                maxSupply[ids[i]] -= amounts[i];
            }
        }
    }
}
