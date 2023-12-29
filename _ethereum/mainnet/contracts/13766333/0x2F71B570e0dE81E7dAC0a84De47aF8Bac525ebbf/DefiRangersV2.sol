// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

/*
    ____       _____    ____                                      _    _____ 
   / __ \___  / __(_)  / __ \____ _____  ____ ____  __________   | |  / /__ \
  / / / / _ \/ /_/ /  / /_/ / __ `/ __ \/ __ `/ _ \/ ___/ ___/   | | / /__/ /
 / /_/ /  __/ __/ /  / _, _/ /_/ / / / / /_/ /  __/ /  (__  )    | |/ // __/ 
/_____/\___/_/ /_/  /_/ |_|\__,_/_/ /_/\__, /\___/_/  /____/     |___//____/ 
                                      /____/                                 
I see you nerd! ⌐⊙_⊙
*/

contract DefiRangersV2 is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 15;

    uint256 public mintPrice = 0.03 ether;

    bool public saleIsActive = false;

    bool public claimingIsActive = false;

    string public baseURI;

    string public provenance;

    address[8] private _shareholders;

    uint[8] private _shares;

    // Mapping from token ID to whether it has been claimed or not
    mapping(uint256 => bool) public hasClaimed;

    IERC721 public genesisContractInstance;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxDefiRangersV2Supply, address genesisContractAddress) ERC721(name, symbol) {
        maxTokenSupply = maxDefiRangersV2Supply;

        _shareholders[0] = 0x5C8465d8eaDd095440deFbB2D2F7a251Fd07352e; // Chris
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0xBd2440e2F8dDc9f03d7E2B37DD9Bb780Cb8eEb7C;
        _shareholders[3] = 0x65131347c08242559e9CBD2e37Dc11b8C88e29C4;
        _shareholders[4] = 0x5B789ddA90988B76Ef4f9Cc0f28f902A35AF8faE;
        _shareholders[5] = 0xd29135dcA9A302C9fCBce48e1c255744aA2bDD78;
        _shareholders[6] = 0x7B2ff47deA4fA2bAC287dC633Dcd5Db5C0c78eD2;
        _shareholders[7] = 0xFccEefbeE0265D638c80c7200Ac6cad5d043c1be;

        _shares[0] = 4900;
        _shares[1] = 3000;
        _shares[2] = 1000;
        _shares[3] = 500;
        _shares[4] = 200;
        _shares[5] = 200;
        _shares[6] = 100;
        _shares[7] = 100;

        genesisContractInstance = IERC721(genesisContractAddress);
    }

    function setGenesisContractAddress(address genesisContractAddress) public onlyOwner {
        genesisContractInstance = IERC721(genesisContractAddress);
    }

    function setMaxTokenSupply(uint256 maxDefiRangersV2Supply) public onlyOwner {
        maxTokenSupply = maxDefiRangersV2Supply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 8; i++) {
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
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause claiming if active, make active if paused.
    */
    function flipClaimingState() public onlyOwner {
        claimingIsActive = !claimingIsActive;
    }

    /*
    * Mint DefiRangersV2 NFTs via claiming via Genesis DefiRangers
    */
    function mintViaClaim(uint256[] calldata tokenIds) public {
        require(claimingIsActive, 'Minting via claims is not live yet');

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(genesisContractInstance.ownerOf(tokenIds[i]) == msg.sender, 'Caller is not owner of the token ID');
            require(! hasClaimed[tokenIds[i]], 'This token has already been claimed');
            hasClaimed[tokenIds[i]] = true;

            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    /*
    * Mint DefiRangersV2 NFTs, woot!
    */
    function publicMint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not live yet");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can mint a max of 15 NFTs at a time");
        require(_tokenIdCounter.current() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available NFTs");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
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
