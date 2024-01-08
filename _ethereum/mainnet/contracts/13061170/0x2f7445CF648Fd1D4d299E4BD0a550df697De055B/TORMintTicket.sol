// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

/*
              ________________       _,.......,_        
          .nNNNNNNNNNNNNNNNNP’  .nnNNNNNNNNNNNNnn..
         ANNC*’ 7NNNN|’’’’’’’ (NNN*’ 7NNNNN   `*NNNn.
        (NNNN.  dNNNN’        qNNN)  JNNNN*     `NNNn
         `*@*’  NNNNN         `*@*’  dNNNN’     ,ANNN)
               ,NNNN’  ..-^^^-..     NNNNN     ,NNNNN’
               dNNNN’ /    .    \   .NNNNP _..nNNNN*’
               NNNNN (    /|\    )  NNNNNnnNNNNN*’
              ,NNNN’ ‘   / | \   ’  NNNN*  \NNNNb
              dNNNN’  \  \'.'/  /  ,NNNN’   \NNNN.
              NNNNN    '  \|/  '   NNNNC     \NNNN.
            .JNNNNNL.   \  '  /  .JNNNNNL.    \NNNN.             .
          dNNNNNNNNNN|   ‘. .’ .NNNNNNNNNN|    `NNNNn.          ^\Nn
                           '                     `NNNNn.         .NND
                                                  `*NNNNNnnn....nnNP’
                                                     `*@NNNNNNNNN**’
*/

contract TORMintTicket is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public mintPrice = 69000000 gwei; // 0.069 ETH

    bool public saleIsActive = false;

    string public baseURI;

    mapping (address => bool) private _minters;

    address[5] private _shareholders;

    uint[5] private _shares;

    address private _torContractAddress;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxMintPassSupply) ERC721(name, symbol) {
        maxTokenSupply = maxMintPassSupply;

        _shareholders[0] = 0x689018A9e2073d9A8530dA969B735F313636553b; // JJ
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0x7Dcb39fe010A205f16ee3249F04b24d74C4f44F1; // Belfort
        _shareholders[3] = 0x74a2acae9B92781Cbb1CCa3bc667c05313e14850; // Cam
        _shareholders[4] = 0xD9D2E67b1695492B870165FD852CF07576f911B3; // Jagger

        _shares[0] = 6270;
        _shares[1] = 1250;
        _shares[2] = 1180;
        _shares[3] = 650;
        _shares[4] = 650;
    }

    function setMaxTokenSupply(uint256 maxMintPassSupply) public onlyOwner {
        maxTokenSupply = maxMintPassSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function setTorContractAddress(address torContractAddress) public onlyOwner {
        _torContractAddress = torContractAddress;
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
    function reserveMint(uint256 reservedAmount) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(msg.sender, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function canMint(address owner) public view returns (bool) {
        return !_minters[owner];
    }

    /*
    * Mint tickets, woo!
    */
    function mintTicket() public payable {
        require(saleIsActive, "Sale must be active to mint tickets");
        require(_tokenIdCounter.current() + 1 <= maxTokenSupply, "Purchase would exceed max available tickets");
        require(mintPrice <= msg.value, "Ether value sent is not correct");
        require(!_minters[msg.sender], "You can only mint 1 ticket per wallet");

        _minters[msg.sender] = true;
        _safeMint(msg.sender, _tokenIdCounter.current() + 1);
        _tokenIdCounter.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(tx.origin, tokenId) && msg.sender == _torContractAddress, "Caller is not owner nor approved");
        _burn(tokenId);
    }
}
