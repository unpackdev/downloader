// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./ERC721.sol";

                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                            
// TTTTTTTTTTTTTTTTTTTTTTThhhhhhh               iiii                          iiii                                                               hhhhhhh               iiii          tttt                                                                        tttt          
// T:::::::::::::::::::::Th:::::h              i::::i                        i::::i                                                              h:::::h              i::::i      ttt:::t                                                                     ttt:::t          
// T:::::::::::::::::::::Th:::::h               iiii                          iiii                                                               h:::::h               iiii       t:::::t                                                                     t:::::t          
// T:::::TT:::::::TT:::::Th:::::h                                                                                                                h:::::h                          t:::::t                                                                     t:::::t          
// TTTTTT  T:::::T  TTTTTT h::::h hhhhh       iiiiiii     ssssssssss        iiiiiii     ssssssssss          aaaaaaaaaaaaa            ssssssssss   h::::h hhhhh       iiiiiiittttttt:::::ttttttt   ppppp   ppppppppp      ooooooooooo       ssssssssss   ttttttt:::::ttttttt    
//         T:::::T         h::::hh:::::hhh    i:::::i   ss::::::::::s       i:::::i   ss::::::::::s         a::::::::::::a         ss::::::::::s  h::::hh:::::hhh    i:::::it:::::::::::::::::t   p::::ppp:::::::::p   oo:::::::::::oo   ss::::::::::s  t:::::::::::::::::t    
//         T:::::T         h::::::::::::::hh   i::::i ss:::::::::::::s       i::::i ss:::::::::::::s        aaaaaaaaa:::::a      ss:::::::::::::s h::::::::::::::hh   i::::it:::::::::::::::::t   p:::::::::::::::::p o:::::::::::::::oss:::::::::::::s t:::::::::::::::::t    
//         T:::::T         h:::::::hhh::::::h  i::::i s::::::ssss:::::s      i::::i s::::::ssss:::::s                a::::a      s::::::ssss:::::sh:::::::hhh::::::h  i::::itttttt:::::::tttttt   pp::::::ppppp::::::po:::::ooooo:::::os::::::ssss:::::stttttt:::::::tttttt    
//         T:::::T         h::::::h   h::::::h i::::i  s:::::s  ssssss       i::::i  s:::::s  ssssss          aaaaaaa:::::a       s:::::s  ssssss h::::::h   h::::::h i::::i      t:::::t          p:::::p     p:::::po::::o     o::::o s:::::s  ssssss       t:::::t          
//         T:::::T         h:::::h     h:::::h i::::i    s::::::s            i::::i    s::::::s             aa::::::::::::a         s::::::s      h:::::h     h:::::h i::::i      t:::::t          p:::::p     p:::::po::::o     o::::o   s::::::s            t:::::t          
//         T:::::T         h:::::h     h:::::h i::::i       s::::::s         i::::i       s::::::s         a::::aaaa::::::a            s::::::s   h:::::h     h:::::h i::::i      t:::::t          p:::::p     p:::::po::::o     o::::o      s::::::s         t:::::t          
//         T:::::T         h:::::h     h:::::h i::::i ssssss   s:::::s       i::::i ssssss   s:::::s      a::::a    a:::::a      ssssss   s:::::s h:::::h     h:::::h i::::i      t:::::t    ttttttp:::::p    p::::::po::::o     o::::ossssss   s:::::s       t:::::t    tttttt
//       TT:::::::TT       h:::::h     h:::::hi::::::is:::::ssss::::::s     i::::::is:::::ssss::::::s     a::::a    a:::::a      s:::::ssss::::::sh:::::h     h:::::hi::::::i     t::::::tttt:::::tp:::::ppppp:::::::po:::::ooooo:::::os:::::ssss::::::s      t::::::tttt:::::t
//       T:::::::::T       h:::::h     h:::::hi::::::is::::::::::::::s      i::::::is::::::::::::::s      a:::::aaaa::::::a      s::::::::::::::s h:::::h     h:::::hi::::::i     tt::::::::::::::tp::::::::::::::::p o:::::::::::::::os::::::::::::::s       tt::::::::::::::t
//       T:::::::::T       h:::::h     h:::::hi::::::i s:::::::::::ss       i::::::i s:::::::::::ss        a::::::::::aa:::a      s:::::::::::ss  h:::::h     h:::::hi::::::i       tt:::::::::::ttp::::::::::::::pp   oo:::::::::::oo  s:::::::::::ss          tt:::::::::::tt
//       TTTTTTTTTTT       hhhhhhh     hhhhhhhiiiiiiii  sssssssssss         iiiiiiii  sssssssssss           aaaaaaaaaa  aaaa       sssssssssss    hhhhhhh     hhhhhhhiiiiiiii         ttttttttttt  p::::::pppppppp       ooooooooooo     sssssssssss              ttttttttttt  
//                                                                                                                                                                                                 p:::::p                                                                     
//                                                                                                                                                                                                 p:::::p                                                                     
//                                                                                                                                                                                                p:::::::p                                                                    
//                                                                                                                                                                                                p:::::::p                                                                    
//                                                                                                                                                                                                p:::::::p                                                                    
//                                                                                                                                                                                                ppppppppp                                                                    
                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                            
