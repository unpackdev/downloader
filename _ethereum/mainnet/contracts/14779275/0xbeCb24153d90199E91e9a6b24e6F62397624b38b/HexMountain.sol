//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
  
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./console.sol";
import "./ERC721Woodable.sol";

contract VMountainInterface {
    function balanceOf(address) public returns (uint) {}
    function tokenOfOwnerByIndex(address, uint) public returns (uint) {}
}

contract HexMountain is ERC721A, ERC721AQueryable, ERC721Woodable {  
    address private immutable contractAddress;
    address public owner;

    VMountainInterface private immutable _vMountainContract;
    mapping (uint => bool) _vMountainUsedForMint;

    uint constant public cap = 1200;
    uint public mintPrice = 7 ether / 100;
    uint public woodificationPrice = 10 ether / 100;

    bool public freeSaleActive = false;
    bool public saleActive = false;
    bool public woodificationActive = false;

    // Donations going to Ethereum protocol contributors via the Protocol guild
    // https://twitter.com/StatefulWorks/status/1477006979704967169
    // https://stateful.mirror.xyz/mEDvFXGCKdDhR-N320KRtsq60Y2OPk8rHcHBCFVryXY
    // https://protocol-guild.readthedocs.io/en/latest/
    address public donationAddress = 0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9;

    string private __baseURI;


    constructor(address vMountainContractAddress) ERC721A("HexMountain", "HEXM") {
        contractAddress = address(this);
        owner = msg.sender;
        _vMountainContract = VMountainInterface(vMountainContractAddress);
        __baseURI = "https://nand.fr/assets/hmountain/metadata/";
    }
  
    function mint(uint64 quantity) external payable noDelegateCall {
        require(tx.origin == msg.sender, "ser plz");
        require(_totalMinted() + quantity <= cap, "Cap reached");
        require(saleActive || freeSaleActive, "Sale not active yet");
        require(quantity <= 20, "Max 20 per tx");

        uint64 quantityToPay = quantity;

        // Free mints for VMountain owners
        for(uint i = 0; i < _vMountainContract.balanceOf(msg.sender); i++) {
            uint tokenId = _vMountainContract.tokenOfOwnerByIndex(msg.sender, i);
            if(_vMountainUsedForMint[tokenId] == false) {
                quantityToPay--;
                _vMountainUsedForMint[tokenId] = true;
                if(quantityToPay == 0) {
                    break;
                }
            }
        }

        // Free mint for whitelisted ppl
        uint64 freeWLMints = _getAux(msg.sender);
        if(freeWLMints > 0 && quantityToPay > 0) {
            uint64 freeWLMintsToConsume = freeWLMints >= quantityToPay ? quantityToPay : freeWLMints;
            quantityToPay -= freeWLMintsToConsume;
            _setAux(msg.sender, freeWLMints - freeWLMintsToConsume);
        }

        // If there are things to pay, ensure the main sale is active
        require(saleActive || quantityToPay == 0, "Sale active for free mint only");

        // Check price
        require(msg.value == quantityToPay * mintPrice, "Incorrect price");

        // Mint all
        _safeMint(msg.sender, quantity);
    }

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {

        // If you minted a token ending with a "5", you get the free woodification of your NFT!
        if(from == address(0)) {
            for(uint tokenId = startTokenId; tokenId < startTokenId + quantity; tokenId++) {
                if(tokenId % 10 == 5) {
                    _safeWoodMint(tokenId);
                }
            }
        }
    }

    /**
     * Woodify a NFT: it create a WNFT (wood NFT).
     */
    function woodMint(uint256 tokenId) external payable {
        require(msg.value == woodificationPrice, "Incorrect price");
        require(ownerOf(tokenId) == msg.sender, "You must own the NFT");
        require(woodificationActive, "Woodification not active yet");

        _safeWoodMint(tokenId);
    } 

    function mintByOwner(uint64 quantity) public onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    function woodMintByOwner(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");

        _safeWoodMint(tokenId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function hasVMountainBeenUsedForFreeMint(uint tokenId) public view returns (bool) {
        return _vMountainUsedForMint[tokenId];
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        __baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function gibWhitelist(address whitelistedAddress, uint64 whitelistedAmount) public onlyOwner {
        _setAux(whitelistedAddress, whitelistedAmount);
    }

    function hasWhitelistAmount(address addr) public view returns (uint64) {
        return _getAux(addr);
    }

    function setFreeSaleActive(bool active) public onlyOwner {
        freeSaleActive = active;
    }

    function setSaleActive(bool active) public onlyOwner {
        saleActive = active;
    }

    function setWoodificationActive(bool active) public onlyOwner {
        woodificationActive = active;
    }

    function setWoodificationPrice(uint price) public onlyOwner {
        woodificationPrice = price;
    }

    function setMintPrice(uint price) public onlyOwner {
        mintPrice = price;
    }

    function fetchSaleFunds() public onlyOwner {
        uint balance = address(this).balance;

        // Donation is 20% of all sales
        uint donation = balance / 5;
        uint remainingBalance = balance - donation;

        payable(donationAddress).transfer(donation);
        payable(msg.sender).transfer(remainingBalance);
    }

    /**
     * Currently the Protocol guild is in Pilot phase (launched 8 may 2022),
     * so I need to be able to update the address if they were to use a smart contract later.
     */
    function setDonationAddress(address newDonationAddress) public onlyOwner {
        donationAddress = newDonationAddress;
    }

    // Hopefully this will not be necessary and I will be able to do that on a L2 (starknet, ...)
    event GeographyUpdated(uint tokenId, uint geographyId);
    bool public updateGeographyActive = false;
    uint public updateGeographyPrice = 5 ether / 100;
    function updateGeography(uint tokenId, uint geographyId) external payable {
        require(msg.value == updateGeographyPrice, "Incorrect price");
        require(updateGeographyActive, "Geography update not active");
        require(ownerOf(tokenId) == msg.sender, "You must own the nft");

        emit GeographyUpdated(tokenId, geographyId);
    }
    function setUpdateGeographyActive(bool active) public onlyOwner {
        updateGeographyActive = active;
    }
    function updateUpdateGeographyPrice(uint newPrice) public onlyOwner {
        updateGeographyPrice = newPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function isNotDelegated() private view {
        require(address(this) == contractAddress, "ser plz");
    }

    modifier noDelegateCall() {
        isNotDelegated();
        _;
    }
}