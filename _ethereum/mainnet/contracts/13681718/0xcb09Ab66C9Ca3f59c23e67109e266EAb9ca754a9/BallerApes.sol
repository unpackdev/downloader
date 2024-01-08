// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract BallerApes is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using ECDSA for bytes32;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 20;

    uint256 public mintPrice = 0.08 ether;

    bool public saleIsActive = false;

    bool public presaleIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public currentBatchNumber = 1;

    // Used to validate authorized mint addresses
    address public signerAddress = 0x4cF49B4F82aE3aED2499b4F57A8208bb001A6EDC;

    address[5] private _shareholders;

    uint[5] private _shares;

    IERC721 public pigskinApesContractInstance;

    // Mapping from batch number to addresses to get a bool on whether the address has claimed its free NFTs
    mapping (uint256 => mapping (address => bool)) public hasClaimed;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxBallerApeSupply, address pigskinApesAddress) ERC721(name, symbol) {
        maxTokenSupply = maxBallerApeSupply;

        _shareholders[0] = 0xD83C7bcED50Ba86f1C1FBf29aBba278E3659F72A; // Mark
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0xBaC76260da2763003f1d1D110DAfac140daA4644; // Jose
        _shareholders[3] = 0xa07b04d4940d549b224e2a4802B541b6648cA40a; // Blair
        _shareholders[4] = 0x4D842f973158E70a6A54e0b0FBF752A70aF14FbD; // Toni

        _shares[0] = 4100;
        _shares[1] = 2200;
        _shares[2] = 2200;
        _shares[3] = 1000;
        _shares[4] = 500;

        pigskinApesContractInstance = IERC721(pigskinApesAddress);
    }

    function setSignerAddress(address newSignerAddress) public onlyOwner {
        signerAddress = newSignerAddress;
    }

    function setCurrentBatchNumber(uint256 newBatchNumber) public onlyOwner {
        currentBatchNumber = newBatchNumber;
    }

    function setMaxTokenSupply(uint256 maxPigskinApeSupply) public onlyOwner {
        maxTokenSupply = maxPigskinApeSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    /*
    * Distribute eth prize to a single addresses
    */
    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    /*
    * Distribute eth prizes to multiple addresses
    */
    function withdrawMultipleForGiveaway(uint256 amount, address[] memory winnerAddresses) public onlyOwner {
        for (uint256 i = 0;  i < winnerAddresses.length; i++) {
            Address.sendValue(payable(winnerAddresses[i]), amount);
            emit PaymentReleased(winnerAddresses[i], amount);
        }
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 5; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    /*
    * Mint reserved NFTs for multiple winner addresses (1 per address)
    */
    function reserveMintMultiple(address[] memory winnerAddresses) public onlyOwner {        
        for (uint256 i = 0; i < winnerAddresses.length; i++) {
            _tokenIdCounter.increment();
            _safeMint(winnerAddresses[i], _tokenIdCounter.current());
        }
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause pre-sale if active, make active if paused.
    */
    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    /*
    * Mint Baller Ape NFTs, woot!
    */
    function adoptApes(uint256 numberOfTokens) public payable {
        require(saleIsActive || (presaleIsActive && pigskinApesContractInstance.balanceOf(msg.sender) > 0), "Sale is not active or your address doesn't own a Pigskin Ape");
        require(totalSupply() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available baller apes");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can only adopt 20 baller apes at a time");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function hashClaim(address buyer, uint256 numberOfMints, uint256 batchNumber) public pure returns (bytes32) {
        return keccak256(abi.encode(
            buyer,
            numberOfMints,
            batchNumber
        ));
    }

    /*
    * For winners to claim free Baller Ape NFTs
    */
    function claimApes(uint256 numberOfMints, uint256 batchNumber, bytes memory signature) public {
        require(currentBatchNumber == batchNumber, "This batch has expired");
        require(!hasClaimed[batchNumber][msg.sender], "This address has already minted");
        bytes32 hashToVerify = hashClaim(msg.sender, numberOfMints, batchNumber);
        require(signerAddress == hashToVerify.toEthSignedMessageHash().recover(signature), "Invalid signature");

        hasClaimed[batchNumber][msg.sender] = true;

        for (uint256 i = 1; i <= numberOfMints; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
