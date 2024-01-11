// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@               *%&          @@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@         @@    @            @  /@        @@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@                 @@  @           @               @@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@                      @  @     &  .                  @@@@@@@@@@@@@@
// @@@@@@@@@@@@                        @  @      @   @@@@@@@@@@@@@@@   @@@@@@@@@@@@
// @@@@@@@@@@@           @@@@@@@@@@@@@@@@@ @  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@                 @@@@@@@@@@@@@@
// @@@@@@@@@@@ @@@@@@@@@@                @       @                       @@@@@@@@@@
// @@@@@@@@@@@@@@@@@                     @        @                      *@@@@@@@@@
// @@@@@@@@@@@@@@                       @          @                     @@@@@@@@@@
// @@@@@@@@@@@@@@                      @          @ @                    @@@@@@@@@@
// @@@@@@@@@@@@@@@@*                %@  @       @  @  @                @@@@@@@@@@@@
// @@@@@@@@@@@@@@@@   @@        @@   @   @        @   @  @/          @@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@  .     .@@    @@            @    @@       %@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@       @                    @@         @@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@                               @@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@                              @@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@&                            @@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@                          @@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                        @@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%                     #@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                          @@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@                 @@@  @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@              (@@@@ @@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@           @@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@         @@@@   @@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@     ,@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@  @@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract MantisMansion is Ownable, ERC721A, ReentrancyGuard {

    using Strings for uint256;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public cost = 0.069 ether;
    uint256 public guestListCost = 0.055 ether;
    uint256 public guestListVIPCost = 0 ether;
    uint8 public maxGuestListVIPFreeMint = 1;
    uint256 public maxSupply = 6666;
    uint256 public teamSupply = 50;
    uint256 public maxMintAmount = 10;
    bool public paused = false;
    bool public revealed = false;

    // Allowed Wallets
    bool public isGuestListVIPActive = false;
    bool public isGuestListActive = false;
    bool public isPublicActive = false;


    mapping(address => uint256) public addressMintedBalance;
    mapping (address => uint256) public guestListVIPFreeMintAddress;
    mapping(address => uint256) addressBlockBought;

    // Merkle Tree Root Address
    bytes32 public guestListMerkleRoot;
    bytes32 public guestListVIPMerkleRoot;


    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A("Mantis Mansion", "MANTIS", 50, maxSupply) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // Verifiers
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function setGuestListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        guestListMerkleRoot = merkleRoot;
    }

    function setGuestListVIPMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        guestListVIPMerkleRoot = merkleRoot;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isMintActive(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isGuestListVIPActive, "GUEST_LIST_VIP_IS_NOT_ACTIVE");
        } 

        if(mintType == 2) {
            require(isGuestListActive, "GUEST_LIST_IS_NOT_ACTIVE");
        }

        if(mintType == 3) {
            require(isPublicActive, "PUBLIC_IS_NOT_ACTIVE");
        }
        _;
    }

    // Mint for Team
    function mintForTeam(uint256 _mintAmount) external onlyOwner {
        require(teamSupply > 0, "NFTS_FOR_THE_TEAM_HAS_BEEN_MINTED");
        require(_mintAmount <= teamSupply, "EXCEEDS_MAX_MINT_FOR_TEAM");

        teamSupply -= _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // Public
    function mint(
        uint256 _mintAmount
        ) 
        public
        payable 
        isMintActive(3) 
        isCorrectPayment(cost, _mintAmount)
        {
        require(!paused, "CONTRACT_IS_PAUSED");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "NO_TOKEN_AMOUNT_PROVIDED_FOR_MINT");
        require(_mintAmount <= maxMintAmount,"EXCEEDS_SINGLE_TRANSACTION_MINT");
        require(supply + _mintAmount <= maxSupply, "EXCEEDS_MAX_SUPPLY_LIMIT");

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "INSUFFICIENT_FUNDS");
        }

        addressMintedBalance[msg.sender] += _mintAmount;
        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, _mintAmount);
    }

    // Guest List (Whitelist) - Lowered Price
    function mintGuestList(
        uint256 _mintAmount,
        bytes32[] calldata merkleProof
        )
        public
        payable
        isMintActive(2)
        isValidMerkleProof(merkleProof, guestListMerkleRoot)
        isCorrectPayment(guestListCost, _mintAmount)
    {
        require(!paused, "CONTRACT_IS_PAUSED");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "NO_TOKEN_AMOUNT_PROVIDED_FOR_MINT");
        require(_mintAmount <= maxMintAmount,"EXCEEDS_SINGLE_TRANSACTION_MINT");
        require(supply + _mintAmount <= maxSupply, "EXCEEDS_MAX_SUPPLY_LIMIT");

        if (msg.sender != owner()) {
            require(msg.value >= guestListCost * _mintAmount, "INSUFFICIENT_FUNDS");
        }

        addressMintedBalance[msg.sender] += _mintAmount;
        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, _mintAmount);
    }

    // Guest List VIP (Cryptocrawlerz Owners ) - FREE
    function mintGuestListVIP(
        bytes32[] calldata merkleProof
        )
        public
        payable
        isMintActive(1)
        isValidMerkleProof(merkleProof, guestListVIPMerkleRoot)
    {
        require(!paused, "CONTRACT_IS_PAUSED");
        uint256 supply = totalSupply();
        require(guestListVIPFreeMintAddress[msg.sender] + 1 <= maxGuestListVIPFreeMint,"EXCEEDS_MAX_FREE_MINT");
        require(supply + 1 <= maxSupply, "EXCEEDS_MAX_SUPPLY_LIMIT");

        guestListVIPFreeMintAddress[msg.sender]++;
        addressMintedBalance[msg.sender]++;
        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, 1);
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
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //Owner Commands --------------------------------------------
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setGuestListVIPCost(uint256 _newCost) public onlyOwner {
        guestListVIPCost = _newCost;
    }

    function setGuestListCost(uint256 _newCost) public onlyOwner {
        guestListCost = _newCost;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    // MetaData URI Settings
    string private baseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // Minting Activations

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function allowGuestListVIP(bool _state) public onlyOwner {
        isGuestListVIPActive = _state;
    }

    function allowGuestList(bool _state) public onlyOwner {
        isGuestListActive = _state;
    }

    function allowPublic(bool _state) public onlyOwner {
        isPublicActive = _state;
    }

    // Withdraw ETH
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to withdraw balance");
    }
}