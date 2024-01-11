// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";

contract BELEEWORLD is ERC721, Ownable {
    using Strings for uint256;

    uint16 private index;
    uint256 public seed;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public cost = 0.18 ether;
    uint256 public costOG = 0.18 ether;
    uint256 public costWL = 0.15 ether;
    uint256 public maxSupply = 888;
    uint256 public maxMintAmountWL = 2;
    uint256 public maxMintAmountOG = 2;
    uint256 public maxMintAmountPublic = 4;
    uint256 public nftPerAddressLimitWL = 888;

    uint256 allTokens = 0;
    bool public revealed = false;
    mapping(address => uint256) public addressMintedBalance;

    uint256 public currentState = 0;

    mapping(address => bool) public whitelistedAddresses;
    mapping(address => bool) public OGedAddresses;

    bytes32 public merkleRootWhitelist =
        0x2d6c060187f5af199ef28a2c25b9d4f7e1be51ad0a2de09aaa249553cff5b24c;

    bytes32 public merkleRootOG =
        0xe5840aec0dd09e333d7a91755692f64db00e74eb5359b0e4aa75a9dc80a8cda5;

    constructor() ERC721("BELEEWORLD", "BEL") {
        setNotRevealedURI(
            "ipfs://Qmb3CFk1qdLeqdAVMWEgxoApXmWzVDDEUTWq75FDJk7Jgk/mystery.json "
        );
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        if (msg.sender != owner()) {
            require(currentState > 0, "the contract is paused");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            if (currentState == 1) {
                require(isWhitelisted(msg.sender, _merkleProof), "user is not whitelisted");
                require(!whitelistedAddresses[msg.sender], "user has already claimed a mint");
                require(
                    _mintAmount <= maxMintAmountWL,
                    "max mint amount per session exceeded"
                );
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimitWL,
                    "max NFT per address exceeded"
                );
                require(
                    msg.value >= costWL * _mintAmount,
                    "insufficient funds"
                );
                whitelistedAddresses[msg.sender] = true;
            } else if (currentState == 2) {
                require(isOGed(msg.sender, _merkleProof), "user is not oged");
                require(!OGedAddresses[msg.sender], "user has already claimed a mint");
                require(
                    _mintAmount <= maxMintAmountOG,
                    "max mint amount per session exceeded"
                );
                require(msg.value >= costOG * _mintAmount, "insufficient funds");
                OGedAddresses[msg.sender] = true;
            } else if (currentState == 3) {
                require(
                    _mintAmount <= maxMintAmountPublic,
                    "max mint amount per session exceeded"
                );
                require(msg.value >= cost * _mintAmount, "insufficient funds");
            }
        }

        for (uint256 i = 0; i < _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
            allTokens++;
        }
    }

    function metadataOf(uint256 tokenId) public view returns (string memory) {
        require( tokenId < totalSupply(), "Invalid token id");

        if (seed == 0) return "";

        uint256[] memory metaIds = new uint256[](maxSupply);
        uint256 randomSeed = seed;

        for (uint256 i = 0; i < maxSupply; i++) {
            metaIds[i] = i;
        }

        // shuffle meta id
        for (uint256 i = 51; i < maxSupply; i++) {
            uint256 j = (uint256(keccak256(abi.encode(randomSeed, i))) % (maxSupply - 51)) + 51;
            (metaIds[i], metaIds[j]) = (metaIds[j], metaIds[i]);
        }

        return metaIds[tokenId].toString();
    }

    function totalSupply() public view returns (uint256) {
        return allTokens;
    }

    function isWhitelisted(address _user, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        require(
            MerkleProof.verify(_merkleProof, merkleRootWhitelist, leaf),
            "Invalid Merkle Proof."
        );
        return true;
    }

    function isOGed(address _user, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        require(
            MerkleProof.verify(_merkleProof, merkleRootOG, leaf),
            "Invalid Merkle Proof."
        );
        return true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        metadataOf(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function reveal(uint256 randomNumber) public onlyOwner {
        require( !revealed, "Blind box already revealed!");

        if (randomNumber > 0) seed = randomNumber;
        else seed = 1;

        revealed = true;
    }

    function setNftPerAddressLimitWL(uint256 _limit) public onlyOwner {
        nftPerAddressLimitWL = _limit;
    }

    function setmaxMintAmountPublic(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmountPublic = _newmaxMintAmount;
    }

    function setmaxMintAmountOG(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmountOG = _newmaxMintAmount;
    }

    function setmaxMintAmountWL(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmountWL = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause() public onlyOwner {
        currentState = 0;
    }

    function setOnlyWhitelisted() public onlyOwner {
        currentState = 1;
    }

    function setOnlyOg() public onlyOwner {
        currentState = 2;
    }

    function setPublic() public onlyOwner {
        currentState = 3;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRootWhitelist = _merkleRoot;
    }

    function setOGMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRootOG = _merkleRoot;
    }

    function removeFromWhitelistClaimedUser(address _user) public onlyOwner {
        whitelistedAddresses[_user] = false;
    }

    function removeFromOGClaimedUsers(address _user) public onlyOwner {
        OGedAddresses[_user] = false;
    }

    function setPublicCost(uint256 _price) public onlyOwner {
        cost = _price;
    }

    function setWLCost(uint256 _price) public onlyOwner {
        costWL = _price;
    }

    function setOGCost(uint256 _newCost) public onlyOwner {
        costOG = _newCost;
    }

    function withdraw() public payable onlyOwner {
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}
