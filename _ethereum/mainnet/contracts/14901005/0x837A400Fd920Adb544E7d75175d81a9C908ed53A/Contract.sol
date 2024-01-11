//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./Strings.sol";

/*
GoblinCats.sol

*/

contract GoblinzCats is Ownable, ERC721A {
    
    
    uint256 constant public MAX_SUPPLY = 5000;
    uint256 public publicPrice = 0.003 ether;

    uint256 constant public PUBLIC_MINT_LIMIT_TXN = 5;
    uint256 constant public PUBLIC_MINT_LIMIT = 10;


    string public revealedURI;
    
    string public hiddenURI = "ipfs://QmUiQ2ZY897kyq35aZHmRBFQbJnkNgYeZdQzFNvnWW96K1/hidden.json";

    string public CONTRACT_URI = "ipfs://QmUiQ2ZY897kyq35aZHmRBFQbJnkNgYeZdQzFNvnWW96K1/hidden.json";

    string public baseExtension = ".json";

    bool public paused = true;
    bool public revealed = false;

    bool public freeSale = true;
    bool public publicSale = false;

    address constant internal DEV_ADDRESS = 0x0224c4b1947b01bE8F3C0629A65a05a59174905a;
    address public teamWallet = 0xD67138944217166151C5e70F3e9687101F5D6944;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("Goblinz Cats", "GOBCTS") { 

        _safeMint(teamWallet, 100);
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function refundOverpay(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    
    function freeMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(freeSale, "Free sale inactive");
        require(msg.value == 0, "This phase is free");
        require(quantity <= 2, "Only 2 free");

        uint256 newSupply = totalSupply() + quantity;
        
        require(newSupply <= 1000, "Not enough free supply");

        require(!userMintedFree[msg.sender], "User max free limit");
        
        userMintedFree[msg.sender] = true;

        if(newSupply == 1000) {
            freeSale = false;
            publicSale = true;
        }


        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(publicSale, "Public sale inactive");
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];
                
        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "User max mint limit");
        
        refundOverpay(price * quantity);

        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {

        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (revealed) {
            return string(abi.encodePacked(revealedURI, Strings.toString(_tokenId), ".json"));
        }
        else {
            return hiddenURI;
        }
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenURI = _hiddenMetadataUri;
    }

    function revealCollection() public onlyOwner {
        revealed = true;
        revealedURI = CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
        freeSale = !_state;
    }
    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
        publicSale = !_state;
    }

    function setTeamWalletAddress(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function withdraw() external payable onlyOwner {
       
        uint256 currBalance = address(this).balance;

        (bool succ, ) = payable(DEV_ADDRESS).call{
            value: (currBalance * 1000) / 10000
        }("");
        require(succ, "Dev transfer failed");

        
        (succ, ) = payable(teamWallet).call{
            value: address(this).balance
        }("");
        require(succ, "Team (remaining) transfer failed");
    }

    function mintToUser(uint256 quantity, address receiver) public onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
    }


    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}