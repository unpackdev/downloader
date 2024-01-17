// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract Goosebumps is ERC721A, Ownable {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrWLNotStarted();
    error ErrWLEnded();
    error ErrPublicNotStarted();
    error ErrExceedsMaxPublicPerTx();
    error ErrExceedsSupply();
    error ErrInvalidValue();
    error ErrExceedsDevMint();
    error ErrInvalidMerkleProof();
    error ErrExceedsMaxPerWL();
    error ErrMintNotStarted();

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    uint256 public constant maxSupply = 3333;
    uint256 public constant maxDevMint = 20;

    uint256 public constant wlMaxPerWallet = 2;
    uint256 public constant publicMaxPerTx = 2;

    string public constant unrevealedURI = "ipfs://bafkreibhnrlqbe5eg4zjssgffjpyj4x5ckm5tc5d6uqy3d7yzqalsbichm";

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    bytes32 public merkleRoot;
    uint256 public price = 0.025 ether;

    uint256 public wlStart;
    uint256 public devMinted;
    mapping(address => uint256) wlMintedMap;

    bool public revealed;
    string public baseURI;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor() ERC721A(unicode'Goosebumps by Chino Maron (チノマロン)', 'Apparitions') {}

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    function wlMint(uint256 quantity_, bytes32[] memory merkleProof) external payable {

        // check wl started
        uint256 _wlStart = wlStart;
        if (_wlStart == 0) { revert ErrWLNotStarted(); }
        if (block.timestamp > _wlStart + 1 hours) { revert ErrWLEnded(); }

        uint256 _totalSupply = totalSupply();

        // check quantity per wallet
        uint256 mintedQuantity = wlMintedMap[msg.sender];
        if (mintedQuantity + quantity_ > wlMaxPerWallet) { revert ErrExceedsMaxPerWL(); }

        // is whitelisted
        _checkMerkleProof(msg.sender, merkleProof);

        // check supply
        if (_totalSupply + quantity_ > maxSupply) { revert ErrExceedsSupply(); }

        // check value
        if (msg.value != price * quantity_) { revert ErrInvalidValue(); }

        // update state
        wlMintedMap[msg.sender] = quantity_;

        // mint
        _mint(msg.sender, quantity_);
    }

    function mint(uint256 quantity_) external payable {
        uint256 _totalSupply = totalSupply();

        // check mint started
        uint256 _wlStart = wlStart;
        if (_wlStart == 0) { revert ErrMintNotStarted(); }
        if (block.timestamp < _wlStart + 1 hours) { revert ErrMintNotStarted(); }

        // check quantity
        if (quantity_ > publicMaxPerTx) { revert ErrExceedsMaxPublicPerTx(); }

        // check supply
        if (_totalSupply + quantity_ > maxSupply) { revert ErrExceedsSupply(); }

        // check value
        if (msg.value != price * quantity_) { revert ErrInvalidValue(); }

        // mint
        _mint(msg.sender, quantity_);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  overrides                                 */
    /* -------------------------------------------------------------------------- */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(baseURI).length == 0) {
            return unrevealedURI;
        } else {
            return super.tokenURI(tokenId);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                 owners only                                */
    /* -------------------------------------------------------------------------- */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function startMint() external onlyOwner {
        wlStart = block.timestamp;
    }

    function reveal(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function devMint(uint256 quantity_) external onlyOwner {
        uint256 _totalSupply = totalSupply();
        uint256 _devMinted = devMinted;

        // check supply
        if (_totalSupply + quantity_ > maxSupply) { revert ErrExceedsSupply(); }

        // check dev max mint
        if (quantity_ + _devMinted > maxDevMint) { revert ErrExceedsDevMint(); }

        // update state
        devMinted = _devMinted + quantity_;

        // mint
        _mint(msg.sender, quantity_);
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  internal                                  */
    /* -------------------------------------------------------------------------- */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _checkMerkleProof(address account, bytes32[] memory merkleProof) internal view {
        bytes32 node = keccak256(abi.encodePacked(account));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) {
            revert ErrInvalidMerkleProof();
        }
    }
}
