/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: GPL-3.0
/*

 ██████╗██████╗ ██╗   ██╗██████╗ ████████╗ ██████╗ ██████╗  █████╗ ██████╗ ██╗███████╗███████╗
██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗██╔══██╗██╔══██╗██║██╔════╝██╔════╝
██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   ██║   ██║██████╔╝███████║██████╔╝██║█████╗  ███████╗
██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   ██║   ██║██╔══██╗██╔══██║██╔══██╗██║██╔══╝  ╚════██║
╚██████╗██║  ██║   ██║   ██║        ██║   ╚██████╔╝██████╔╝██║  ██║██████╔╝██║███████╗███████║
 ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝╚══════╝╚══════╝

Cryptobabies.COM
Cryptobabies.DAO
Cryptobabies.NFT
Cryptobabies.ETH

Cute, Collectible, CryptoBabies NFTs 
- CRYPTOBABIES GENESIS EDITION
-v1.0.0

*/

pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/ContextMixin.sol
 */
abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}
contract CryptoBabiesGenesis is VRFConsumerBase, ContextMixin, Ownable, ERC721Enumerable {
  using Strings for uint256;

  string public    baseURI;
  string public    network;
  string public    edition;
  bool public      paused = true;
  bool public      revealed = false;
  
  uint256 public   cost = 0.03 ether;
  uint256 public   maxSupply = 5000;
  uint256 public   maxMintAmount = 5;
  uint256 public   daoBabies = 25;
  uint256 public   nftPerAddressLimit = 50;

  bytes32 internal keyHash;
  uint256 internal fee;
  address public   VRFCoordinator;
  address public   LinkToken;
  address internal DAOAddress;

  //PROVENANCE
  string  public   PROVENANCE = "";
  uint256 public   startingIndexBlock;
  uint256 public   startingIndex;

  //A CRYTPOBABY
  struct CryptoBaby {
      uint256 dna;
  }

  //All The Babies live here
  CryptoBaby[] private babies;

  // EVENTS
  event requestedCryptoBaby(bytes32 indexed requestId);
  event createdCryptoBaby(string message);

  //MAPS
  mapping(address => uint256) public addressBabyBalance;
  mapping(bytes32 => address) requestToSender;

  constructor(
      address _VRFCoordinator, 
      address _LinkToken,
      address _DAOAddress, 
      string memory _baseUri,
      bytes32 _keyhash, 
      uint    _fee,
      string memory _network,
      string memory _edition
    )
      VRFConsumerBase(_VRFCoordinator , _LinkToken)
      ERC721("CRYPTOBABIES GENESIS", 'CBGEN')
    {
      VRFCoordinator =  _VRFCoordinator;
      LinkToken =       _LinkToken;
      keyHash =         _keyhash;
      fee =             _fee;
      DAOAddress = _DAOAddress;
      network = _network;
      edition = _edition;
      setBaseURI(_baseUri);
  }


  /*
      Public function for creating a new CryptoBaby.
  */
  function requestCreation(uint32 _numberOfBabies ) public payable {

      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
      require(!paused, "Sale must be active to mint CryptoBabies");
      require(msg.value >= cost * _numberOfBabies , "insufficient funds");
      require(totalSupply() + _numberOfBabies  <= maxSupply, "max baby limit exceeded");
      require(_numberOfBabies > 0, "need to mint at least 1 baby");
      require(_numberOfBabies <= maxMintAmount, "you cant mint that many babies at once");
      require(addressBabyBalance[msg.sender] + _numberOfBabies <= nftPerAddressLimit, "max NFT per address exceeded");

      for(uint i = 0; i < _numberOfBabies; i++) {
          if (totalSupply() < maxSupply) {
          requestNewCryptoBaby(msg.sender);
          emit createdCryptoBaby("CryptoBaby has been minted");
          }
      }
  }

  // Reserve XX babies for the DAO up front
  function reserveDAOBabies() public onlyOwner { 
    
    for(uint i = 0; i < daoBabies; i++) {
        if (totalSupply() < maxSupply) {
        requestNewCryptoBaby(DAOAddress);
        emit createdCryptoBaby("CryptoBaby has been minted");
        }
    }

  }

  function requestNewCryptoBaby(address parent) internal returns (bytes32)
  {
          bytes32 requestId = requestRandomness(keyHash, fee);
          //Track the request
          requestToSender[requestId] = parent;
          addressBabyBalance[parent]++;
          emit requestedCryptoBaby(requestId);

          // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
          // the end of pre-sale, set the starting index block
          if (startingIndexBlock == 0 && (totalSupply() == maxSupply )) {
                startingIndexBlock = block.number;
              }
          return requestId;
  }

  /*
      Chainlink callback with our requested random number
  */
  function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
  internal override 
  {
      uint256 newId = totalSupply()+1;

      //Baby DNA is 32 Digits, we ask for 40 for future needs.
      uint256 dna = (randomNumber % 10 ** 40); 

      //Creates a new cryptobaby
      CryptoBaby memory newBaby = CryptoBaby(dna);

      //Kinda funny we have to push....
      babies.push(newBaby);

      //deliver the new baby
      _safeMint(requestToSender[requestId], newId);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //token uri
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();

    if(revealed == false) {
        return string(abi.encodePacked(currentBaseURI, "0"));
    }
    
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), "&network=", network, "&edition=", edition ))
        : "";
  }
  
   /**
   * Override isApprovedForAll to auto-approve OpenSea's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }


    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

  /*
      Returns the CryptoBaby's DNA
  */
  function getCryptoBabyDNA(uint256 tokenId) public view returns (uint256) {
      return (
          babies[tokenId-1].dna
      );
  }

  function contractURI() public pure returns (string memory) {
        return "https://metadata.cryptobabies.com/metadata/contractinfo";
  }

  /*
      List of Owners TokenIds
  */
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public onlyOwner{
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % maxSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % maxSupply;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }
/*
    -------------------------------------
    ONLY OWNER
    -------------------------------------
    */
  function reveal() public onlyOwner {
      revealed = true;
  }

      /*
    * Set provenance once it's calculated
    */
  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    PROVENANCE = provenanceHash;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause() public onlyOwner {
    paused = !paused;
  }


  /*
      withdraw ETH from this contract
  */
  function withdraw() public onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }

  /**
   * Withdraw LINK from this contract
  */
  function withdrawLink() public onlyOwner {
      require(LINK.transfer(DAOAddress, LINK.balanceOf(address(this))), "Unable to transfer");
  }
}