// bbbbbbbb                                                                                                                                                        bbbbbbbb                                                                                                    
// b::::::b                                       YYYYYYY       YYYYYYY                                                   LLLLLLLLLLL                              b::::::b                                                                                                    
// b::::::b                                       Y:::::Y       Y:::::Y                                                   L:::::::::L                              b::::::b                                                                                                    
// b::::::b                                       Y:::::Y       Y:::::Y                                                   L:::::::::L                              b::::::b                                                                                                    
//  b:::::b                                       Y::::::Y     Y::::::Y                                                   LL:::::::LL                               b:::::b                                                                                                    
//  b:::::bbbbbbbbb yyyyyyy           yyyyyyy     YYY:::::Y   Y:::::YYYooooooooooo      ggggggggg   ggggg aaaaaaaaaaaaa     L:::::L                 aaaaaaaaaaaaa   b:::::bbbbbbbbb        ssssssssss                                                                          
//  b::::::::::::::bby:::::y         y:::::y         Y:::::Y Y:::::Y oo:::::::::::oo   g:::::::::ggg::::g a::::::::::::a    L:::::L                 a::::::::::::a  b::::::::::::::bb    ss::::::::::s                                                                         
//  b::::::::::::::::by:::::y       y:::::y           Y:::::Y:::::Y o:::::::::::::::o g:::::::::::::::::g aaaaaaaaa:::::a   L:::::L                 aaaaaaaaa:::::a b::::::::::::::::b ss:::::::::::::s                                                                        
//  b:::::bbbbb:::::::by:::::y     y:::::y             Y:::::::::Y  o:::::ooooo:::::og::::::ggggg::::::gg          a::::a   L:::::L                          a::::a b:::::bbbbb:::::::bs::::::ssss:::::s                                                                       
//  b:::::b    b::::::b y:::::y   y:::::y               Y:::::::Y   o::::o     o::::og:::::g     g:::::g    aaaaaaa:::::a   L:::::L                   aaaaaaa:::::a b:::::b    b::::::b s:::::s  ssssss                                                                        
//  b:::::b     b:::::b  y:::::y y:::::y                 Y:::::Y    o::::o     o::::og:::::g     g:::::g  aa::::::::::::a   L:::::L                 aa::::::::::::a b:::::b     b:::::b   s::::::s                                                                             
//  b:::::b     b:::::b   y:::::y:::::y                  Y:::::Y    o::::o     o::::og:::::g     g:::::g a::::aaaa::::::a   L:::::L                a::::aaaa::::::a b:::::b     b:::::b      s::::::s                                                                          
//  b:::::b     b:::::b    y:::::::::y                   Y:::::Y    o::::o     o::::og::::::g    g:::::ga::::a    a:::::a   L:::::L         LLLLLLa::::a    a:::::a b:::::b     b:::::bssssss   s:::::s                                                                        
//  b:::::bbbbbb::::::b     y:::::::y                    Y:::::Y    o:::::ooooo:::::og:::::::ggggg:::::ga::::a    a:::::a LL:::::::LLLLLLLLL:::::La::::a    a:::::a b:::::bbbbbb::::::bs:::::ssss::::::s                                                                       
//  b::::::::::::::::b       y:::::y                  YYYY:::::YYYY o:::::::::::::::o g::::::::::::::::ga:::::aaaa::::::a L::::::::::::::::::::::La:::::aaaa::::::a b::::::::::::::::b s::::::::::::::s                                                                        
//  b:::::::::::::::b       y:::::y                   Y:::::::::::Y  oo:::::::::::oo   gg::::::::::::::g a::::::::::aa:::aL::::::::::::::::::::::L a::::::::::aa:::ab:::::::::::::::b   s:::::::::::ss                                                                         
//  bbbbbbbbbbbbbbbb       y:::::y                    YYYYYYYYYYYYY    ooooooooooo       gggggggg::::::g  aaaaaaaaaa  aaaaLLLLLLLLLLLLLLLLLLLLLLLL  aaaaaaaaaa  aaaabbbbbbbbbbbbbbbb     sssssssssss                                                                           
//                        y:::::y                                                                g:::::g                                                                                                                                                                       
//                       y:::::y                                                     gggggg      g:::::g                                                                                                                                                                       
//                      y:::::y                                                      g:::::gg   gg:::::g                                                                                                                                                                       
//                     y:::::y                                                        g::::::ggg:::::::g                  


