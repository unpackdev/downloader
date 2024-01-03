// SPDX-License-Identifier: MIT
// 
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣶⣾⣿⣿⣿⣿⣷⣶⣶⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣄⠀⠀⠀⠀⠀
// ⠀⠀⠀⢀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀
// ⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀
// ⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀
// ⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆
// ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷
// ⣿⣿⣿⣿⡟⠿⣿⣿⣛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⢛⣿⣿⡿⢿⣿⣿⣿⣿
// ⢸⣿⣿⣿⡇⠀⠀⠉⠛⢻⣶⣤⡄⠀⠀⠀⠀⠀⣤⣶⣿⠛⠉⠁⠀⢸⣿⣿⣿⣿⣿
// ⠸⣿⣿⣿⣿⡀⠀⠀⢰⣿⣿⣿⡇⠀⠀⠀⠀⠸⣿⣿⣿⡇⠀⠀⢀⣿⣿⣿⣿⣿
// ⠀⢹⣿⣿⣿⣷⣄⠀⠈⠻⠿⠟⠁⠀⠀⠀⠀⠀⠛⠿⠟⠃⠀⢠⣾⣿⣿⣿⣿⡆⠀
// ⠀⠀⠹⣿⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⡆⠀⠀
// ⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⣶⣤⣀⣀⣀⣀⣀⣀⣤⣴⣾⣿⣿⣿⣿⡿⠋⠀⠀⠀
// ⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠿⠿⣿⣿⣿⣿⣿⣿⠿⠿⠛⠋⠁⠀⠀⠀⠀⠀⠀
// 
// 
// 
//    *    (   (            (         ) (       )              
//  (  `   )\ ))\ )   (     )\ )   ( /( )\ ) ( /(       (      
//  )\))( (()/(()/(   )\   (()/(   )\()|()/( )\())  (   )\     
// ((_)()\ /(_))(_)|(((_)(  /(_)) ((_)\ /(_)|(_)\   )((((_)(   
// (_()((_|_))(_))  )\ _ )\(_))    _((_|_))  _((_) ((_)\ _ )\  
// |  \/  |_ _| _ \ (_)_\(_)_ _|  | \| |_ _|| \| |_ | (_)_\(_) 
// | |\/| || ||   /  / _ \  | |   | .` || | | .` | || |/ _ \   
// |_|  |_|___|_|_\ /_/ \_\|___|  |_|\_|___||_|\_|\__//_/ \_\  
// 
// 
// 

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";

