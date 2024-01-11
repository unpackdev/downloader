// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
        ,----,                                                                                                                                                                                                               
      ,/   .`|                                                                                                                                                                                                               
    ,`   .'  :                   ,--,              ,--,              ,--,              ,--,              ,--,              ,--,              ,--,              ,--,              ,--,              ,--,              ,--,    
  ;    ;     /                 ,--.'|            ,--.'|            ,--.'|            ,--.'|            ,--.'|            ,--.'|            ,--.'|            ,--.'|            ,--.'|            ,--.'|            ,--.'|    
.'___,/    ,' __  ,-.   ,---.  |  | :     ,---.  |  | :     ,---.  |  | :     ,---.  |  | :     ,---.  |  | :     ,---.  |  | :     ,---.  |  | :     ,---.  |  | :     ,---.  |  | :     ,---.  |  | :     ,---.  |  | :    
|    :     |,' ,'/ /|  '   ,'\ :  : '    '   ,'\ :  : '    '   ,'\ :  : '    '   ,'\ :  : '    '   ,'\ :  : '    '   ,'\ :  : '    '   ,'\ :  : '    '   ,'\ :  : '    '   ,'\ :  : '    '   ,'\ :  : '    '   ,'\ :  : '    
;    |.';  ;'  | |' | /   /   ||  ' |   /   /   ||  ' |   /   /   ||  ' |   /   /   ||  ' |   /   /   ||  ' |   /   /   ||  ' |   /   /   ||  ' |   /   /   ||  ' |   /   /   ||  ' |   /   /   ||  ' |   /   /   ||  ' |    
`----'  |  ||  |   ,'.   ; ,. :'  | |  .   ; ,. :'  | |  .   ; ,. :'  | |  .   ; ,. :'  | |  .   ; ,. :'  | |  .   ; ,. :'  | |  .   ; ,. :'  | |  .   ; ,. :'  | |  .   ; ,. :'  | |  .   ; ,. :'  | |  .   ; ,. :'  | |    
    '   :  ;'  :  /  '   | |: :|  | :  '   | |: :|  | :  '   | |: :|  | :  '   | |: :|  | :  '   | |: :|  | :  '   | |: :|  | :  '   | |: :|  | :  '   | |: :|  | :  '   | |: :|  | :  '   | |: :|  | :  '   | |: :|  | :    
    |   |  '|  | '   '   | .; :'  : |__'   | .; :'  : |__'   | .; :'  : |__'   | .; :'  : |__'   | .; :'  : |__'   | .; :'  : |__'   | .; :'  : |__'   | .; :'  : |__'   | .; :'  : |__'   | .; :'  : |__'   | .; :'  : |__  
    '   :  |;  : |   |   :    ||  | '.'|   :    ||  | '.'|   :    ||  | '.'|   :    ||  | '.'|   :    ||  | '.'|   :    ||  | '.'|   :    ||  | '.'|   :    ||  | '.'|   :    ||  | '.'|   :    ||  | '.'|   :    ||  | '.'| 
    ;   |.' |  , ;    \   \  / ;  :    ;\   \  / ;  :    ;\   \  / ;  :    ;\   \  / ;  :    ;\   \  / ;  :    ;\   \  / ;  :    ;\   \  / ;  :    ;\   \  / ;  :    ;\   \  / ;  :    ;\   \  / ;  :    ;\   \  / ;  :    ; 
    '---'    ---'      `----'  |  ,   /  `----'  |  ,   /  `----'  |  ,   /  `----'  |  ,   /  `----'  |  ,   /  `----'  |  ,   /  `----'  |  ,   /  `----'  |  ,   /  `----'  |  ,   /  `----'  |  ,   /  `----'  |  ,   /  
                                ---`-'            ---`-'            ---`-'            ---`-'            ---`-'            ---`-'            ---`-'            ---`-'            ---`-'            ---`-'            ---`-'                                                                                                                                                                                                                                                                                                                                                                                                                                        
*/                 



import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC2981.sol";

contract NGMITrolls is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    
  using Strings for uint256;
  string public provenanceHash;
  uint256 constant MAX_SUPPLY = 5000; 
  uint256 public maxAmount = 5;
  uint256 private _currentId; 
  string public baseURI;
  string private _contractURI;
  bool public isActive = false; 
  mapping(address => uint256) private _alreadyMinted;
  address public beneficiary; 

  constructor(
    address _beneficiary,
    string memory _initialBaseURI,
    string memory _initialContractURI
  ) ERC721A("NGMI Trolls", "TROLLZ") {
    beneficiary = _beneficiary;
    baseURI = _initialBaseURI;
    _contractURI = _initialContractURI;
  }

  // Setters

  function setProvenanceHash(string calldata hash) public onlyOwner {
    provenanceHash = hash;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setMaxAmount(uint256 _maxAmount) public onlyOwner {
    maxAmount = _maxAmount;
  }

  function setActive() public onlyOwner {
    isActive = !isActive;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function setContractURI(string memory uri) public onlyOwner {
    _contractURI = uri;
  }

  // Getters

    function alreadyMinted(address addr) public view returns (uint256) {
    return _alreadyMinted[addr];
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  // Minting

  function mintPublic(
    uint256 amount
  ) public nonReentrant {
    address sender = _msgSender();

    require(isActive, "Sale is closed");
    require(amount <= maxAmount - _alreadyMinted[sender], "Insufficient mints left for this wallet");
    require(msg.sender == tx.origin, "No minting from smart contracts");

    _alreadyMinted[sender] += amount;
    _internalMint(sender, amount);
  }

  function ownerMint(address to, uint256 amount) public onlyOwner {
    _internalMint(to, amount); 
  }

  // Withdraw Any Deposited Funds

  function withdraw() public onlyOwner {
    payable(beneficiary).transfer(address(this).balance);
  }

  // Private

  function _internalMint(address to, uint amount) private {
    require(_currentId + amount <= MAX_SUPPLY, "Will exceed maximum supply");
    _currentId += amount;
    _safeMint(to, amount);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // IERC2981

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
    _tokenId; 
    royaltyAmount = (_salePrice / 100) * 5; 
    return (beneficiary, royaltyAmount);
  }
}