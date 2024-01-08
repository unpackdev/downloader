// SPDX-License-Identifier: MIT

/*
                                      DickbuttP
                                  unksDickbuttPunks
                              DickbuttPunksDickbuttPun
                      ksDickbuttPunks           Dickbutt
                   PunksDickbutt                  PunksDi
                 ckbuttPunksDick                   buttPu
                 nksDickbuttPunks                   Dickb
                 uttPunksDic kbuttP    unksDickbut  tPunk
                 sDickbuttPunksDickb uttPunksDickbut tPun
                 ksDickbuttPunksDi  ckbuttPunksDickbuttPu
                nksDi  ckbuttPunks  DickbuttPunksDickbutt
               PunksDickbuttPunksDi ckbuttPunks DickbuttP
              unksDickbuttPunksDi   ckbuttPunksDickbuttPu
             nksDickbuttPunksDickbuttPunksDickbut  tPunk
            sDick          buttPunksDickbuttP     unksDi
           ckbut                      tPunksD     ickbut
          tPunks                                 Dickbu
         ttPunk                                 sDickb
        uttPun                                  ksDick
        buttP                      unks        Dickbu
        ttPu                      nksDi ckb   uttPun
        ksDi                      ckbuttPunk  sDick                         buttPunks
       Dickb                      uttPunksD  ickbu                        ttPunksDickb
       uttPu                     nksDickbut tPunk                       sDickb    uttP
       unksD                     ickbuttPu  nksDi                     ckbuttP    unksD
       ickbu                    ttPunksDi  ckbutt                   PunksDi     ckbut
       tPunk                    sDickbut   tPunksDickbuttPunksD   ickbutt     Punks
        Dick                   buttPunk    sDickbuttPunksDickbuttPunksD      ickbu
        ttPu                   nksDick     buttP   unksD   ickbuttPun      ksDick
        butt                  PunksDic      kbu   ttPunksDickbuttPu      nksDic
        kbutt               Punks Dickb         uttPunksDickbuttPu     nksDick
         butt             Punks  Dickbut         tPunksDickbuttPunks   Dickbutt
         Punks            DickbuttPunksD                     ickbuttP    unksDickb
          uttPu            nksDickbuttP              unks       Dickbu  ttPu nksDi
          ckbutt              Punk                   sDic        kbuttP  unksDick
           buttPu                                nks              Dickb    uttP
            unksDick                            butt              Punks     Dick
               buttPun                          ksDi              ckbuttPunksDic
     kbu        ttPunksDic                       kbut           tPunksDickbuttP
    unksDic    kbuttPunksDickbut                  tPu         nksDick    b
    uttPunksDickbu ttPunksDickbuttPunksD           ickb    uttPunk
    sDic kbuttPunksDick    buttPunksDickbu ttPunksDickbuttPunksD
     ickb  uttPunksDi         ckbuttPunks DickbuttPunksDickbu
      ttPu   nksDic         kbuttPunksDi ckbut tPunksDickb
       uttPunksDi           ckbuttPunks  Dick
        buttPun              ksDickbu   ttPu
          nks                Dickbu    ttPu
                              nksDic  kbut
                               tPunksDick
                                 buttPun
                                   ksD
*/

pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";

contract DBPNKS is ERC721, Ownable
{
    uint16 public constant MAX_DICKS = 5000; // We're gonna make 5k dicks

    uint16 public nextPreSaleTokenId = 51;
    uint16 public nextPublicTokenId = 201;
    uint128 public price = .05 ether;        // .05 ETH mint price
    uint128 public preSalePrice = .04 ether; // .04 pre-sale ETH mint price
    bool public hasSaleStarted = false;      // Sale disabled by default
    bool public hasPreSaleStarted = false;   // Pre-sale disabled by default
    string public contractURI;
    string public baseTokenURI;

    constructor(string memory _baseTokenURI, string memory _contractURI) ERC721("DickbuttPunks", "DBPNKS")
    {
        setBaseTokenURI(_baseTokenURI);
        contractURI = _contractURI;

        // DickbuttPunks 26-50 (25 total) reserved for free giveaways
        // Mint 5 immediately for promotions
        for(uint256 i = 26; i <= 30; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function mint(uint256 quantity) public payable
    {
        require(hasSaleStarted || msg.sender == owner(), "Sale hasn't started");
        require(quantity > 0 && quantity <= 40, "Quantity must be 1-40");
        require(nextPublicTokenId <= MAX_DICKS, "All tokens have been minted");
        require(nextPublicTokenId + quantity - 1 <= MAX_DICKS, "Quantity would exceed supply");
        require(msg.value >= price * quantity || msg.sender == owner(), "Insufficient Ether sent");

        for(uint256 i = 1; i <= quantity; i++) {
            _safeMint(msg.sender, nextPublicTokenId);
            nextPublicTokenId++;
        }
    }

    function preSaleMint(uint256 quantity) public payable
    {
        require(hasPreSaleStarted || msg.sender == owner(), "Pre-sale hasn't started");
        require(quantity > 0 && quantity <= 10, "Quantity must be 1-10");
        require(nextPreSaleTokenId <= 200, "All pre-sale tokens have been minted");
        require(nextPreSaleTokenId + quantity - 1 <= 200, "Quantity would exceed pre-sale supply");
        require(msg.value >= preSalePrice * quantity || msg.sender == owner(), "Insufficient Ether sent");

        for(uint256 i = 1; i <= quantity; i++) {
            _safeMint(msg.sender, nextPreSaleTokenId);
            nextPreSaleTokenId++;
        }
    }

    function devMint(address receiver, uint256 tokenId) public payable onlyOwner
    {
        require(tokenId >= 1 && tokenId <= 50, "ID must be 1-50");
        _safeMint(receiver, tokenId);
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner
    {
        baseTokenURI = _baseTokenURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner
    {
        contractURI = _contractURI;
    }

    function setPrice(uint128 _price) public onlyOwner
    {
        price = _price;
    }

    function setPreSalePrice(uint128 _price) public onlyOwner
    {
        preSalePrice = _price;
    }

    function flipSaleStatus() public onlyOwner
    {
        hasSaleStarted = !hasSaleStarted;
    }

    function flipPreSaleStatus() public onlyOwner
    {
        hasPreSaleStarted = !hasPreSaleStarted;
    }

    function withdraw(uint256 _amount) public payable onlyOwner
    {
        require(payable(owner()).send(_amount));
    }

    function withdrawAll() public payable onlyOwner
    {
        require(payable(owner()).send(address(this).balance));
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }
}