contract MiraiNinja is ERC721A, Ownable, ReentrancyGuard, ERC2981 {
    string public baseURI;
    string public notRevealedUri;
    uint256 public cost = 0.012 ether;
    uint256 public wlcost = 0.01 ether;
    uint256 public ogcost = 0.011 ether;
    uint256 public maxSupply = 5555;
    uint256 public wlSupply = 3000;
    uint256 public ogSupply = 800;
    uint256 public MaxperWallet = 10;
    uint256 public MaxperWalletWl = 5;
    uint256 public MaxperWalletOG = 1;
    bool public paused = true;
    bool public revealed = false;
    bool public preSale = false;
    bool public publicSale = false;
    bool public ogSale = false;
    bytes32 public WLmerkleRoot;
    bytes32 public OGmerkleRoot;
    mapping(address => uint256) public PublicMintofUser;
    mapping(address => uint256) public WhitelistedMintofUser;
    mapping(address => uint256) public OGMintofUser;
    uint256 totalWLMint;
    uint256 totalOGMint;
    uint256 totalPublicMint;

    constructor() ERC721A("Mirai Ninja", "MIRAI") {}

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev Public mint
    function mint(uint256 tokens) public payable nonReentrant {
        require(!paused, "Sale is paused");
        require(_msgSenderERC721A() == tx.origin, "BOTS Are not Allowed");
        require(publicSale, "Public Sale Hasn't started yet");
        require(tokens <= MaxperWallet, "max mint amount per tx exceeded");
        require(totalSupply() + tokens <= maxSupply, "Soldout");
        require(
            PublicMintofUser[_msgSenderERC721A()] + tokens <= MaxperWallet,
            "Max NFT Per Wallet exceeded"
        );
        require(msg.value >= cost * tokens, "insufficient funds");

        PublicMintofUser[_msgSenderERC721A()] += tokens;
        totalPublicMint += tokens;
        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev presale mint for whitelisted users
    function presalemint(uint256 tokens, bytes32[] calldata merkleProof)
        public
        payable
        nonReentrant
    {
        require(!paused, "Sale is paused");
        require(preSale, "Presale Hasn't started yet");
        require(_msgSenderERC721A() == tx.origin, "BOTS Are not Allowed");
        require(
            MerkleProof.verify(
                merkleProof,
                WLmerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "You are not Whitelisted"
        );
        require(
            WhitelistedMintofUser[_msgSenderERC721A()] + tokens <=
                MaxperWalletWl,
            "Max NFT Per Wallet exceeded"
        );
        require(tokens <= MaxperWalletWl, "max mint per Tx exceeded");
        require(
            totalSupply() + tokens <= wlSupply,
            "Whitelist MaxSupply exceeded"
        );
        require(msg.value >= wlcost * tokens, "insufficient funds");

        WhitelistedMintofUser[_msgSenderERC721A()] += tokens;
        totalWLMint += tokens;
        _safeMint(_msgSenderERC721A(), tokens);
    }

        /// @dev presale mint for whitelisted users
    function ogmint(uint256 tokens, bytes32[] calldata merkleProof)
        public
        payable
        nonReentrant
    {
        require(!paused, "Sale is paused");
        require(ogSale, "OGsale Hasn't started yet");
        require(_msgSenderERC721A() == tx.origin, "BOTS Are not Allowed");
        require(
            MerkleProof.verify(
                merkleProof,
                OGmerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "You are not Whitelisted"
        );
        require(
            OGMintofUser[_msgSenderERC721A()] + tokens <=
                MaxperWalletOG,
            "Max NFT Per Wallet exceeded"
        );
        require(tokens <= MaxperWalletOG, "max mint per Tx exceeded");
        require(
            totalSupply() + tokens <= ogSupply,
            "Whitelist MaxSupply exceeded"
        );
        require(msg.value >= ogcost * tokens, "insufficient funds");

        OGMintofUser[_msgSenderERC721A()] += tokens;
        totalOGMint += tokens;
        _safeMint(_msgSenderERC721A(), tokens);
    }

    function airdrop(uint256 _mintAmount, address[] calldata destination)
        public
        onlyOwner
        nonReentrant
    {
        uint256 totalnft = _mintAmount * destination.length;
        require(
            totalSupply() + totalnft <= maxSupply,
            "max NFT limit exceeded"
        );
        for (uint256 i = 0; i < destination.length; i++) {
            _safeMint(destination[i], _mintAmount);
        }
    }

    /// @dev use it To Burn NFTs
    function burn(uint256[] calldata tokenID) public nonReentrant {
        for (uint256 id = 0; id < tokenID.length; id++) {
            require(_exists(tokenID[id]), "Burning for nonexistent token");
            require(
                ownerOf(tokenID[id]) == _msgSenderERC721A(),
                "You are not owner of this NFT"
            );
            _burn(tokenID[id]);
        }
    }

    /// @notice returns metadata link of tokenid
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
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
                        _toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /// @notice return the total number minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /// @notice return all tokens owned by an address
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /// @dev to reveal collection, true for reveal
    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }


    function setMerkleRoots(bytes32 _WLRoot, bytes32 _OGRoot) external onlyOwner {
        WLmerkleRoot = _WLRoot;
        OGmerkleRoot = _OGRoot;
    }

    function setMaxPerWallets(uint256 _publiclimit, uint256 _wllimit, uint256 _oglimit) public onlyOwner {
        MaxperWallet = _publiclimit;
        MaxperWalletWl = _wllimit;
        MaxperWalletOG = _oglimit;
    }


    /// @dev change the nft price(amount need to be in wei)
    function setCosts(uint256 _publicCost, uint256 _WLCost, uint256 _ogCost) public onlyOwner {
        cost = _publicCost;
        wlcost = _WLCost;
        ogcost = _ogCost;
    }

    function setMaxsupply(uint256 _newsupply) public onlyOwner {
        maxSupply = _newsupply;
    }

    function setWlsupply(uint256 _newsupply) public onlyOwner {
        wlSupply = _newsupply;
    }

    function setOGsupply(uint256 _newsupply) public onlyOwner {
        ogSupply = _newsupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /// @dev to pause and unpause your contract(use booleans true or false)
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }


    /// @dev activate sales(use booleans true or false)
    function togglesalePhases(bool _public, bool _wl, bool _og) public onlyOwner {
        ogSale = _og;
        publicSale = _public;
        preSale = _wl;
    }


    function withdraw() public payable onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSenderERC721A()).transfer(balance);
    }

    // ERC2981 functions
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }
}
