// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721A.sol";
                                                                                          
/*                                                                                          
                                      .::-====-----:                                      
                                 :=++*+==-:::::---==+++=-.                                
                             :=++-::::--==++++++==-::::::=++=.                            
                          .=+=:..:-+*#%%%###%########*+=--::-++=:                         
                        -==....-*#***#%%##****##%%%######+=---::++=.                      
                    .-==:.  .-+*+*%@%+-...----=++++%@%###%%#=--:---++==:..                
         :-==-==-==-:..  ..-==+%@@%-.:-:..---====+*+=@@@%#*#%#+----:::.:---=--===-        
       -#+-:::..........:::-+%@@@%::---:.::--:-====+#=%@@@%#**##*=---:::::::.....:*       
       @*****++====-==+==:+%@@@@%-::::::+#@@@@#======%-@@@@@@%**********++++++=-::*       
       %#####*###***+=--*%@@@@@@+::::::#@@@@@@@@+===-%**@@@@@@@@%#####***********+:       
       :@%%%%####****#%@@@@@@@@@=:::::=@@@@@@@@@#-*#*@%%@@@@@@@@#*====--------:::+:       
      .#+------::-=+*+=+@@@@@@@@*::---:#@@@@@@@%==###@#%@@@@@@#==--::--===+++++=--+       
      .@*+++++++++=---=+-*@@@@@@@=::---:=#%%%#+=+#**%##@@@@@#==-:.-*#%##*****++==*:       
       =%%%%########**+=:.:*@@@@@@=::------=++%@*+*%#*@@@@%+=-::-*#####******+++=.        
         --=========+#***=:..=#@@@@#-::-----=+%@%#*+#@@@#+=-::-*###+.                     
                      -****=:...-+#%@%*=:-=++===+*%@%*=--:::-*##%+                        
                        :+*++*=-.  .:-=+++====+++=-:::..::=*##%+.                         
                          .=**++++=-:.           ....-+*##**#+.                           
                             :=**+==+++==++====+**#%%#*++#*=                              
                                .-+#*+==----========+**+-                                 
                                 :*---+%+-====-+%+=-:-*                                   
                                 %.:-+*=#      *:+:. .+:                                  
                                .#.-=+%=@      #:#.. .=:                                  
                                -#.-+*@+@      *:#.. .=-        ..:::.                    
                                =#:=*#@+@      +:#.. .=-    =++=-::--=++-                 
                                ++:=%#@**      +-#:: .:=  .*-...:---::++-*:               
                                #%%#%%@%=      =++-==*#%. +-..:-*****=-=#=#-              
                               **++#%%#@.      :%=#++-::+.+:...+:::*#+---%-#              
                             :#=:=+#%%@*        =%+#:..::+**:::::::*#=:.:#=#              
                           :**-:=+#%%%%          +@+#:...:-*#=-::-*+-:..:%-%              
                         -*+-:-=*#%%#%:           =*+#=:...::-=++=:..  .**+*              
                       .#+-:-=*#%%%%#.             :*+*#=:.  .....   .=*===               
                       .%-+##%%@%#%=                 =*++*++:.......=+--+:                
                        -*%%%%%%%=.                    :=**+=----::-===-.                 
                          .--=-.                           .-==-==-:                      
*/ 

