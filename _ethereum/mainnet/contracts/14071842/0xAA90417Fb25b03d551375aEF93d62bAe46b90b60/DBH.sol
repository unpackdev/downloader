// SPDX-License-Identifier: MIT

/*
                                      DickbuttH
                                  eroesDickbuttHero
                              esDickbuttHeroesDickbutt
                      HeroesDickbuttH           eroesDic
                   kbuttHeroesDi                  ckbuttH
                 eroesDickbuttHe                   roesDi
                 ckbuttHeroesDick                   buttH
                 eroesDickbu ttHero    esDickbuttH  eroes
                 DickbuttHeroesDickb uttHeroesDickbu ttHe
                 roesDickbuttHeroe  sDickbuttHeroesDickbu
                ttHer  oesDickbutt  HeroesDickbuttHeroesD
               ickbuttHeroesDickbut tHeroesDick buttHeroe
              sDickbuttHeroesDick   buttHeroesDickbuttHer
             oesDickbuttHeroesDickbuttHeroesDickb  uttHe
            roesD          ickbuttHeroesDickb     uttHer
           oesDi                      ckbuttH     eroesD
          ickbut                                 tHeroe
         sDickb                                 uttHer
        oesDic                                  kbuttH
        eroes                      Dick        buttHe
        roes                      Dickb utt   Heroes
        Dick                      buttHeroes  Dickb                         uttHeroes
       Dickb                      uttHeroes  Dickb                        uttHeroesDic
       kbutt                     HeroesDick buttH                       eroesD    ickb
       uttHe                     roesDickb  uttHe                     roesDic    kbutt
       Heroe                    sDickbutt  Heroes                   Dickbut     tHero
       esDic                    kbuttHer   oesDickbuttHeroesDic   kbuttHe     roesD
        ickb                   uttHeroe    sDickbuttHeroesDickbuttHeroe      sDick
        butt                   HeroesD     ickbu   ttHer   oesDickbut      tHeroe
        sDic                  kbuttHer      oes   DickbuttHeroesDic      kbuttH
        eroes               Dickb uttHe         roesDickbuttHeroes     Dickbut
         tHer             oesDi  ckbuttH         eroesDickbuttHeroes   Dickbutt
         Heroe            sDickbuttHeroe                     sDickbut    tHeroesDi
          ckbut            tHeroesDickb              uttH       eroesD  ickb uttHe
          roesDi              ckbu                   ttHe        roesDi  ckbuttHe
           roesDi                                ckb              uttHe    roes
            Dickbutt                            Hero              esDic     kbut
               tHeroes                          Dick              buttHeroesDick
     but        tHeroesDic                       kbut           tHeroesDickbutt
    HeroesD    ickbuttHeroesDick                  but         tHeroes    D
    ickbuttHeroesD ickbuttHeroesDickbutt           Hero    esDickb
    uttH eroesDickbuttH    eroesDickbuttHe roesDickbuttHeroesDic
     kbut  tHeroesDic         kbuttHeroes DickbuttHeroesDickb
      uttH   eroesD         ickbuttHeroe sDick buttHeroesD
       ickbuttHer           oesDickbutt  Hero
        esDickb              uttHeroe   sDic
          kbu                ttHero    esDi
                              ckbutt  Hero
                               esDickbutt
                                 HeroesD
                                   ick
*/

pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DBH is ERC721Enumerable, Ownable
{
    uint256 constant NUM_GENS = 3;          // Number of Dickbutt Heroes generations
    uint256 constant TOKENS_PER_GEN = 3333; // Number of tokens per generation

    uint256 public maxPreSaleId = 359;
    uint256 public maxPublicId = TOKENS_PER_GEN;

    uint256 public price = .05 ether;         // .05 ETH mint price
    uint256 public preSalePrice = .025 ether; // .025 ETH pre-sale mint price
    bool public hasSaleStarted = false;       // Sale disabled by default
    bool public hasPreSaleStarted = false;    // Pre-sale disabled by default
    mapping(address => mapping(uint256 => bool)) public hasMintedPreSale;
    string public contractURI;
    string public baseTokenURI;
    address public dojo;

    constructor(string memory _baseTokenURI, string memory _contractURI) ERC721("Dickbutt Heroes", "DBH")
    {
        setBaseTokenURI(_baseTokenURI);
        contractURI = _contractURI;
    }

    /* PUBLIC/EXTERNAL */
    function mint(uint256 quantity) external payable
    {
        require(hasSaleStarted || _msgSender() == owner(), "Sale hasn't started");
        require(quantity > 0 && quantity <= 10, "Quantity must be 1-10");
        require(totalSupply() + 1 <= maxPublicId, "All tokens have been minted");
        require(totalSupply() + quantity <= maxPublicId, "Quantity would exceed supply");
        require(msg.value >= price * quantity || _msgSender() == owner(), "Insufficient Ether sent");

        mintDickbutts(_msgSender(), quantity);
    }

    function preSaleMint(uint256 quantity) external payable
    {
        require(totalSupply() + 1 <= maxPreSaleId, "All pre-sale tokens have been minted");
        require(quantity > 0 && quantity <= 3, "Quantity must be 1-3");
        require(totalSupply() + quantity <= maxPreSaleId, "Quantity would exceed supply");
        if(_msgSender() != owner()) {
            require(hasPreSaleStarted, "Pre-sale hasn't started");
            require(!hasMintedPreSale[_msgSender()][calculateGen(totalSupply() + 1)], "Limit 1 pre-sale mint per address");
            require(msg.value >= preSalePrice * quantity, "Insufficient Ether sent");
        }

        hasMintedPreSale[_msgSender()][calculateGen(totalSupply() + 1)] = true;
        mintDickbutts(_msgSender(), quantity);
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner
    {
        baseTokenURI = _baseTokenURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner
    {
        contractURI = _contractURI;
    }

    function setDojo(address _dojo) external onlyOwner
    {
        dojo = _dojo;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        price = _price;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner
    {
        preSalePrice = _price;
    }

    function setMaxPreSaleId(uint256 newMaxId) external onlyOwner
    {
        require(newMaxId <= TOKENS_PER_GEN * NUM_GENS);
        maxPreSaleId = newMaxId;
    }

    function setMaxPublicId(uint256 newMaxId) external onlyOwner
    {
        require(newMaxId <= TOKENS_PER_GEN * NUM_GENS);
        maxPublicId = newMaxId;
    }

    function flipSaleStatus() external onlyOwner
    {
        hasSaleStarted = !hasSaleStarted;
    }

    function flipPreSaleStatus() external onlyOwner
    {
        hasPreSaleStarted = !hasPreSaleStarted;
    }

    function withdraw(uint256 _amount) external payable onlyOwner
    {
        require(payable(owner()).send(_amount));
    }

    function withdrawAll() external payable onlyOwner
    {
        require(payable(owner()).send(address(this).balance));
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override
    {
        if(_msgSender() == dojo) {
            // Hard-code approval if Dojo is doing the transfer to prevent wasted gas
            _transfer(from, to, tokenId);
        }
        else {
            super.transferFrom(from, to, tokenId);
        }
    }

    /* PRIVATE/INTERNAL */
    function mintDickbutts(address recipient, uint256 quantity) private
    {
        for(uint256 i = 1; i <= quantity; i++) {
            _safeMint(recipient, totalSupply() + 1);
        }
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    function calculateGen(uint256 tokenId) private pure returns (uint256)
    {
        return ((tokenId - 1) / TOKENS_PER_GEN) + 1;
    }
}