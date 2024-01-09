// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Metaflag is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public onlyWhitelisted = true;

    address public proxyRegistryAddress;

    string private _baseURIExtended =
        "ipfs://QmXHDUHAK2szMUeNHtX6BpkKLCq1Au1tbZCsJ3r3tR4t88/";

    bytes32 public whitelistMerkleRoot;
    uint256 public cost = 0.04 ether;
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant MAX_MINT_AMOUNT = 10;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public addressToMinted;

    constructor(address _proxyRegistryAddress) ERC721("Metaflag", "MFG") {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    //OnlyOwner
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        _baseURIExtended = _baseTokenURI;
    }

    function setPrice(uint256 price) public onlyOwner {
        cost = price;
    }

    function changeOnlyWhitelisted() public onlyOwner {
        onlyWhitelisted = !onlyWhitelisted;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function teamMint(uint256 _mintAmount) external onlyOwner {
        require(totalSupply() + _mintAmount < MAX_SUPPLY, "not enough to mint");
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function _leaf(string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    // public
    function whitelistMint(uint256 count, bytes32[] calldata proof)
        public
        payable
    {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verify(_leaf(payload), proof),
            "Invalid Merkle Tree proof supplied."
        );
        require(
            addressToMinted[_msgSender()] + count <= MAX_MINT_AMOUNT,
            "Exceeds whitelist supply"
        );
        require(count * cost == msg.value, "Invalid funds provided.");

        addressToMinted[_msgSender()] += count;
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function publicMint(uint256 count) public payable {
        require(!onlyWhitelisted, "Public mint is not open");
        require(totalSupply() + count < MAX_SUPPLY, "Exceeds max supply.");
        require(count < MAX_MINT_AMOUNT, "Exceeds max per transaction.");
        require(count * cost == msg.value, "Invalid funds provided.");

        for (uint256 i; i < count; i++) {
            _safeMint(_msgSender(), totalSupply());
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return
            string(
                abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
