// BumbleBeens by Queen Been & Varn (bumblebeens.com)

//..................................................                              ..........
//...................................................                            ...........
//........................................................ ..                 ............. 
//...............                   ............................        ................    
//.....      .                         ....  ...........................................    
//...                                            ......................................     
//..                                           @@@%@@..............................         
//                                      @@@@@@@@@   @@@@@@@@......................          
//                              @@@@     @@   @@@   @@@   @@,.....................          
//                             @@   @@@@@ @@@@@@@@@@@@@@@@@@@@/@@@@@@..............         
//                              @@@   @@@@@@@@@@@@(@@@@@&  @@@@   @@@.................      
//                                @@@@....@@@    @@@    @@...@@@@@@....................     
//..                             @@@..........*#....,@@,.......@@@.....................     
//..                   @@@@@@   @@...............................@@......................   
//...               *@@      &@@@........,@@.......@@@@...........@@@./@@@@@................
//.......   ..      @@        .@@.........@@.......,@@,............@@@      @@@.............
//................   @@@      @@........,,...@@@@.....,,............@@        @@............
//...................,@@@   @@@.....................................,@@     @@@.............
//...............,@@@@     @@,.......................................@@   @@@,..............
//..............@@@/@@(   @@(((,....................................,@@      @@@............
//.............@@@///@@@@@@((((((((((.........................(((((((@@       .@@        ...
//.............@@//////////@@(((((((((((((@@@@@@@((@@@((((((((((((((@@@       @@            
//.............@@@(////////@@(((((((((((@@(*@@//(@@///@@(((((((((((@@& @@@@@@@              
//................@@@@@@@@@@(((((((((((#@@***@@@//////@@@(((((((((@@@                       
//     ..........*@@....@@,...((((((((((@@****@@///&@@@@(((((((((@@@                        
//      .........*@@.....@@(........(((((@@@@@@@@@@((((((((((((@@@..@@.                     
//      ..........@@.......@@,.@@@@@.........((((((((((((((((@@@.....,@@                    
//             ....@@.......@@@    @@.....................@@@..@@@@....@@                   
//              ....@@@....@@@@@@@@@@@...............@@@@@.............@@#                  
//               .....@@@..............@@@@@@@@@@@@@....................@@                  
//              .........@@@..........................@@@@@@@     .@@@@@@@                  
//           ,...........,@@....@@@@@@@@@@&#@@@@@@@@@                               .       
//        ...............@@...@@@...................                            ,...........
//       .............. @@....@@......................       ...........,...................
//      .............  &@@...@@@       .....................................................
//.............        @@....@@           ..................................................

