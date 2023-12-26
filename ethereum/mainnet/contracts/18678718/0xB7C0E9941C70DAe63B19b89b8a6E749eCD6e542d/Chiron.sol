// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./ERC721AC.sol";
import "./BasicRoyalties.sol";

contract ChironWorld is ERC721AC, Ownable, Pausable, BasicRoyalties {
    using Strings for uint256;
    string public baseUri;

    uint256 public supply;
    string public extension = ".json";

    bool public whitelistLive;
    bool public revealed;
    bytes32 public merkleRoot;

    struct Config {
        uint256 mintPrice;
        uint256 maxMint;
    }

    Config public config;

    mapping(address => bool) admins;

    event WhitelistLive(bool live);
    event SaleLive(bool live);

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseUri,
        bytes32 _merkleRoot
    ) ERC721AC(name, symbol) BasicRoyalties(msg.sender, 500) {
        config.mintPrice = 0.03 ether;
        config.maxMint = 1;
        supply = 930;
        baseUri = _baseUri;
        merkleRoot = _merkleRoot;
        _pause();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721AC, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalties(address _receiver, uint96 _fees) external onlyOwner {
        _setDefaultRoyalty(_receiver, _fees);
    }

    /**
     * @dev Returns the first token id.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _requireCallerIsContractOwner() internal view virtual override {
        require(
            _msgSender() == owner(),
            "ERC721A: caller is not the contract owner"
        );
    }

    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        address wallet
    ) internal pure returns (bool) {
        bytes32 leaf = getLeaf(wallet);
        return MerkleProof.verify(proof, root, leaf);
    }

    function getLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function whitelistMint(
        bytes32[] calldata proof
    ) external payable whenNotPaused {
        require(whitelistLive, "Whitelist sale has ended");
        require(
            verify(proof, merkleRoot, msg.sender),
            "Wallet not whitelisted"
        );
        require(msg.value == config.mintPrice, "Invalid price");
        require(_numberMinted(msg.sender) == 0, "Already minted");
        _callMint(1, msg.sender);
    }

    function mint() external payable whenNotPaused {
        require(!whitelistLive, "Public sale not live");
        require(_numberMinted(msg.sender) == 0, "Already minted");
        require(msg.value >= config.mintPrice, "Invalid price");
        _callMint(1, msg.sender);
    }

    function adminMint(uint256 count, address to) external onlyOwner {
        _callMint(count, to);
    }

    function _callMint(uint256 count, address to) internal {
        uint256 total = totalSupply();
        require(total + count <= supply, "Sold out");
        _safeMint(to, count);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function setUri(string memory _uri) external onlyOwner {
        baseUri = _uri;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function toggleWhitelistLive() external onlyOwner {
        whitelistLive = !whitelistLive;
        emit WhitelistLive(whitelistLive);
    }

    function setMerkle(bytes32 _merkleProof) external onlyOwner {
        merkleRoot = _merkleProof;
    }

    function setConfig(Config memory _config) external onlyOwner {
        config = _config;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
