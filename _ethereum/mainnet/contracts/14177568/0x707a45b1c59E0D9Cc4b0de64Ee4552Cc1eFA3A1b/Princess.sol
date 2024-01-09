// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

contract Princess is ERC721, Ownable, Pausable {
    string internal baseURI;
    uint256 public constant MAX_SUPPLY = 6000;
    uint256 public constant MAX_PER_TX = 20;
    uint256 public priceInWei;
    bytes32 public whitelistMerkleRoot =
        0xb54ab4fffb30f62f70e6f0e82b12b3aa53fb00d77b21c1bdc4dde59cb9db3b45;
    uint256 public totalSupply;

    constructor(string memory _baseUri, address _owner)
        ERC721("CHILL PRINCESS", "PRINCESS")
    {
        baseURI = _baseUri;
        transferOwnership(_owner);
    }

    function _leaf(string memory allowance, string memory payload)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        private
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function mint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) external payable whenNotPaused {
        string memory payload = string(abi.encodePacked(msg.sender));
        require(
            _verify(_leaf(Strings.toString(allowance), payload), proof),
            "Invalid Merkle Tree proof supplied."
        );
        require(
            balanceOf(msg.sender) + count <= allowance,
            "count exceeds allowance for this address"
        );
        require(count <= MAX_PER_TX, "Exceeds max per transaction.");
        require(count * priceInWei == msg.value, "Invalid funds provided.");
        uint256 currentSupply = totalSupply;
        uint256 newSupply = currentSupply + count;
        require(newSupply <= MAX_SUPPLY, "Excedes max supply.");

        for (uint256 i = 1; i <= count; i++) {
            _mint(msg.sender, currentSupply + i);
        }
        totalSupply = newSupply;
    }

    function mintOwner(uint256 count) external onlyOwner {
        uint256 currentSupply = totalSupply;
        uint256 newSupply = currentSupply + count;
        require(newSupply <= MAX_SUPPLY, "Excedes max supply.");

        for (uint256 i = 1; i <= count; i++) {
            _mint(msg.sender, currentSupply + i);
        }

        totalSupply = newSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function setPriceInWei(uint256 _newPrice) external onlyOwner {
        priceInWei = _newPrice;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send to owner.");
    }
}