contract BoredApeYachtClub is ERC721, Ownable {
  using ECDSA for bytes32;
  string public PROVENANCE;
  bool provenanceSet;

  uint256 public mintPrice;
  uint256 public maxPossibleSupply;
  uint256 public allowListMintPrice;
  uint256 public maxAllowedMints;

  address public immutable currency;
  address immutable wrappedNativeCoinAddress;

  address private signerAddress;
  bool public paused;

  enum MintStatus {
    PreMint,
    AllowList,
    Public,
    Finished
  }

  MintStatus public mintStatus = MintStatus.PreMint;

  mapping (address => uint256) public totalMintsPerAddress;

  constructor(
      string memory _name,
      string memory _symbol,
      uint256 _maxPossibleSupply,
      uint256 _mintPrice,
      uint256 _allowListMintPrice,
      uint256 _maxAllowedMints,
      address _signerAddress,
      address _currency,
      address _wrappedNativeCoinAddress
  ) ERC721(_name, _symbol, _maxAllowedMints) {
    maxPossibleSupply = _maxPossibleSupply;
    mintPrice = _mintPrice;
    allowListMintPrice = _allowListMintPrice;
    maxAllowedMints = _maxAllowedMints;
    signerAddress = _signerAddress;
    currency = _currency;
    wrappedNativeCoinAddress = _wrappedNativeCoinAddress;
  }

  function flipPaused() external onlyOwner {
    paused = !paused;
  }

  function preMint(uint amount) public onlyOwner {
    require(mintStatus == MintStatus.PreMint, "s");
    require(totalSupply() + amount <= maxPossibleSupply, "m");  
    _safeMint(msg.sender, amount);
  }

  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    require(!provenanceSet);
    PROVENANCE = provenanceHash;
    provenanceSet = true;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }
  
  function changeMintStatus(MintStatus _status) external onlyOwner {
    require(_status != MintStatus.PreMint);
    if (mintStatus == MintStatus.Public) {
      require(_status != MintStatus.AllowList);
    }
    mintStatus = _status;
  }

  function mintAllowList(
    bytes32 messageHash,
    bytes calldata signature,
    uint amount
  ) public payable {
    require(mintStatus == MintStatus.AllowList && !paused, "s");
    require(totalSupply() + amount <= maxPossibleSupply, "m");
    require(hashMessage(msg.sender, address(this)) == messageHash, "i");
    require(verifyAddressSigner(messageHash, signature), "f");
    require(totalMintsPerAddress[msg.sender] + amount <= maxAllowedMints, "l");

    if (currency == wrappedNativeCoinAddress) {
      require(allowListMintPrice * amount <= msg.value, "a");
    } else {
      IERC20 _currency = IERC20(currency);
      _currency.transferFrom(msg.sender, address(this), amount * allowListMintPrice);
    }

    totalMintsPerAddress[msg.sender] = totalMintsPerAddress[msg.sender] + amount;
    _safeMint(msg.sender, amount);
  }

  function mintPublic(uint amount) public payable {
    require(mintStatus == MintStatus.Public && !paused, "s");
    require(totalSupply() + amount <= maxPossibleSupply, "m");
    require(totalMintsPerAddress[msg.sender] + amount <= maxAllowedMints, "l");

    if (currency == wrappedNativeCoinAddress) {
      require(mintPrice * amount <= msg.value, "a");
    } else {
      IERC20 _currency = IERC20(currency);
      _currency.transferFrom(msg.sender, address(this), amount * mintPrice);
    }

    totalMintsPerAddress[msg.sender] = totalMintsPerAddress[msg.sender] + amount;
    _safeMint(msg.sender, amount);

    if (totalSupply() == maxPossibleSupply) {
      mintStatus = MintStatus.Finished;
    }
  }

  function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
    return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
  }

  function hashMessage(address sender, address thisContract) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, thisContract));
  }

  receive() external payable {
    mintPublic(msg.value);
  }

  function withdraw() external onlyOwner() {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(address tokenAddress) external onlyOwner() {
    IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
  }
}