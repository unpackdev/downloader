//SPDX-License-Identifier: MIT


pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

/*
_________ .__  __         ________                 
\_   ___ \|__|/  |______  \______ \ _____    ____  
/    \  \/|  \   __\__  \  |    |  \\__  \  /  _ \ 
\     \___|  ||  |  / __ \_|    `   \/ __ \(  <_> )
 \______  /__||__| (____  /_______  (____  /\____/ 
        \/              \/        \/     \/        
*/

contract CitaDaoProject is ERC721, Ownable, ReentrancyGuard  {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.085 ether;

    uint256 constant public maxSupply = 9500;
    uint256 public maxMintAmount = 5;
    uint256 public nftPerWhiteListTier1AddressLimit = 1;
    uint256 public nftPerWhiteListTier2AddressLimit = 2;
    uint256 public nftPerWhiteListTier3AddressLimit = 5;

    uint256 public nftPerPublicAddressLimit = 1;

    bool public paused = true;
    bool public onlyWhitelist = true;

    bytes32 public merkleRootTier1 = 0xde8c507567c6cf0746076ed269946c95dfe65181d938a8a4da5ce2daa186dfe8 ;
    bytes32 public merkleRootTier2 = 0x76d32d30a72d79ab999b66453e3caf622b77d8e761412f6b25a6c29355a9d476 ;
    bytes32 public merkleRootTier3 = 0xc161cfbd408e04353a30500bc80582f4a2e330557733fc607f767c9e4c81e686 ;


    mapping(address => uint256) public addressMintBalance;

        constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseUri);
    }

        function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // reduce gas during mint.
    function totalToken() public view returns (uint256) {
            return _tokenIdTracker.current();
    }

    function ownerMint(uint256 _mintAmount) public onlyOwner
    {
        uint256 supply = totalToken();
        require(_mintAmount > 0, "User must mint at least 1 NFT");
        require(
            supply + _mintAmount <= maxSupply,
            "All NFT's in collection have been minted"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {

            addressMintBalance[msg.sender]++;
            _tokenIdTracker.increment();
            _safeMint(msg.sender, totalToken());
        }
    }

     /// @notice minting function; subject to WL constraints 
    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable nonReentrant {
        require(!paused, "Minting on this Contract is currently paused");
        uint256 supply = totalToken();
        require(_mintAmount > 0, "User must mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "User has exhausted available mints this session"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "All NFT's in collection have been minted"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (msg.sender != owner()) {
            if (onlyWhitelist == true) {
                require(
                    MerkleProof.verify(_merkleProof, merkleRootTier1, leaf) || 
                    MerkleProof.verify(_merkleProof, merkleRootTier2, leaf) ||
                    MerkleProof.verify(_merkleProof, merkleRootTier3, leaf),
                    "User is not on the Whitelist"
                );
                if (MerkleProof.verify(_merkleProof, merkleRootTier1, leaf)) {
                    uint256 whitelistTier1OwnerMintCount = addressMintBalance[
                        msg.sender
                    ];
                    require(
                        whitelistTier1OwnerMintCount + _mintAmount <=
                            nftPerWhiteListTier1AddressLimit,
                        "The Max NFTs per address exceeded"
                    );
                } else if (MerkleProof.verify(_merkleProof, merkleRootTier2, leaf)) {
                    uint256 whitelistTier2OwnerMintCount = addressMintBalance[
                        msg.sender
                    ];
                    require(
                        whitelistTier2OwnerMintCount + _mintAmount <=
                            nftPerWhiteListTier2AddressLimit,
                        "The Max NFTs per address exceeded"
                    );
                } else if (MerkleProof.verify(_merkleProof, merkleRootTier3, leaf)) {
                    uint256 whitelistTier3OwnerMintCount = addressMintBalance[
                        msg.sender
                    ];
                    require(
                        whitelistTier3OwnerMintCount + _mintAmount <=
                            nftPerWhiteListTier3AddressLimit,
                        "The Max NFTs per address exceeded"
                    );
                }
            } else {
                uint256 PublicOwnerMintCount = addressMintBalance[msg.sender];
                require(
                    PublicOwnerMintCount + _mintAmount <=
                        nftPerPublicAddressLimit,
                    "The Max NFTs per address exceeded"
                );
            }
            require(msg.value >= cost * _mintAmount, "Insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {

            addressMintBalance[msg.sender]++;
            _tokenIdTracker.increment();
            _safeMint(msg.sender, totalToken());
        }
    }

    /// @notice pulls token URI for queried Token ID
/// @dev takes uint256 returns string 

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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /// @notice Owner Functions
    /// @dev Unpause minting, modify WL tiers, change WL state (bool).  

    function setMerkleRootTier1(bytes32 incomingBytes) public onlyOwner
    {
        merkleRootTier1 = incomingBytes;
    }

    function setMerkleRootTier2(bytes32 incomingBytes) public onlyOwner
    {
        merkleRootTier2 = incomingBytes;
    }

    function setMerkleRootTier3(bytes32 incomingBytes) public onlyOwner
    {
        merkleRootTier3 = incomingBytes;
    }


    function setNftPerWhiteListTier1AddressLimit(uint256 _limit)
        public
        onlyOwner
    {
        nftPerWhiteListTier1AddressLimit = _limit;
    }

    function setNftPerWhiteListTier2AddressLimit(uint256 _limit)
        public
        onlyOwner
    {
        nftPerWhiteListTier2AddressLimit = _limit;
    }

    function setNftPerWhiteListTier3AddressLimit(uint256 _limit)
        public
        onlyOwner
    {
        nftPerWhiteListTier3AddressLimit = _limit;
    }

    function setNftPerPublicAddressLimit(uint256 _limit) public onlyOwner {
        nftPerPublicAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
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

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    /// @notice When set to true, only WL users may mint from contract
    /// @dev set state when public mint starts (bool)
    function setOnlyWhitelist(bool _state) public onlyOwner {
        onlyWhitelist = _state;
    }

    function totalSupply() public view returns (uint256) {
            return _tokenIdTracker.current();
    }

    function withdraw() public payable onlyOwner {
        /// @notice To DAO
        (bool hs, ) = payable(0xCf282f464614B837282125cfa3c250985966E0eF).call{value: address(this).balance * 75 / 100}("");
        require(hs);
        /// @notice To team / founders
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}