// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";

// ____________      ______________   ____________      ______________   __
//|        \   \    /  |       \   |_/  \   _  \  \    /  |       \   |_/  \
//|   ___   |   |  |   |    ____|     __|  |_|  |  |  |   |    ____|      __|
//|  |   |  |   |  |   |   |         /         /   |  |   |   |          /
//|  |___|  |   |__|   |   |____     \__    _  \   |__|   |   |____      \__
//|         |          |        |   _   |  |_|  |         |        |    _   |
//|________/__________/________/___| \__|_______/_________/________/___| \__|

contract DuckBuckNFT is ERC721Enumerable, Ownable  {
  uint public constant ADOPTION_CAPACITY = 30;
  uint public constant ADOPTION_ENERGY_COST = 66900000000000000; //0.0669 ETH
  uint public constant DUCKS_IN_A_ROW_COST = 60210000000000000; //0.06021 ETH
  uint public constant PEKING_PLATTER_COST = 53520000000000000; //0.05352 ETH
  uint public constant BAD_MOTHER_DUCKER_COST = 46830000000000000; //0.04683 ETH
  uint public constant MOBY_DUCK_COST = 10000000000000000000; //10 ETH

  string public DBNFT_PROVENANCE = "";
  using Counters for Counters.Counter;

  Counters.Counter private _duckCounter;
  Counters.Counter private _youABadMotherDucker;
  Counters.Counter private _whaleHarpoons;

  uint private _totalDucks;
  uint private _totalBadMotherDuckers;
  uint private _totalMobyDucks;
  uint private _ducksInARowQty;
  uint private _pekingDuckPlatterQty;
  uint private _badMotherDuckerQty;
  bool private _isAdopting;

  mapping (address => uint256) private _badMotherDuckers;

  mapping (address => uint256) private _mobyDucks;

  mapping (uint => uint) private _studFees;

  constructor() ERC721("Duck Buck NFT", "DBNFT") {
    _totalDucks = 10200;
    _totalBadMotherDuckers = 50;
    _totalMobyDucks = 5;
    _ducksInARowQty = 10;
    _pekingDuckPlatterQty = 20;
    _badMotherDuckerQty = 30;
  }

  function adoptSomeDucks(uint _ducks) external payable {
    require(_isAdopting, "Adoption agency is closed.");
    require(_ducks >= 1, "You can''t adopt less than 1 duck, you silly goose!");
    require(_duckCounter.current() <= _totalDucks, "We''re all out of ducks to give!");
    require(_ducks <= ADOPTION_CAPACITY, "Your living situation is not suitable for that many ducks!");
    require(_duckCounter.current() + _ducks <= _totalDucks, "We''re running out of ducks to give!  Select less ducks to adopt!");
    require(msg.value >= ADOPTION_ENERGY_COST * _ducks, "More ether needed to adopt ducks!");

    adoptionPaperwork(_ducks);
  }

  function ducksInARow() external payable {
    require(_isAdopting, "Adoption agency is closed.");
    require(_duckCounter.current() <= _totalDucks, "We''re all out of ducks to give!");
    require((_duckCounter.current() + _ducksInARowQty) <= _totalDucks, "We''re running out of ducks to give!  You took too long to get your ducks in a row!");
    require(msg.value >= DUCKS_IN_A_ROW_COST * _ducksInARowQty, "More ether needed to adopt ducks!");

    adoptionPaperwork(_ducksInARowQty);
  }

  function pekingDuckPlatter() external payable {
    require(_isAdopting, "Adoption agency is closed.");
    require(_duckCounter.current() <= _totalDucks, "We''re all out of ducks to give!");
    require((_duckCounter.current() + _pekingDuckPlatterQty) <= _totalDucks, "We''re running out of ducks to give!  No more platters can be cooked up.");
    require(msg.value >= PEKING_PLATTER_COST * _pekingDuckPlatterQty, "More ether needed to adopt ducks!");

    adoptionPaperwork(_pekingDuckPlatterQty);
  }

  function badMotherDucker() external payable {
    require(_isAdopting, "Adoption agency is closed.");
    require(_duckCounter.current() <= _totalDucks, "We''re all out of ducks to give!");
    require(_badMotherDuckers[msg.sender] <= 0, "You are a known Bad Mother Ducker.  Don''t be greedy.");
    require((_duckCounter.current() + _badMotherDuckerQty) <= _totalDucks, "We''re running out of ducks to give!  Apparently you aren''t a Bad Mother Ducker.");
    require(_youABadMotherDucker.current() <= _totalBadMotherDuckers, "We''ve hit our limit of Bad Mother Duckers!  You a Sad Mother Ducker!");
    require(msg.value >= BAD_MOTHER_DUCKER_COST * _badMotherDuckerQty, "More ether needed to adopt ducks!");

    adoptionPaperwork(_badMotherDuckerQty);
    _youABadMotherDucker.increment();
    _badMotherDuckers[msg.sender] += 1;

    emit BadMotherDucker(msg.sender);
  }

  function mobyDuck() external payable {
    require(_isAdopting, "Adoption agency is closed.");
    require(_duckCounter.current() <= _totalDucks, "We''re all out of ducks to give!");
    require(_mobyDucks[msg.sender] <= 0, "We love our whales!  Save some krill for others.");
    require((_duckCounter.current() + _badMotherDuckerQty) <= _totalDucks, "We''re running out of ducks to give!  Apparently you aren''t a Moby Duck.");
    require(_whaleHarpoons.current() <= _totalMobyDucks, "We''ve run out of harpoons!  Find another way!");
    require(msg.value >= MOBY_DUCK_COST, "More ether needed to adopt ducks!");

    adoptionPaperwork(_badMotherDuckerQty);
    _whaleHarpoons.increment();
    _mobyDucks[msg.sender] += 1;

    emit MobyDuck(msg.sender);
  }

  function adoptionPaperwork(uint _ducks) internal {
    for (uint i = 0; i < _ducks; i++) {
      _duckCounter.increment();
      _safeMint(msg.sender, _duckCounter.current());
    }
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://duckbucknft.com/tokens/";
  }

  function isABadMotherDucker(address potentialMotherDucker) external view returns (bool) {
    return _badMotherDuckers[potentialMotherDucker] > 0;
  }

  function isAMobyDuck(address potentialMobyDuck) external view returns (bool) {
    return _mobyDucks[potentialMobyDuck] > 0;
  }

  function setStudFee(uint feeInWei, uint tokenId) external {
    require(tokenId > 0, "Token id is invalid");
    require(tokenId <= _totalDucks, "Token id is too big.");
    require(ownerOf(tokenId) == msg.sender, "Only the owner of a token may set the stud fee.");

    _studFees[tokenId] = feeInWei;
  }

  function getStudFee(uint tokenId) external view returns (uint) {
    require(tokenId > 0, "Token id is invalid.");
    require(tokenId <= _totalDucks, "Token id is too big.");

    return _studFees[tokenId];
  }

  // Duck God Functions
  function withdraw(address recipient, uint amountToCredit) external onlyOwner {
    require(amountToCredit > 0, "Credit amount must be a postive integer.");
    require(amountToCredit <= address(this).balance, "Credit amount must be less than or equal to the balance of the contract.");
    payable(recipient).transfer(amountToCredit);
  }

  function setAdopting(bool isAdopting) external onlyOwner {
    _isAdopting = isAdopting;
  }

  function getAdopting() external view returns (bool) {
    return _isAdopting;
  }

  function reserveDucks() external onlyOwner {
      for (uint i = 0; i < 200; i++) {
        _duckCounter.increment();
        _safeMint(msg.sender, _duckCounter.current());
      }
  }

  //Provenance?  I thought you said Providence!  Gahhh!
  function setProvenanceHash(string memory provenanceHash) external onlyOwner {
      DBNFT_PROVENANCE = provenanceHash;
  }

  function getPurchasedBadMotherDuckers() public view returns (uint) {
    return _youABadMotherDucker.current();
  }

  function getPurchasedWhaleHarpoons() public view returns (uint){
    return _whaleHarpoons.current();
  }

  event BadMotherDucker(address indexed from);

  event MobyDuck(address indexed from);
}
