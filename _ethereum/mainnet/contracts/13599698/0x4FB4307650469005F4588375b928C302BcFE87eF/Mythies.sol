// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

contract Mythies is ERC721Enumerable, ERC721URIStorage, Ownable {
/*
                                   .                                                                                    
                         ..       ,k:                 .'.               :d;               ..                            
                 .      'Ok.     .d0,                ,cl;.              cX0:   .;,       .d0,                           
               .dx.     cXO'     .O0,           ...':llllc,'.           ;KXk'  .O0,      'ONl                           
               :Xk.     oX0:     '0K;            .,colloll;..           ;KX0c  .kXl.     ,KNd.                          
               :XO,     lXKl     'OXl              .:lllc'              ;0XKd.  oNx.     ;KNx.                          
               ;XK;     ;KXx.    .kXk,              .cl:'               cXXXk'  lKO,     ;XNk.                          
               '0Xo.    .ON0;     lKKx.              ,:,.               oKKXx.  lXO;     ,0WO'                          
               .ON0,     dNXd.    .kNKo.             .'..              .xKXXl   lKO;     ,KWk.                          
               .ONNx.    ;KNKc     ;KNKo.                              :0KX0;  .dXk'     ;XWO.                          
               .xNXKc    .xNK0:     :KXKd.          .......           ;0NXKo.  'OKo.    .oXXk.                          
                oX0Xk.    ;0KXK:     ;OKKk;   .':lcldddkkddxoc;.    .lOXXKo.  .o0O,     ,OXKl                           
                ,OKKKo.   .lKKX0o.    .dKXKxclOK0Odc::;;;:clox0xc,,lOKKKKo.  'd00l.     cKX0,                           
                 lXKK0l.   .oKKKX0o.   .:OXNX00kl:,,,;:::;,,,;coOKXNXK0x;. .ckO0d.     ,kKKl                            
                 .xXXXXk'   .cOKKKK0d:.. .dXKOd:,,;codddoooc,,;:lkXNOo,  .:xO00d.     ;OXXx.                            
                  .dKXXXOc.   'oOKKKKK0kolxOkkl;,:oo:,,',:xxc,,,:xXO'.':ok000Oc.    .l0XXk'                             
                   .c0XKKKO:.   .:okOKKKKXNKOxc,,cdc'cdl;,oxc,,';dKKkk0XK00kl.    .lOKXXx'                              
                     ;OXKKXXOl'.    .',,,oOkxxc,,:dc'oOd:,dd:,,,ckKXXKKK0xl.   .,o0XNNKl.                               
                      .:xKXXXXKOkdlc:::clxK0kkl,,;od;;:;,cxc;;,;o0XK0Odc'...,cdkXWNNKd'                                 
         .               ';lkKXKKKXXKXXXXXX0O0kc;;:dd:'':oc;;,;oOXNk:;;:ldOKXXXXXXOl'        .:.                        
        .l'                 .':loooxkOOkxddkKKOdc;;:odc;;;;;,;lk0KXX0KXNNNNNNKOdc'.         'ldl,.                      
      .,ldo;.                        ..     ;k0Oxl:;;cddl;;;:lxKKdoooddddlc:;..              ,o:.                       
      .,hodl'                                'okOkoc;,:lc;;cdOOl'                            .;.                        
        ,l.                      ...',;:coodddx0K0Okl;;;,;lxOOl,;:cllodxxkkxxddool:,..                                  
        .,              ..',:codxkO0KXNNXXNNNNNXKOxoc::;,;ldxk0XNNNWNNNNNNNNXXNXXXK00Odl;.                              
                    .cdxO0KXXXXKXXXKKXNNXXXNNXK0kko;;codl:::cx0XNNWWWWNNWWNNXK000KKKKXXXNKxc.                           
                 .;d0XXXKXX0kdol::oxOXNNXXXXNX0kdl:;::clodl;;ldOKKOkxdolc;,''....';clxKXNNNN0l.                         
               .cOKXXXXOd:'.  .'lx0XXXXNNNNNX0Okoc;:lc;;;cdl;;cx0x,                   'o0NNNNNk,                        
              'kXXKK0d;.    'ckKNXXX0OkxddxOXK0xl:;lo::lc;cdc,;cx00kdooollc:;,,'.       'o0XNNN0:                       
             ;OXXXkc.     ;xKXXKxl;'.. ..':d00Ooc;;oo;lOkc;dd;,;l0NWNNXNNNWNNNXXOdc'      .dXNNX0:                      
            ,OXXO:.     'xXXXOl'   .,cox0XWNK0Oo:;;lo;lOkc;ox:,;lOOo;,,;:clodkKXXXXKx:.    .lKK0X0;                     
           .oXNx.      ;ONKx:.  .:x0XXXXNWNK00Odc;,cdc;::;:xo;';oO0xool:,..   .';lx0XKk:.    :OKKX0,                    
           c0XO'      :0XKc    :kXXXNN0xoc,'lOOxl:;,colccldd:,,:d0XXXXXXK0Odc'     'o0KKx'    cKXKXk'                   
          .xXK:      ;0XKc   .dXXXN0d:.     .cO0xl:;,;cllc:,,;:dkxooooxk0KXXXKx:.    :OXXO;   .oK0KXo.                  
          ;OXd.     .kXNk.  .dXXNXd.          ,dOOdc:;,,,;;:ldOOc.     ..';cdOXXO:    ,kXX0;   .xXXN0,                  
         .oXK;      ;KXNd.  :KXXKc              ,ldxkkxxkkkOko:'             .:kXXd.   ,OXNO'   ,OXNK:                  
         .kXO'      ;0XNl   oXXK:                  .,;;;::;'.                  .dXXx.   ;0XXl    c0KXl                  
         ,0Nx.      ;0XX:  .dNXl                                                .lKXx.   lKNk.   ,OKXd.                 
         :KXl       ,kXK;  .oN0,                     .                           .lKXd.  .oX0;   .xKXx.                 
        .lKK;       'xKK;   cN0,                    .c'                           .oXK:   'OXl    lKXk.                 
        .oXK;       .xNK:   ;KK;                    ,oc,.                          .dXx.   lXx.   :0XO'                 
        .oNX;       .oXXd.  'kNd                   .coooc,...                       ;K0,   ;KO'   ,OXO'                 
        .dNX:        :KX0;  .oNk.               .;lloddoddo:.                       ,0Xc   ,0K;   ,OXO'                 
        .kNK:        .dXXd.  ,00'                .,lddddd:.                         'kXd.  'kXl   'xKx.                 
        .dN0,         .kX0;  .oKc                  .:ddd;                           'kKl   .dKc   .kXd.                 
         lX0,          ,OXl   .kx.                  .cl;.                           .OO'    l0;   .k0:                  
         .dk.           'd:    .,                    ,,                              ''     .;.    ..                   
          ..                                         ..                                                                 
*/

  using SafeMath for uint;
  using Counters for Counters.Counter;
  Counters.Counter private _mintedCount;

  //                           __            __    
  //        _______  ___  ___ / /____ ____  / /____
  //   _   / __/ _ \/ _ \(_-</ __/ _ `/ _ \/ __(_-<
  //  (_)  \__/\___/_//_/___/\__/\_,_/_//_/\__/___/
  //
  uint256 public constant MAX_SUPPLY = 222;
  uint256 public constant MAX_PUBLIC_MINT = 5;
  uint256 public constant PRICE_PER_TOKEN = 0.02 ether;

  //                           __    
  //        ___ _  _____ ___  / /____
  //   _   / -_) |/ / -_) _ \/ __(_-<
  //  (_)  \__/|___/\__/_//_/\__/___/
  //
  event Minted(uint tokenId, address recipient);
  event VerifiedForWhitelist(bool verified);

  //                              _             
  //        __ _  ___ ____  ___  (_)__  ___ ____
  //   _   /  ' \/ _ `/ _ \/ _ \/ / _ \/ _ `(_-<
  //  (_) /_/_/_/\_,_/ .__/ .__/_/_//_/\_, /___/
  //                /_/  /_/          /___/     
  //
  mapping(uint256 => bool) public mythieExists;
  mapping(uint256 => address) public tokenIdToOwner;
  mapping(string => uint256) public tokenURItoTokenId;
  mapping(uint256 => string) internal _tokenURIs;

  //             __       __                        
  //        ___ / /____ _/ /____   _  _____ ________
  //   _   (_-</ __/ _ `/ __/ -_) | |/ / _ `/ __(_-<
  //  (_) /___/\__/\_,_/\__/\__/  |___/\_,_/_/ /___/
  //
  // Contract-level metadata URI
  string public contractLevelURI;
  // Base URI for token metadata
  string private _baseURIextended;
  // Where funds should be sent to
  address payable public fundsTo;
  // Is public sale on?
  bool public publicSale;
  // Is whitelist only sale on?
  bool public whitelistSale;
  // Sale price
  uint256 public pricePer;
  // Merkle root
  bytes32 public merkleRoot;

  //   _/|  ___ ___ _    _/|
  //  > _< / _ `/  ' \  > _<
  //  |/   \_, /_/_/_/  |/  
  //      /___/             
  //
  constructor() ERC721("Mythies", "MYTHIE") {
    whitelistSale = false;
    publicSale = false;
    pricePer = PRICE_PER_TOKEN;
    contractLevelURI = "https://gateway.pinata.cloud/ipfs/QmPVwDFFayfWYrPWy4wszdKd4G4aqfuyahEMS1KqxpmD5R";
    _baseURIextended = "https://gateway.pinata.cloud/ipfs/QmWFoPqLKN9k8HE4y2iKnaYtV78BsbdeyJtyrXpGFo9wkd/";
    merkleRoot = 0xc942be770202bf53d5a1a933e69198b937dff0569945e99ce0151ba0264bf74f;
  }

  //                   __                              
  //        ___  ___  / /_ __  ___ _    _____  ___ ____
  //   _   / _ \/ _ \/ / // / / _ \ |/|/ / _ \/ -_) __/
  //  (_)  \___/_//_/_/\_, /  \___/__,__/_//_/\__/_/   
  //                  /___/                            
  //
  function setMerkleRoot(bytes32 root) external onlyOwner {
    merkleRoot = root;
  }

  function setFundsTo(address payable newFundsTo) external onlyOwner {
    fundsTo = newFundsTo;
  }

  function setPricePer(uint256 newPrice) external onlyOwner {
    pricePer = newPrice;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner() {
    _baseURIextended = baseURI_;
  }

  function setContractURI(string memory contractURI_) external onlyOwner() {
    contractLevelURI = contractURI_;
  }

  function enablePublicSale() external onlyOwner {
    publicSale = true;
    whitelistSale = false;
    pricePer = PRICE_PER_TOKEN;
  }

  function enableWhitelistSale() external onlyOwner {
    whitelistSale = true;
    publicSale = false;
    pricePer = 0 ether;
  }

  function disableAllSales() external onlyOwner {
    publicSale = false;
    whitelistSale = false;
  }

  function claimBalance() external onlyOwner {
    require(fundsTo != address(0), "Cannot transfer to null address");
    (bool success, ) = fundsTo.call{value: address(this).balance}("");
    require(success, "Transfer failed");
  }

  //         __  __  ___    ____
  //        / / / / / _ \  /  _/
  //   _   / /_/ / / , _/ _/ /  
  //  (_)  \____/ /_/|_| /___/  
  //
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
    require(_exists(tokenId), "URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
    super._setTokenURI(tokenId, _tokenURI);
  }

  // Returns the URI for the contract level metadata
  function contractURI() external view returns (string memory) {
    return contractLevelURI;
  }

  // Returns the unique token URI, given the token id
  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    super.tokenURI(tokenId);

    // Concat the tokenID to the baseURI.
    return string(abi.encodePacked(_baseURIextended, uint2str(tokenId), '.json'));
  }

  function _setTokenURIforTokenId(uint256 tokenId) internal {
    _setTokenURI(tokenId, tokenURI(tokenId));
    tokenURItoTokenId[tokenURI(tokenId)] = tokenId;
  }

  //               _      __  _          
  //        __ _  (_)__  / /_(_)__  ___ _
  //   _   /  ' \/ / _ \/ __/ / _ \/ _ `/
  //  (_) /_/_/_/_/_//_/\__/_/_//_/\_, / 
  //                              /___/  
  //
  function verifyWhitelistedAddress(
    address account,
    bytes32[] calldata merkleProof
  ) public returns (bool) {
    
    bytes32 node = keccak256(abi.encodePacked(account));

    // Verify the merkle proof.
    bool verified = MerkleProof.verify(merkleProof, merkleRoot, node);

    emit VerifiedForWhitelist(verified);

    return verified;
  }

  function mintedSupply() public view returns (uint) {
    return _mintedCount.current();
  }

  function availableMintsForAddress(address addr) external view returns (uint256) {
    return MAX_PUBLIC_MINT - balanceOf(addr);
  }

  function mintMythieWhitelist(address recipient, uint8 quantity, bytes32[] calldata merkleProof) public {
    // Recipient's address must be verified on the whitelist
    require(verifyWhitelistedAddress(recipient, merkleProof), 'Address is not whitelisted');
    // Cannot mint 0
    require(quantity != 0, "Requested quantity cannot be zero");
    // Cannot mint more than max supply
    require(mintedSupply() + quantity <= MAX_SUPPLY, "Purchase would exceed max supply of Mythies");
    // Cannot mint more than the max limit per wallet
    require(balanceOf(recipient) + quantity <= MAX_PUBLIC_MINT, "Exceeded max available to purchase");
    // Sale must be enabled
    require(whitelistSale == true, "Whitelist sale is not enabled");

    for (uint256 i = 0; i < quantity; i++) {
      _mintedCount.increment();
      uint256 newMythieId = _mintedCount.current();

      _safeMint(recipient, newMythieId);
      _setTokenURIforTokenId(newMythieId);

      mythieExists[newMythieId] = true;
      tokenIdToOwner[newMythieId] = recipient;

      emit Minted(newMythieId, recipient);
    }
  }

  function mintMythie(address recipient, uint8 quantity) public payable {
    // Cannot mint 0
    require(quantity != 0, "Requested quantity cannot be zero");
    // Cannot mint more than max supply
    require(mintedSupply() + quantity <= MAX_SUPPLY, "Purchase would exceed max supply of Mythies");
    // Cannot mint more than the max limit per wallet
    require(balanceOf(recipient) + quantity <= MAX_PUBLIC_MINT, "Exceeded max available to purchase");
    // Sale must be enabled
    require(publicSale == true, "Public sale is not enabled");
    // Txn must have at least quantity * price (any more is considered a tip)
    require(quantity * pricePer <= msg.value, "Not enough ether sent");
    
    for (uint256 i = 0; i < quantity; i++) {
      _mintedCount.increment();
      uint256 newMythieId = _mintedCount.current();

      _safeMint(recipient, newMythieId);
      _setTokenURIforTokenId(newMythieId);

      mythieExists[newMythieId] = true;
      tokenIdToOwner[newMythieId] = recipient;

      emit Minted(newMythieId, recipient);
    }
  }

  //              __  __          
  //        ___  / /_/ /  ___ ____
  //   _   / _ \/ __/ _ \/ -_) __/
  //  (_)  \___/\__/_//_/\__/_/   
  //
  // https://github.com/provable-things/ethereum-api/issues/102#issuecomment-760008040
  function uint2str(uint256 _i) internal pure returns (string memory str) {
    if (_i == 0) { return "0"; }

    uint256 j = _i;
    uint256 length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    j = _i;
    while (j != 0) {
      bstr[--k] = bytes1(uint8(48 + j % 10));
      j /= 10;
    }
    str = string(bstr);
  }

  // Help from the wizard: https://docs.openzeppelin.com/contracts/4.x/wizard
  /** 
  * @dev Override some conflicting methods so that this contract can inherit 
  * ERC721Enumerable and ERC721URIStorage functionality
  */

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // with love <3
  //           _      ____      _ __            __            
  //   _/|    (_)__  / _(_)__  (_) /____   ___ / /____ __    _/|
  //  > _<   / / _ \/ _/ / _ \/ / __/ -_) (_-</  '_/ // /   > _<
  //  |/    /_/_//_/_//_/_//_/_/\__/\__/ /___/_/\_\\_, /    |/  
  //                                            /___/       
}