// Development help from @0xFonzy (twitter.com/0xFonzy)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract BumbleBeens is ERC721A, Ownable {
  uint256 public hive = 8335;
  uint256 public adoptPrice = 0.03 ether;
  uint256 public adoptPriceBuzzlist = 0.025 ether;
  uint256 public adoptLimit = 2;
  uint256 public adoptLimitBuzzlist = 2;
  uint256 public adoptPhase = 0;
  bytes32 public buzzlist = 0x0;
  string public beensUrl;
  address private community = 0xcdB405c6a8Bb3A41BCD0b1dDf1A90B939Aa34194;
  address private fonzy = 0x1AF8c7140cD8AfCD6e756bf9c68320905C355658;

  mapping(uint256 => mapping(address => uint256)) public adopted;

  enum AdoptStatus {
    OFF, BUZZLIST, PUBLIC
  }

  AdoptStatus public adoptStatus;

  constructor() ERC721A("BumbleBeens", "BEENS") {}

  function publicAdopt(uint256 beens) public payable isSupplyAvailable(beens) isAdoptable(beens, adoptLimit) {
    require(adoptStatus == AdoptStatus.PUBLIC, "Public adopting has not started");
    require(msg.sender == tx.origin, "Only humans can adopt beens");
    require(msg.value >= adoptPrice * beens, "Insufficient funds for adoption");
    adopted[adoptPhase][msg.sender] += beens;
    _safeMint(msg.sender, beens);
  }

  function buzzlistAdopt(uint256 beens, bytes32[] calldata proof) public payable isSupplyAvailable(beens) isAdoptable(beens, adoptLimitBuzzlist) {
    require(adoptStatus >= AdoptStatus.BUZZLIST, "Buzzlist adopt has not started");
    require(isBuzzlisted(msg.sender, proof), "Account not on the buzzlist");
    require(msg.value >= adoptPriceBuzzlist * beens, "Insufficient funds for buzzlist adoption");
    adopted[adoptPhase][msg.sender] += beens;
    _safeMint(msg.sender, beens);
  }

  modifier isAdoptable(uint256 beens, uint256 limit) {
    require(beens > 0 && adopted[adoptPhase][msg.sender] + beens <= limit, "Adoption limit reached");
    _;
  }

  modifier isSupplyAvailable(uint256 beens) {
    require(totalSupply() + beens <= hive, "Beens supply limit exceeded");
    _;
  }

  function isBuzzlisted(address account, bytes32[] memory proof) public view returns (bool) {
    return MerkleProof.verify(proof, buzzlist, keccak256(abi.encodePacked(account)));
  }

  function queenBeenAdopt(address account, uint256 beens) external isSupplyAvailable(beens) onlyOwner {
    _safeMint(account, beens);
  }

  function setReducedHive(uint256 _hive) external onlyOwner {
    require(_hive <= hive, "Hive supply can not be increased");
    require(_hive >= totalSupply(), "Hive supply can not be lowered");
    hive = _hive;
  }

  function setAdoptionPrice(uint256 _adoptPrice) public onlyOwner {
    adoptPrice = _adoptPrice;
  }

  function setAdoptionPriceBuzzlist(uint256 _adoptPriceBuzzlist) public onlyOwner {
    adoptPriceBuzzlist = _adoptPriceBuzzlist;
  }

  function setAdoptLimit(uint256 _adoptLimit) public onlyOwner {
    adoptLimit = _adoptLimit;
  }

  function setAdoptLimitBuzzlist(uint256 _adoptLimitBuzzlist) public onlyOwner {
    adoptLimitBuzzlist = _adoptLimitBuzzlist;
  }

  function setAdoptStatus(uint256 _adoptStatus) public onlyOwner {
    require(_adoptStatus <= uint256(AdoptStatus.PUBLIC), "Invalid adopt status");
    adoptStatus = AdoptStatus(_adoptStatus);
  }

  function setAdoptPhase(uint256 _adoptPhase) public onlyOwner {
    adoptPhase = _adoptPhase;
  }

  function setBuzzlist(bytes32 _buzzlist) public onlyOwner {
    buzzlist = _buzzlist;
  }

  function setAdoptPhaseDetails(
    uint256 _adoptPhase,
    uint256 _adoptStatus, 
    uint256 _adoptLimit, 
    uint256 _adoptLimitBuzzlist,
    uint256 _adoptPrice,
    uint256 _adoptPriceBuzzlist,
    bytes32 _buzzlist
    ) external onlyOwner {
    setAdoptPhase(_adoptPhase);
    setAdoptStatus(_adoptStatus);
    setAdoptLimit(_adoptLimit);
    setAdoptLimitBuzzlist(_adoptLimitBuzzlist);
    setAdoptionPrice(_adoptPrice);
    setAdoptionPriceBuzzlist(_adoptPriceBuzzlist);
    setBuzzlist(_buzzlist);
  }

  function setBeensUrl(string memory _beensUrl) external onlyOwner {
    beensUrl = _beensUrl;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return beensUrl;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(community), (balance * 90) / 100);
    Address.sendValue(payable(fonzy),     (balance * 10) / 100);
  }
}