/*
███╗   ███╗███████╗████████╗ █████╗ ██╗   ██╗███████╗██████╗ ███████╗██╗   ██╗███████╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██║   ██║██╔════╝
██╔████╔██║█████╗     ██║   ███████║██║   ██║█████╗  ██████╔╝███████╗██║   ██║███████╗
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██║   ██║╚════██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║ ╚████╔╝ ███████╗██║  ██║███████║╚██████╔╝███████║
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚══════╝
Art, Direction and Webdesign by Mankind
Contract and Web Development by @Tumtum2814 of CryptidLabs.Xyz

*/



// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

contract MetaversusVotingMachine is ERC721Enumerable, PaymentSplitter, Ownable {
  using Strings for uint256;


  bool public _isVotingActive = false;
  bool public _isBaseUriSet = false;
  
  uint256 public constant MAX_SUPPLY = 120;// Max supply

  uint256 public PRICE = 0.44 ether;

  uint256 private _TokenId = 0;

  string private _baseUri = "https://www.ipfs.infura.io/ipfs/QmQqxwdn5yuyfRMH8Lf6XDmqoFVaPjiS6QovjqNswSG3AF/";

  uint256 public Vogu = 0;
  uint256 public Animeta = 0;

  uint256 private _winnerset = 0;
  
  mapping(uint => uint) public vote_outcome;

  event Vote(address _to, uint256 _amount, string _project, uint256 _votecount);

  constructor(address[] memory payees, uint256[] memory shares) ERC721("Metaversus_Animeta_VS_Vogu", "MVAVV") PaymentSplitter(payees, shares) {}

  function vote(uint256 amount, uint256 project) public payable {
    require(_isVotingActive, "MetaversusVotingMachine: sale is not active");
    require(amount > 0, "MetaversusVotingMachine: must mint more than 0");
    require(amount <= 5, "MetaversusVotingMachine: must mint fewer than or equal to 5");
    require(_TokenId < MAX_SUPPLY, "MetaversusVotingMachine: sale has ended");
    require(_TokenId + amount <= MAX_SUPPLY, "MetaversusVotingMachine: exceeds max supply");
    require(amount * PRICE == msg.value, "MetaversusVotingMachine: must send correct ETH amount");
    

    for (uint i = 0; i < amount; i++) {
      _TokenId = _TokenId + 1;
        if (project == 2){
          vote_outcome[_TokenId] = 2;}
        else if (project == 1){
          vote_outcome[_TokenId] = 1;}
      _mint(msg.sender, _TokenId);
    }
    if (project == 2){
      Vogu = Vogu + amount;
      emit Vote(msg.sender, amount, "Vogu", Vogu);
      if (Vogu >= 61 &&  _winnerset == 0){
        setBaseURII('https://www.ipfs.infura.io/ipfs/QmWordrbJkmkXWSefbAuRYCPNTfmdGqFDoSSRXqernjYqb/');
        _winnerset = 1;
      }
    }
    else if (project == 1){
      Animeta = Animeta + amount;
      emit Vote(msg.sender, amount, "Animeta", Animeta);
      if (Animeta >= 61 && _winnerset == 0){
        setBaseURII('https://www.ipfs.infura.io/ipfs/Qmd6v2Wd9XY1EQSdnbp55hRbjGYoxy96kDjdFR3GBszYtt/');
        _winnerset = 1;
      }
    }
    else{
      revert("You tried to vote for a nonexistent side!");
    }

  }


  function toggleVoting() public onlyOwner {

    _isVotingActive = !_isVotingActive;
  }

  function endVoting() public onlyOwner {

    _isVotingActive = false;
  }

  function setBaseURI(string memory baseUri) public onlyOwner {

    _baseUri = baseUri;
  }
  function setBaseURII(string memory baseUri) internal{

    _baseUri = baseUri;
    _isBaseUriSet = true;
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseUri;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "MetaversusVotingMachine: URI query for nonexistent token");


    string memory baseURI = _baseURI();
    string memory votec = vote_outcome[tokenId].toString();
    if (_winnerset == 1){
      return string(abi.encodePacked(baseURI,votec,'/', tokenId.toString()));
    }
    else{
      return string(abi.encodePacked(baseURI,tokenId.toString()));
    }
  }
  
  

  function withdraw(address _target) public onlyOwner {
    payable(_target).transfer(address(this).balance);
  }
}