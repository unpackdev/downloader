    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.9;

    import "./ERC721.sol";
    import "./ERC721Burnable.sol";
    import "./Ownable.sol";
    import "./Counters.sol";
    import "./MerkleProof.sol";

    /// @custom:security-contact k@quantum.tech
    contract EarthAnimalClub is ERC721, ERC721Burnable, Ownable {
        using Counters for Counters.Counter;
        Counters.Counter public tokenIdCounter;
        struct MintInfo {
            bool didMint;
            uint tokenId;
        }
        string public baseURI = "ipfs://QmbBwLhmqpi6dJxbDiHahdwiWsUxgdfh5HpN5KxyNFubNj";
        bytes32 public merkleroot;
        uint256 constant public TOTALCOUNT = 50; 
        mapping(address => MintInfo) public tokenPerWallet;

        constructor(bytes32 root) ERC721(".earth animal club", "EARTH-ANIMAL-CLUB") {
            merkleroot = root;
        }

        function isValidProof(bytes32[] calldata _proof, address to) view public returns(bool) {
            bytes32 leaf = computeLeaf(to);
            return MerkleProof.verify(_proof, merkleroot, leaf);
        }

        function computeLeaf(address to) public pure returns (bytes32) {
            return keccak256(abi.encodePacked(to));
        }

        function mint(address to, bytes32[] calldata _proof) public {
            require(isValidProof(_proof, to), "You are not whitelisted");
            require(tokenPerWallet[to].didMint == false, "Token for that address already minted");
            uint256 tokenId = tokenIdCounter.current();
            require(tokenId < TOTALCOUNT, "Fully minted");
            tokenIdCounter.increment();
            tokenPerWallet[to].didMint = true;
            tokenPerWallet[to].tokenId = tokenId;
            _mint(to, tokenId);
        }

        function setBaseURI(string memory _newURI) public onlyOwner {
            baseURI = _newURI;
        }

        function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
            merkleroot = _newMerkleRoot;
        }

        function _baseURI() internal view virtual override returns (string memory){
            return baseURI;
        }

        function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            return _baseURI();
        }

        function totalSupply() external view returns (uint) {
            return tokenIdCounter.current();
        }
    }