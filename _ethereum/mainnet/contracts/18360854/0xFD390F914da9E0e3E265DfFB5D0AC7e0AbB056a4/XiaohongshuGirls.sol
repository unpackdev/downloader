//
//               .&@@P                   !@@@7   .G&&&&&####&&&&&B.              Y@@&      :B@@@&Y^   
//               .&@@5                  ^@@@?     G#####@@@@#####B.     .^:::::::G@@&~::::::^!JG@@B.  
//               .&@@5      ..         ~@@@!  ?GJ:      P@@B            #@@@@@@@@@@@@@@@@@@@@@? .~    
//      .GP?.    .&@@5    ^B@&.       !@@&^  P@@&:      P@@B            ^!!!!!!~~B@@&7~!!~?@@@!       
//      J@@@~    .&@@5    :@@@B      G@@@&B#&@@B.       P@@B                     J@@#     .@@@:       
//     :@@@G     .&@@5     ~@@@Y     J&&BG&@@@Y         P@@B           ..........5@@&.... 7@@&:...    
//     #@@&:     .&@@5      J@@@!        !&@&!          P@@B          P@@@@@@@@@@@@@@@@@@@@@@@@@@@7   
//    G@@@!      .&@@5       G@@&.     .P@@B: :!7       P@@B          !5YYYYYYYYY#@@@5YYYYYYYY5@@@!   
//  .B@@@J       .&@@5       .&@@B   :5@@@@&&@@@#       P@@B                     Y@@#          &@@^   
//  P@@@J        .&@@5        !@@@!  ^@@@&#B57^.        P@@B                     Y@@#         :@@&.   
//   ^P!          &@@5         5P^    ..     .~?^       5@@B                     Y@@#    :7!!?#@@P    
//          .....!@@@Y               ^7J5B&&@@@@?!JJJJJJ&@@&J?JJJJ7              Y@@#    ~@@@@@&5.    
//          B@@@@@@@&:               B@@@&#GY7^..#@@@@@@@@@@@@@@@@&.             Y@@&     .:...       
//          ^5555YJ~.                .:..        ..................              !##5                 
//                                                                                                    
//                                                                                                    
//                        ...                                                                         
//                       .^     ..:::::::^^.                                       .                  
//                       :7^7JY?~:..     .?&#~                                 7#&&#^                 
//                     .?B&#J:            ^@@G                               .P@@@#^                  
//                  .?#@@5:....        .^5@@B: .~7^                         :#@@@5.                   
//                :5@@@P.     ..::^^~7?YYJ~.  .#@@@!                       !&@@&7                     
//               J@@@#^                        ~55!                       Y@@@B:                      
//              G@@@B.             ..                                   .B@@@5                        
//             J@@@&:           ^G&@&^                        ..:.     ~&@@&!      .....              
//            .B@@@P           ?@@@&~    ^G##G:     ~B&&#7..J&@@G.    J@@@B:    .JBJ:.:P&B~           
//             G@@@G         .5@@@P.    ?@@@#^     J@@@&?::Y@@@B.   .G@@@Y     ^&@@^   ?@@#.          
//             .B@@@5.     .:G@@@5    .G@@@Y     .P@@@B!.  !@@@G.  ~&@@&~      ?@@@B.  5BP^    .:     
//       :?Y?.   ^JPB57^:. ^#@@&!    ~&@@&~     :#@@@5:     :JPP7~5@@@B.   ^~~~.!&@@&!       .:.      
//      :&@@@J            Y@@&Y.    7@@@B.    .Y@@@&7            Y@@@Y   :#@@@J  .G@@@7    .^^        
//      ^@@&~           7&@#?.     !@@@P.   .!B@@@B:            J@@@?    P@B7~.   .&@@?  .^:          
//       !&&!        :?GBJ:        ?@@@^ .:^!B@@@Y              B@@B. .::~B5     .Y@@P:::.            
//         :!~:::::^~~^.            ~YY!:.  :!!!^               .?5J^:.    :^::^!J5?^.                
//                                                                                                                                                                                                        
//                                                          
//                                    Creadted By Orbs                             
//                            
//
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract XiaohongshuGirls is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  bytes32 public remiliaMerkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public remiliasaleClaimed;
  mapping(address => bool) public whitelistedAddresses;
  mapping(address => bool) public remiliasaleAddresses;


  string public uriPrefix = 'ipfs:///';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public whitelistCost;
  uint256 public remiliaCost;
  uint256 public maxSupply;
  uint256 public totalWhitelistMinted;
  uint256 public whitelistSaleLimit = 500;
  uint256 public maxMintAmountPerTxPublic;
  uint256 public maxMintAmountPerTxRemilia;
  uint256 public maxMintAmountPerTxWhitelist;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public remiliaSaleEnabled = false;
  bool public revealed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _whitelistCost,
    uint256 _remiliaCost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTxPublic,
    uint256 _maxMintAmountPerTxRemilia,
    uint256 _maxMintAmountPerTxWhitelist,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    setWhitelistCost(_whitelistCost);
    setRemiliaCost(_remiliaCost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTxPublic(_maxMintAmountPerTxPublic);
    setMaxMintAmountPerTxRemilia(_maxMintAmountPerTxRemilia);
    setMaxMintAmountPerTxWhitelist(_maxMintAmountPerTxWhitelist);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount, uint256 _maxMintAmountPerTx) {
    require(_mintAmount > 0 && _mintAmount <= _maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  
  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount, maxMintAmountPerTxPublic) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!'); // Checks if enough Ether was sent
    require(!paused, 'Minting is paused'); // Additional check if you want to include pausing functionality
    _safeMint(_msgSender(), _mintAmount);

  }

   function addToWhitelist(address[] memory _addresses) public onlyOwner {
   for (uint256 i = 0; i < _addresses.length; i++) {
     whitelistedAddresses[_addresses[i]] = true;
     whitelistClaimed[_addresses[i]] = false; 
   }
  }

  function addToRemiliaSale(address[] memory _addresses) public onlyOwner {
   for (uint256 i = 0; i < _addresses.length; i++) {
     remiliasaleAddresses[_addresses[i]] = true;
     remiliasaleClaimed[_addresses[i]] = false; 
   }
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount, maxMintAmountPerTxWhitelist) {
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    require(totalWhitelistMinted + _mintAmount <= whitelistSaleLimit, 'Whitelist sale limit reached');
    require(msg.value >= whitelistCost * _mintAmount, 'Insufficient funds for whitelist price!');
      
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    
    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);

    totalWhitelistMinted += _mintAmount;

  }

  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setWhitelistCost(uint256 _whitelistCost) public onlyOwner {
    whitelistCost = _whitelistCost;
  }

  function setRemiliaCost(uint256 _remiliaCost) public onlyOwner {
    remiliaCost = _remiliaCost;
  }

  function setRemiliaSaleEnabled(bool _state) public onlyOwner {
    remiliaSaleEnabled = _state;
  }

  function remiliaMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount, maxMintAmountPerTxRemilia) {
    require(!remiliasaleClaimed[_msgSender()], 'Address already claimed!');
    require(msg.value >= remiliaCost * _mintAmount, 'Insufficient funds for Remilia price!');
    require(remiliaSaleEnabled, 'The Remilia sale is not enabled!');
  
    
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, remiliaMerkleRoot, leaf), 'Invalid proof!');
 
    remiliasaleClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }





  function setMaxMintAmountPerTxPublic(uint256 _amount) public onlyOwner {
    maxMintAmountPerTxPublic = _amount;
  }

  function setMaxMintAmountPerTxRemilia(uint256 _amount) public onlyOwner {
    maxMintAmountPerTxRemilia = _amount;
  }

  function setMaxMintAmountPerTxWhitelist(uint256 _amount) public onlyOwner {
    maxMintAmountPerTxWhitelist = _amount;
  }


  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setRemiliaMerkleRoot(bytes32 _remiliaMerkleRoot) public onlyOwner {
    remiliaMerkleRoot = _remiliaMerkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner { 
    whitelistMintEnabled = _state;
  }

  

  function withdraw() public onlyOwner nonReentrant {
    
    // =============================================================================
    
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}
