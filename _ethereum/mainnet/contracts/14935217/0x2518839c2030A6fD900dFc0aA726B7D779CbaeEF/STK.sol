//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./Strings.sol";

/*
Stonkies.sol

Contract by @StonkiesDev
*/

contract STK is Ownable, ERC721A {
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public FREE_MINT_MAX = 2000;
    uint256 public TEAM_MINT_MAX = 50;

    uint256 public publicPrice = 0.005 ether;

    uint256 public constant PUBLIC_MINT_LIMIT_TXN = 10;
    uint256 public constant PUBLIC_MINT_LIMIT = 20;

    uint256 public TOTAL_SUPPLY_TEAM;

    string public revealedURI;

    string public hiddenURI =
        "ipfs://bafkreidaqrk2nt7ypxjvy4fqpsvol6hwrjicrmpm23pdme52xkfquwwmt4";

    string public CONTRACT_URI =
        "ipfs://bafkreidaqrk2nt7ypxjvy4fqpsvol6hwrjicrmpm23pdme52xkfquwwmt4";

    bool public paused = false;
    bool public revealed = false;

    bool public freeSale = true;
    bool public publicSale = false;

    address internal constant DEV_ADDRESS =
        0x2E241C9521dCF1486Ae9a0349237C8c9D7586a5d;
    address internal constant CHARITY_ADDRESS =
        0x45daEB0d3694bC6A8711bf951f17b524Dd9E4AaD;
    address internal constant COMMUINITY_ADDRESS =
        0x951FC0F33995AbAF9E84914304686FF19a2D2137;
    address public TEAM_ADDRESS = 0xD9a8aFb0b5d85E6439941522CCB1Fd824c73F660;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("Stonkies", "STK") {}

    // This function  overrides the first Token#

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //This Functions returns the eth that is overpaid
    function refundOverpay(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        } else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    // Public Functions

    //This function is for the free mint
    //User Can Mint Maximum of 3 free NFTS. Only 1 Free Transaction per user is allowed.
    function freeMint(uint256 quantity)
        external
        payable
        mintCompliance(quantity)
    {
        require(freeSale, "Free sale inactive");
        require(msg.value == 0, "This phase is free");
        require(quantity < 4, "Only 3 free Max");

        uint256 newSupply = totalSupply() + quantity;

        require(newSupply <= FREE_MINT_MAX, "Not enough free supply");

        require(!userMintedFree[msg.sender], "User max free limit");

        userMintedFree[msg.sender] = true;

        if (newSupply >= FREE_MINT_MAX) {
            freeSale = false;
            publicSale = true;
        }

        _safeMint(msg.sender, quantity);
    }

    //This Function Is For Public Mint
    function publicMint(uint256 quantity)
        external
        payable
        mintCompliance(quantity)
    {
        require(publicSale, "Public sale inactive");
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];

        require(
            currMints + quantity <= PUBLIC_MINT_LIMIT,
            "User max mint limit"
        );

        refundOverpay(price * quantity);

        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }

    //This function is used for Team Mint
    function teamMint(uint256 quantity)
        public
        payable
        mintCompliance(quantity)
    {
        require(msg.sender == TEAM_ADDRESS, "Team minting only");
        require(
            TOTAL_SUPPLY_TEAM + quantity <= TEAM_MINT_MAX,
            "No team mints left"
        );
        require(totalSupply() >= FREE_MINT_MAX, "Team mints after free");

        TOTAL_SUPPLY_TEAM += quantity;

        _safeMint(msg.sender, quantity);
    }

    //View Functions
    // This function is only really necessary for enumerability when staking/using on websites etc.

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    //This function returns tokenuri
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed) {
            return
                string(
                    abi.encodePacked(
                        revealedURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        } else {
            return hiddenURI;
        }
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    // https://ethereum.stackexchange.com/questions/110924/how-to-properly-implement-a-contracturi-for-on-chain-nfts
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    //Owner Level Functions

    //To set Max Free Mint
    function setFreeMintMax(uint256 _freeintMax) public onlyOwner {
        FREE_MINT_MAX = _freeintMax;
    }

    //To set Max Team Mint
    function setTeamMintMax(uint256 _teamMintMax) public onlyOwner {
        TEAM_MINT_MAX = _teamMintMax;
    }

    //To set Public Price
    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    //To set BaseURI
    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    //To set Hidden URI
    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenURI = _hiddenMetadataUri;
    }

    //To reveal the collection and set revealeduri
    function revealCollection(bool _revealed, string memory _baseUri)
        public
        onlyOwner
    {
        revealed = _revealed;
        revealedURI = _baseUri;
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    //To pause the contract
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    //To set reveal state
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    //To enable public sale
    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
        freeSale = !_state;
    }

    //To enable free sale
    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
        publicSale = !_state;
    }

    //To Set Team Wallet
    function setTeamWalletAddress(address _teamWallet) public onlyOwner {
        TEAM_ADDRESS = _teamWallet;
    }

    //To Withdraw
    function withdraw() external payable onlyOwner {
        // Get the current funds to calculate initial percentages
        uint256 currBalance = address(this).balance;

        (bool succ, ) = payable(DEV_ADDRESS).call{
            value: (currBalance * 3000) / 10000
        }("");
        require(succ, "Dev transfer failed");

        (succ, ) = payable(CHARITY_ADDRESS).call{
            value: (currBalance * 1500) / 10000
        }("");
        require(succ, "Charity transfer failed");

        // Withdraw the ENTIRE remaining balance to the team wallet
        (succ, ) = payable(COMMUINITY_ADDRESS).call{
            value: address(this).balance
        }("");
        require(succ, "Team (remaining) transfer failed");
    }

    // Owner-only mint functionality to "Airdrop" mints to specific users
    function mintToUser(uint256 quantity, address receiver)
        public
        onlyOwner
        mintCompliance(quantity)
    {
        _safeMint(receiver, quantity);
    }

    //Modifiers

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough mints left"
        );
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}