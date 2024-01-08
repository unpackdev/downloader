// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./ERC721Burnable.sol";

contract CryptoButlers is ERC721, AccessControl, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string  private _defaultURI;
    bytes32 private _merkleRoot;
    uint256 private _supply;
    uint256 private _maxSupply = 555; //TBD
    uint256 private _ethPrice = 0.05 * 10 ** 18; //TBD
    uint256 private _maxMint = 20;
    uint256 private _saleStart = 16422516;
    uint256 private _whitelistSaleStart = 16421652;

    mapping(address => bool) public whitelistUsed;

    receive() external payable {}
    fallback() external payable {}

    constructor() ERC721("CryptoButlers", "CMCB") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        setDefaultURI("https://api.cryptomaids.tokyo/metadata/butler/");
    }

    function setDefaultURI(string memory defaultURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _defaultURI = defaultURI_;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function _baseURI() internal view override returns (string memory) {
        return _defaultURI;
    }

    function _safeMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < _maxSupply, "Max limit");
        _tokenIdCounter.increment();
        super._safeMint(to, tokenId + 1);
    }

    function bulkMint(address[] memory _tos) public onlyRole(MINTER_ROLE) {
        uint8 i;
        for (i = 0; i < _tos.length; i++) {
          _safeMint(_tos[i]);
        }
    }

    function recruitButler(uint256 _count) public payable {
        require(_count < _maxMint, "Exceeds number");
        require(msg.value >= totalPrice(_count), "Value below price");
        require(_saleStart != 0 && block.timestamp > _saleStart, "sale not started");

        for (uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender);
        }
    }

    function whitelistMint(uint256 _count, bytes32[] calldata _proof) external payable {
        require(_count <= _maxMint, "Exceeds number");
        require(msg.value >= totalPrice(_count), "Value below price");
        require(!whitelistUsed[msg.sender], "Address has already minted");
        require(_whitelistSaleStart != 0 && block.timestamp > _whitelistSaleStart , "sale not started");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, _merkleRoot, leaf), "proof invalid");
        require(!whitelistUsed[msg.sender], "whitelist used");
        whitelistUsed[msg.sender] = true;
                
        for (uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender);
        }
    }
    function isWhitelisted(address leaf, bytes32[] calldata _proof) public view returns (bool) { 
        return MerkleProof.verify(_proof, _merkleRoot, keccak256(abi.encodePacked(leaf))); 
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyRole(DEFAULT_ADMIN_ROLE) { _merkleRoot = merkleRoot_; }
    function setMaxSupply(uint256 count_) public onlyRole(DEFAULT_ADMIN_ROLE) { _maxSupply = count_; }
    function setEthPrice(uint256 price_) public onlyRole(DEFAULT_ADMIN_ROLE) { _ethPrice = price_; }
    function setMaxMint(uint256 maxMint_) public onlyRole(DEFAULT_ADMIN_ROLE) { _maxMint = maxMint_; }
    function setSaleStart(uint256 saleStart_) public onlyRole(DEFAULT_ADMIN_ROLE) { 
        _saleStart = saleStart_;
    }
    function setWhitelistSaleStart(uint256 whitelistSaleStart_) public onlyRole(DEFAULT_ADMIN_ROLE) { 
        _whitelistSaleStart = whitelistSaleStart_;
    }

    function merkleRoot() public view returns (bytes32) { return _merkleRoot; }
    function maxMint() public view returns (uint256) { return _maxMint; }
    function maxSupply() public view returns (uint256) { return _maxSupply; }
    function ethPrice() public view returns (uint256) { return _ethPrice; }
    function saleStart() public view returns (uint256) { return _saleStart; }
    function whitelistSaleStart() public view returns (uint256) { return _whitelistSaleStart; }
    function totalPrice(uint256 _count) public view returns (uint256) { return _ethPrice * _count; }
    function totalSupply() public view virtual returns (uint256) { return _supply; }

    function withdraw(address payable recipient, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}