contract ForbiddenOne is Ownable, ERC721A {
  using Strings for uint256;

  string private _baseTokenURI;
  address private openSeaProxyRegistryAddress;
  bool private isOpenSeaProxyActive = false;

  /* minting vars */
  uint public dropSize = 64;
  bool public mintActive = true;
  bool public publicMintActive = false;
  mapping(uint => mapping(address => uint)) private dropsMinted;
  mapping(uint => uint) public dropsPrices;
  mapping(uint => uint) public dropsMaxPerMint;
  mapping(uint => bool) public dropsMintable;
  mapping(uint => bytes32) public dropsMerkleRoots;

  /* purchasing vars */
  bool public purchaseActive = false;
  bool public purchased = false;
  address public purchasedBy;
  uint public purchasePrice = 0 ether;

  /* claiming vars */
  bool public claimActive = false;
  uint public claimShare;
  mapping(uint => bool) public claimedTokens;

  constructor(bytes32 firstMerkleRoot, string memory baseURI) ERC721A("The Forbidden One", "FRBDN", 64) {
    dropsMintable[1] = true;
    dropsPrices[1] = 0 ether;
    dropsMaxPerMint[1] = 1;
    dropsMerkleRoots[1] = firstMerkleRoot;
    _baseTokenURI = baseURI;
  }

  modifier callerIsUser() {
    require(msg.sender != address(0), "No constructorz lol");
    require(tx.origin == msg.sender, "Dont get seven'd");
    _;
  }

  modifier paidEnough(uint drop, uint numberOfTokens) {
    require(msg.value >= dropsPrices[drop] * numberOfTokens, "more eth pls");
    _;
  }

  modifier canMint(uint drop, uint numberOfTokens) {
    require(drop >= 1 && drop <= 5, "invalid drop num");
    require(!purchased, "set already purchased");
    require(numberOfTokens > 0, "mint more lol");
    require(dropsMintable[drop], "drop not mintable");
    if (msg.sender != owner()) {
      require(
        dropsMinted[drop][msg.sender] + numberOfTokens <= dropsMaxPerMint[drop], 
        "max claim reached"
      );
    }
    // enforce minimum supply so drops dont get minted out of order
    uint total = totalSupply();
    if (drop == 1) {
      require(total + numberOfTokens <= 64, "drop 1 minted out");
    }
    if (drop == 2) {
      require(total >= 64, "drop 1 not minted out yet");
      require(total + numberOfTokens <= 128, "drop 2 minted out");
    }
    if (drop == 3) {
      require(total >= 128, "drop 2 not minted out yet");
      require(total + numberOfTokens <= 192, "drop 3 minted out");
    }
    if (drop == 4) {
      require(total >= 192, "drop 3 not minted out yet");
      require(total + numberOfTokens <= 256, "drop 4 minted out");
    }
    if (drop == 5) {
      require(total >= 256, "drop 4 not minted out yet");
      require(total + numberOfTokens <= 320, "drop 5 minted out");
    }
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
      MerkleProof.verify(
        merkleProof,
        root,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Address does not exist in list"
    );
    _;
  }

  function mintPublic(uint drop, uint numberOfTokens) 
    public 
    payable 
    callerIsUser 
    canMint(drop, numberOfTokens) 
    paidEnough(drop, numberOfTokens) 
  {
    require(publicMintActive, "public mint is not active rn...");
    dropsMinted[drop][msg.sender] += numberOfTokens;
    _safeMint(msg.sender, numberOfTokens);
  }

  function mint(uint drop, uint numberOfTokens, bytes32[] calldata merkleProof) 
    public 
    payable 
    callerIsUser 
    canMint(drop, numberOfTokens)
    paidEnough(drop, numberOfTokens)
    isValidMerkleProof(merkleProof, dropsMerkleRoots[drop])
  {
    require(mintActive, "mint is not active rn..");
    dropsMinted[drop][msg.sender] += numberOfTokens;
    _safeMint(msg.sender, numberOfTokens);
  }

  function purchase() public payable {
    require(purchaseActive, "set not for sale");
    require(!purchased, "already purchased");
    require(msg.value == purchasePrice, "not enough eth");
    purchased = true;
    purchasedBy = msg.sender;
  }

  function claim() public {
    require(claimActive, "claim is not active");
    uint tokenCount = balanceOf(msg.sender);
    require(tokenCount > 0, "doesnt own any tokens");

    uint sharesOwed = 0;
    uint index;
    for (index = 0; index < tokenCount; index++) {
      uint tokenId = tokenOfOwnerByIndex(msg.sender, index);
      if (!claimedTokens[tokenId]) {
        sharesOwed++;
        claimedTokens[tokenId] = true;
      }
    }

    uint amount = sharesOwed * claimShare;
    (bool success, ) = msg.sender.call{ value: amount }("");
    require(success, "Failed to widthdraw Ether");
  }

  /**
    * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
    */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    if (isOpenSeaProxyActive)   {
      // Get a reference to OpenSea's proxy registry contract by instantiating
      // the contract using the already existing address.
      ProxyRegistry proxyRegistry = ProxyRegistry(
          openSeaProxyRegistryAddress
      );
      if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
      }
    }

    return super.isApprovedForAll(owner, operator);
  }

  /* admin */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setOpenSeaProxy(address _openSeaProxyRegistryAddress, bool _isOpenSeaProxyActive) external onlyOwner {
    openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    isOpenSeaProxyActive = _isOpenSeaProxyActive;
  }

  function setDropInfo(
    uint drop,
    bool mintable,
    uint maxPerMint,
    uint price
  ) external onlyOwner {
    dropsMintable[drop] = mintable;
    dropsMaxPerMint[drop] = maxPerMint;
    dropsPrices[drop] = price;
  }
  
  function setPurchaseInfo(
    bool _purchaseActive, 
    uint _purchasePrice
  ) external onlyOwner {
    purchaseActive = _purchaseActive;
    purchasePrice = _purchasePrice;
  }
  
  function setClaimInfo(
    bool _claimActive, 
    uint _claimShare
  ) external onlyOwner {
    claimActive = _claimActive;
    claimShare = _claimShare;
  }

  function setDropMerkleRoot(uint drop, bytes32 merkleRoot) external onlyOwner {
    dropsMerkleRoots[drop] = merkleRoot;
  }

  function setMintActive(bool _mintActive) external onlyOwner {
    mintActive = _mintActive;
  }

  function setPublicMintActive(bool _publicMintActive) external onlyOwner {
    publicMintActive = _publicMintActive;
  }

  function mintTo(address to, uint drop, uint numberOfTokens) 
    external 
    canMint(drop, numberOfTokens)
    onlyOwner 
  {
    dropsMinted[drop][to] += numberOfTokens;
    _safeMint(to, numberOfTokens);
  }

  function deposit(uint amount) external onlyOwner payable {
    require(msg.value == amount, 'deposit correct amount..');
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success, "Failed to widthdraw Ether");
  }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}