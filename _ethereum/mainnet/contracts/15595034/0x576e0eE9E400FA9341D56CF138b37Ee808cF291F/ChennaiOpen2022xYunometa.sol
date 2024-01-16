
/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//                                                                 //
//    _____.___.                                   __              //
//    \__  |   |__ __  ____   ____   _____   _____/  |______       //
//     /   |   |  |  \/    \ /  _ \ /     \_/ __ \   __\__  \      //
//     \____   |  |  /   |  (  <_> )  Y Y  \  ___/|  |  / __ \_    //
//     / ______|____/|___|  /\____/|__|_|  /\___  >__| (____  /    //
//     \/                 \/             \/     \/          \/     //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract ChennaiOpen2022xYunometa is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  // Predefined NFT Types
  uint8 private constant TANJORE_DOLL = 1;
  uint8 private constant RANGOLI = 2;
  uint8 private constant TICKET = 3;
  uint8 private constant GEN_ART = 4;
  uint8 private constant TOURISM = 5;
  uint8 private constant LOOTBOX = 6;
  uint8 private constant LOOTBOX_CONTENT_NFT = 7;

  uint256 private constant MAX_NFT_URI_GROUPS = 25;
  uint256 private constant MAX_NUM = 1000000000000;

  uint256 public maxMintAmountPerTx = 5;

  uint256 public NFTTypesCount;
  uint256 public LootBoxTypesCount;

  uint256 public ContractState = 2;
  // 0 = Paused
  // 1 = WL
  // 2 = Public Mint



    bool public Apply_Mint_Restriction;

    string public errorMetadataUri;

    mapping(uint256 => string) public NFT_metaDataURI_Hidden;

    mapping(uint256 => uint256) public NFT_maxSupply;
    mapping(uint256 => uint256) public NFT_metaFileId;
    mapping(uint256 => uint256) public NFT_totalMinted;
    mapping(uint256 => uint256) public NFT_totalRevealedCount;
    mapping(uint256 => uint256) public NFT_sellingPrice;
    mapping(uint256 => uint256) public NFT_maxMintAllowed;


    mapping(uint256 => uint256) public LB_Content_NFTCount;
    mapping(uint256 => uint256) public LB_Content_maxSupply;
    mapping(uint256 => uint256) public LB_Content_totalMinted;


    mapping(uint256 => uint256) internal mapTokenId_NFTFileNum;
    mapping(uint256 => mapping(uint256 => string)) public metaDataURIs;
    mapping(uint256 => mapping(uint256 => uint256)) public metaURIGroupCounts;

    mapping(address => mapping(uint8 => uint8)) public mintRestriction;
    mapping(address => uint256) internal contractAdmins;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {

    contractAdmins[msg.sender] = 1;
    Apply_Mint_Restriction  = true;
    initSmartContract();

  }



  modifier contractModifyCompliance() {
    require(contractAdmins[msg.sender] == 1, 'Only contract admins can perform this operation');
    _;
  }

  function contractAdmin_Add(address adminAddress) public onlyOwner {
      contractAdmins[adminAddress] = 1;
  }

  function contractAdmin_Remove(address adminAddress) public onlyOwner {
      contractAdmins[adminAddress] = 0;
  }


  function initSmartContract() internal {

    // uri for error meta data file
    errorMetadataUri  = 'https://bafybeiasrs4zthnbvrhiuithokikawcxsi5bw22z43ozcin3w4g7s24wtm.ipfs.nftstorage.link/hidden.json';

    // Configure the NFTs
    NFTTypesCount = 7;

    NFT_maxSupply[TANJORE_DOLL] = 0;
    NFT_maxSupply[RANGOLI] = 0;
    NFT_maxSupply[TICKET] = 0;
    NFT_maxSupply[GEN_ART] = 0;
    NFT_maxSupply[TOURISM] = 0;
    NFT_maxSupply[LOOTBOX] = 5000;
    NFT_maxSupply[LOOTBOX_CONTENT_NFT] = 12350;

    NFT_totalMinted[TANJORE_DOLL] = 0;
    NFT_totalMinted[RANGOLI] = 0;
    NFT_totalMinted[TICKET] = 0;
    NFT_totalMinted[GEN_ART] = 0;
    NFT_totalMinted[TOURISM] = 0;
    NFT_totalMinted[LOOTBOX] = 0;
    NFT_totalMinted[LOOTBOX_CONTENT_NFT] = 0;

    NFT_totalRevealedCount[TANJORE_DOLL] = 0;
    NFT_totalRevealedCount[RANGOLI] = 0;
    NFT_totalRevealedCount[TICKET] = 0;
    NFT_totalRevealedCount[GEN_ART] = 0;
    NFT_totalRevealedCount[TOURISM] = 0;
    NFT_totalRevealedCount[LOOTBOX] = 5000;
    NFT_totalRevealedCount[LOOTBOX_CONTENT_NFT] = 0;

    NFT_metaFileId[TANJORE_DOLL] = 10000;
    NFT_metaFileId[RANGOLI] = 20000;
    NFT_metaFileId[TICKET] = 30000;
    NFT_metaFileId[GEN_ART] = 40000;
    NFT_metaFileId[TOURISM] = 50000;
    NFT_metaFileId[LOOTBOX] = 60000;
    NFT_metaFileId[LOOTBOX_CONTENT_NFT] = 510000;


    NFT_maxMintAllowed[TANJORE_DOLL] = 5;
    NFT_maxMintAllowed[RANGOLI] = 5;
    NFT_maxMintAllowed[TICKET] = 5;
    NFT_maxMintAllowed[GEN_ART] = 5;
    NFT_maxMintAllowed[TOURISM] = 5;
    NFT_maxMintAllowed[LOOTBOX] = 10;
    NFT_maxMintAllowed[LOOTBOX_CONTENT_NFT] = 500;



    NFT_sellingPrice[TANJORE_DOLL] = 0.001 ether;
    NFT_sellingPrice[RANGOLI] = 0.001 ether;
    NFT_sellingPrice[TICKET] = 0.001 ether;
    NFT_sellingPrice[GEN_ART] = 0.001 ether;
    NFT_sellingPrice[TOURISM] = 0.001 ether;
    NFT_sellingPrice[LOOTBOX] = 0.013 ether;
    NFT_sellingPrice[LOOTBOX_CONTENT_NFT] = 0;


    NFT_metaDataURI_Hidden[TANJORE_DOLL] = '';
    NFT_metaDataURI_Hidden[RANGOLI] = '';
    NFT_metaDataURI_Hidden[TICKET] = '';
    NFT_metaDataURI_Hidden[GEN_ART] = '';
    NFT_metaDataURI_Hidden[TOURISM] = '';
    NFT_metaDataURI_Hidden[LOOTBOX] = '';
    NFT_metaDataURI_Hidden[LOOTBOX_CONTENT_NFT] = 'https://bafybeifortlg7kmqnnlmvcjkhchdn3hlkxs34owvagrhvc5cxakb45s6ji.ipfs.nftstorage.link/dummy.json';


    metaURIGroupCounts[TANJORE_DOLL][1] = 0;
    metaDataURIs[TANJORE_DOLL][1] = '';

    metaURIGroupCounts[RANGOLI][1] = 0;
    metaDataURIs[RANGOLI][1] = '';
    
    metaURIGroupCounts[TICKET][1] = 0;
    metaDataURIs[TICKET][1] = '';

    metaURIGroupCounts[GEN_ART][1] = 0;
    metaDataURIs[GEN_ART][1] = '';

    metaURIGroupCounts[TOURISM][1] = 0;
    metaDataURIs[TOURISM][1] = '';

    metaURIGroupCounts[LOOTBOX][1] = 5000;
    metaDataURIs[LOOTBOX][1] = 'https://bafybeiabbsx7auiiilhvz3ctmlx6sw6sut3yoimb5ldy2cohh6ksqd4vpe.ipfs.nftstorage.link/';

    metaURIGroupCounts[LOOTBOX_CONTENT_NFT][1] = 12350;
    metaDataURIs[LOOTBOX_CONTENT_NFT][1] = 'https://bafybeihlkkkoom2owtbjutgbvgzhenqj5w3ea5ymwpl3ivgq2yhxkx4lka.ipfs.nftstorage.link/';


    // Configure lootboxes

    LootBoxTypesCount = 4;
    LB_Content_NFTCount[1] = 2;
    LB_Content_maxSupply[1] = 3200;
    LB_Content_totalMinted[1] = 0;

    LB_Content_NFTCount[2] = 3;
    LB_Content_maxSupply[2] = 1400;
    LB_Content_totalMinted[2] = 0;

    LB_Content_NFTCount[3] = 4;
    LB_Content_maxSupply[3] = 250;
    LB_Content_totalMinted[3] = 0;

    LB_Content_NFTCount[4] = 5;
    LB_Content_maxSupply[4] = 150;
    LB_Content_totalMinted[4] = 0;
 
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public contractModifyCompliance() {
    require(_maxMintAmountPerTx >= 1, 'Incorrect Max Mint Amount');
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setErrorURI(string memory _URI) public contractModifyCompliance() {
    errorMetadataUri = _URI;
  }

  function setMintRestriction(bool _applyRestriction)  public contractModifyCompliance() {
    Apply_Mint_Restriction = _applyRestriction;
  }

  function modifyLootboxType(uint256 _LootboxId, uint256 _LootboxNFTCount, 
                      uint256 _maxSupply)  public contractModifyCompliance() {
    
    // when loot box type is added or modified then LootboxContentNFTs should be kept in sync
    require(_LootboxId <= LootBoxTypesCount, "Invalid Lootbox Id.");
    require(_maxSupply >= LB_Content_totalMinted[_LootboxId], "Maxsupply should be more than minted.");

    LB_Content_NFTCount[_LootboxId] = _LootboxNFTCount;
    LB_Content_maxSupply[_LootboxId] = _maxSupply;    
  }


  function modifyNFTType_Price(uint256 _NFTTypeId,  
                      uint256 _SellingPrice)  public contractModifyCompliance() {
    require(_NFTTypeId < LOOTBOX_CONTENT_NFT, "Invalid NFT Type.");

    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_sellingPrice.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _SellingPrice)
    }

  }


  function modifyNFTType_Supply(uint256 _NFTTypeId, uint256 _maxSupply)  public contractModifyCompliance() {
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");
    uint256 minted;
    uint256 fileid;

    minted = getMinted(_NFTTypeId);
    fileid = getFileid(_NFTTypeId);

    require(_maxSupply >= minted, "Max Supply less than Total Minted.");
    require(fileid + _maxSupply < MAX_NUM, "Invalid Max Supply.");

    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_maxSupply.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _maxSupply)
    }
  }



  function modifyNFTType_RevealCount(uint256 _NFTTypeId, uint256 _revealCount 
                      )  public contractModifyCompliance() {
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");

    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_totalRevealedCount.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _revealCount)
    }

  }

  function modifyNFTType_HiddenURI(uint256 _NFTTypeId,  
                      string memory _metaDataURI_hidden)  public contractModifyCompliance() {
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");

      NFT_metaDataURI_Hidden[_NFTTypeId] = _metaDataURI_hidden;
  }

  function modifyNFTType_FileId(uint256 _NFTTypeId,  
                       uint256 _metaFileId)  public contractModifyCompliance() {

    uint256 minted;
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");
    require(_metaFileId < MAX_NUM, "Invalid File Id.");

    minted = getMinted(_NFTTypeId);
    require(minted == 0, "Cannot change file id for minted NFTs.");

    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_metaFileId.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _metaFileId)
    }
  }


  function modifyNFTType_MaxMintAllowed(uint256 _NFTTypeId,  
                       uint8 _maxMints)  public contractModifyCompliance() {

    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");
    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_maxMintAllowed.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _maxMints)
    }
  }




  function modifyNFTType_AddMetaURIGroup(uint256 _NFTTypeId,  
                      uint256 _uriGroupCount, string memory _metaDataURI)  public contractModifyCompliance() {
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");
    uint256 i;
    unchecked { 
      i = 1;
      while (i < MAX_NFT_URI_GROUPS) {
        if (metaURIGroupCounts[_NFTTypeId][i] == 0) {
          break;
        } else {
          i++; 
        }
      }
    }
    require(i < MAX_NFT_URI_GROUPS, "Max URIs already added.");
    metaURIGroupCounts[_NFTTypeId][i] = _uriGroupCount;
    metaDataURIs[_NFTTypeId][i] = _metaDataURI;
  }



  function modifyNFTType_ChangeMetaURIGroup(uint256 _NFTTypeId,  uint256 _groupId,
                      uint256 _uriGroupCount, string memory _metaDataURI)  public contractModifyCompliance() {
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");

    metaURIGroupCounts[_NFTTypeId][_groupId] = _uriGroupCount;
    metaDataURIs[_NFTTypeId][_groupId] = _metaDataURI;
  }


  function getMetaURIGroupCount(uint256 _NFTTypeId, uint256 _groupId) public view returns (uint256) {
    return metaURIGroupCounts[_NFTTypeId][_groupId];
  }

  function getMetaGroupURI(uint256 _NFTTypeId, uint256 _groupId) public view returns (string memory) {
    return metaDataURIs[_NFTTypeId][_groupId];
  }


  function getTokenMetaFileName(uint256 _tokenId) public view returns (uint256) {
    require(_exists(_tokenId), 'query for non existent token');
    uint256[] memory tempMem =new uint256[](2);
    uint256 i;
    uint256 nftFileName;

    assembly {
      i := _tokenId
      mstore(tempMem, i)
      mstore(add(tempMem, 0x20),  mapTokenId_NFTFileNum.slot)
      let hash := keccak256(tempMem, 64)
      nftFileName := sload(hash)
      for {} eq(nftFileName, 0) {} {
        i := sub(i,1)
        mstore(tempMem, i)
        hash := keccak256(tempMem, 64)
        nftFileName := sload(hash)
        if eq(i, 1) {
          break
        }
      }
      nftFileName := add(nftFileName, sub(_tokenId, i))
    }

    return nftFileName;
  }


  function getTokenNFTType(uint256 _tokenId) public view returns (uint256) {
    
    require(_exists(_tokenId), 'query for non existent token');
    uint256 i;
    uint256 tokenFile;

    unchecked {
      tokenFile = getTokenMetaFileName(_tokenId);
      assembly {
        i := div(tokenFile, 10000)
        if gt(i, sload(NFTTypesCount.slot)) {
          i := LOOTBOX_CONTENT_NFT
        }
      }
    }
    return i;
  }


  function randomNum(uint256 _rand) public view returns (uint256) {
    uint256 num;
    unchecked { 
      num  = (uint256(keccak256(abi.encode( _rand, msg.sender, block.timestamp, 5001))) % 5000) + 1;
      assembly {
        switch lt(num, 3201) 
        case true {
          num := 1
        }        
        default {
          switch lt(num, 4601)  
          case true {
            num := 2
          }        
          default {
            switch lt(num, 4851) 
            case true {
              num := 3
            }        
            default {
              num := 4
            }
          }
        }
      }
    }
    return num;
  }

  function isAdmin(address _add) public view returns (bool) {
    return contractAdmins[_add] > 0
        ? true
        : false;
  }


  
  function whitelistMint(uint8 _NFTTypeID, uint256 _mintAmount, bytes32[] memory _merkleProof) public payable 
    {
    // Verify whitelist requirements
    uint256 supply;
    uint256 fileid;
    uint256 minted;
    uint256 myMinted;
    uint256 price;
    uint256 maxMints;
    uint256[] memory tempMem =new uint256[](2);
    

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

      require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Not included in whitelist!');
      require(ContractState == 1, 'Invalid mint type!');
      require(_NFTTypeID < LOOTBOX_CONTENT_NFT, 'Invalid NFT Type!');

    minted = getMinted(_NFTTypeID);
    supply = getSupply(_NFTTypeID);
    price = getCost(_NFTTypeID);

    
    unchecked {
      require((_mintAmount > 0) && (_mintAmount <= maxMintAmountPerTx), 'Mint Count More Than Max Allowed.');
      require((_mintAmount + minted) <= supply, 'Mint amount more than available!');
      require(msg.value  >= (price * _mintAmount), 'Insufficient Funds!');
    }

    fileid = getFileid(_NFTTypeID);
    supply = totalSupply();

    unchecked {
      if (Apply_Mint_Restriction) {
        maxMints = getMaxMintAllowed(_NFTTypeID);
        myMinted = mintRestriction[msg.sender][_NFTTypeID];
        require((myMinted + _mintAmount) <= maxMints, 'Mint Count More Than Max Allowed.');
      }
    }

    assembly {

      mstore(tempMem, _NFTTypeID)
      mstore(add(tempMem, 0x20),  NFT_totalMinted.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, add(minted, _mintAmount))


      fileid := add(fileid, minted)

      mstore(tempMem, add(supply, 1))
      mstore(add(tempMem, 0x20),  mapTokenId_NFTFileNum.slot)
      hash := keccak256(tempMem, 64)
      sstore(hash, add(fileid,1))
    }


    unchecked {
      if (Apply_Mint_Restriction) {
        mintRestriction[msg.sender][_NFTTypeID] = uint8(myMinted + _mintAmount);
      }
    }

    _safeMint(_msgSender(), _mintAmount);
  }


  function mint(uint8 _NFTType, uint256 _mintAmount) public payable 
   {

    uint256 supply;
    uint256 fileid;
    uint256 minted;
    uint256 price;
    uint256 myMinted;
    uint256 maxMints;
    uint256[] memory tempMem =new uint256[](2);

    minted = getMinted(_NFTType);
    supply = getSupply(_NFTType);
    price = getCost(_NFTType);

  unchecked {

    require((_mintAmount + minted) <= supply, 'Mint amount more than available!');
    require(msg.value  >= (price * _mintAmount), 'Insufficient Funds!');
    require(ContractState == 2, 'Invalid mint type!');
    require(_NFTType < LOOTBOX_CONTENT_NFT, 'Invalid NFT Type!');
    require((_mintAmount > 0) && (_mintAmount <= maxMintAmountPerTx), 'Mint Count More Than Max Allowed.');

  }

    fileid = getFileid(_NFTType);
    supply = totalSupply();

    unchecked {

      if (Apply_Mint_Restriction) {
        myMinted = mintRestriction[msg.sender][_NFTType];
        maxMints = getMaxMintAllowed(_NFTType);
        require((myMinted + _mintAmount) <= maxMints, 'Mint Count More Than Max Allowed.');
      }
    }

    assembly {

      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_totalMinted.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, add(minted, _mintAmount))

      fileid := add(fileid, minted)
      mstore(tempMem, add(supply, 1))
      mstore(add(tempMem, 0x20),  mapTokenId_NFTFileNum.slot)
      hash := keccak256(tempMem, 64)
      sstore(hash, add(fileid,1))

    }
    unchecked {
      if (Apply_Mint_Restriction) {
        mintRestriction[msg.sender][_NFTType] = uint8(myMinted + _mintAmount);
      }
    }
    _safeMint(_msgSender(), _mintAmount);
  }
  


  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    uint256 supply = totalSupply();
    address tokenOwner;

    unchecked {
      while (ownedTokenIndex < ownerTokenCount && currentTokenId <= supply) {
        tokenOwner = ownerOf(currentTokenId);
        if (tokenOwner == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;
          ownedTokenIndex++;
        }
        currentTokenId++;
      }
    }
    return ownedTokenIds;
  }

  function findMyLootbox() public view returns (uint256) {

    uint256 supply;

    uint256 currentTokenId = 1;
    address tokenOwner;
    uint256 lootboxId;

    supply = totalSupply();
    require(supply > 0, 'findMyLootbox - query for non existent token');

    unchecked {
      while (currentTokenId <= supply) {
        if (getTokenNFTType(currentTokenId) == LOOTBOX) {
          tokenOwner = ownerOf(currentTokenId);
          if (tokenOwner == msg.sender) {
            lootboxId = currentTokenId;
            break;
          }
        }
        currentTokenId++;
      }
    }
    return lootboxId;
  }

  function walletOfOwner_FindLootbox(address _owner, uint256 _startCountTokenId) public view returns (uint256) {
    require(_exists(_startCountTokenId), 'query for non existent token');
    uint256 currentTokenId = _startCountTokenId;
    uint256 supply = totalSupply();
    address tokenOwner;
    uint256 lootboxId;

    unchecked {
      while (currentTokenId <= supply) {
        if (getTokenNFTType(currentTokenId) == LOOTBOX) {
          tokenOwner = ownerOf(currentTokenId);
          if (tokenOwner == _owner) {
            lootboxId = currentTokenId;
            break;
          }
        }
        currentTokenId++;
      }

    }

    return lootboxId;
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }


  function mintLootboxContents(address _from) internal {
    uint256 supply;
    uint256 i;
    uint256 fileStartNum;
    uint256 minted;
    uint256 fileid;
    uint256 maxSupply;
    uint256 lootBoxType;
    uint256 mintAmount;
    uint256[] memory tempMem =new uint256[](2);
    string memory errText;

    errText = "Cannot burn lootbox";
    supply = totalSupply();
    lootBoxType = randomNum(supply);

    minted = getMinted(LOOTBOX_CONTENT_NFT);
    fileid = getFileid(LOOTBOX_CONTENT_NFT);
    maxSupply = getSupply(LOOTBOX_CONTENT_NFT);
    
    assembly {

      mstore(tempMem, lootBoxType)
      mstore(add(tempMem, 0x20),  LB_Content_totalMinted.slot)
      let hash := keccak256(tempMem, 64)
      let lbMinted := sload(hash)
      
      mstore(add(tempMem, 0x20),  LB_Content_maxSupply.slot)
      hash := keccak256(tempMem, 64)
      let lbSupply := sload(hash)
      
     
      switch lt(lbMinted, lbSupply)
      case true {
        mstore(add(tempMem, 0x20),  LB_Content_NFTCount.slot)
        hash := keccak256(tempMem, 64)
        mintAmount := sload(hash)
      }
      default {
        for {i:=1} or(lt(i,4), eq(i,4) ) {i:= add(i,1)} {
          mstore(tempMem, i)
          mstore(add(tempMem, 0x20),  LB_Content_totalMinted.slot)
          hash := keccak256(tempMem, 64)
          lbMinted := sload(hash)
      
          mstore(add(tempMem, 0x20),  LB_Content_maxSupply.slot)
          hash := keccak256(tempMem, 64)
          lbSupply := sload(hash)
          if lt(lbMinted, lbSupply) {
            lootBoxType := i
            break 
          }
        }


        if gt(lootBoxType,4) {
          revert(add(errText, 0x20), mload(errText))
        }
        mstore(tempMem, lootBoxType)
        mstore(add(tempMem, 0x20),  LB_Content_NFTCount.slot)
        hash := keccak256(tempMem, 64)
        mintAmount := sload(hash)
      }

      if lt(maxSupply, add(minted, mintAmount)) {
          revert(add(errText, 0x20), mload(errText))
      }

        fileStartNum := add(fileid, minted)

        mstore(tempMem, LOOTBOX_CONTENT_NFT)
        mstore(add(tempMem, 0x20),  NFT_totalMinted.slot)
        hash := keccak256(tempMem, 64)
        sstore(hash, add(minted, mintAmount))

        mstore(tempMem, add(supply, 1))
        mstore(add(tempMem, 0x20),  mapTokenId_NFTFileNum.slot)
        hash := keccak256(tempMem, 64)
        sstore(hash, add(fileStartNum,1))

        mstore(tempMem, lootBoxType)
        mstore(add(tempMem, 0x20),  LB_Content_totalMinted.slot)
        hash := keccak256(tempMem, 64)
        sstore(hash, add(sload(hash),1))
    }

    _safeMint(_from, mintAmount);

  }
  

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {

      uint256 NFTType;
      NFTType = getTokenNFTType(tokenId);

      if ((NFTType == LOOTBOX) ) {
        if ( (to == address(0)) || (to == address(0x000000000000000000000000000000000000dEaD))) {
          require(ownerOf(tokenId) == from, "Only NFT owner can burn");
          mintLootboxContents(msg.sender);
        }
      }

        super.safeTransferFrom(from, to, tokenId);

    }


    function burnLootbox(uint256 _lbTokenId) public {

      safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _lbTokenId);

      return;
    }


  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'URI query for non existent token');
    string memory currentBaseURI;
    uint256 nftType;
    uint256 nftFileName;
    uint256 nftNum;


    unchecked {
      nftFileName = getTokenMetaFileName(_tokenId);

      assembly {
        nftType := div(nftFileName, 10000)
        if gt(nftType, sload(NFTTypesCount.slot)) {
          nftType := LOOTBOX_CONTENT_NFT
        }
      }

      nftNum = nftFileName - getFileid(nftType);
      currentBaseURI = getNFTURI(nftType, nftNum, nftFileName);

    }

    return bytes(currentBaseURI).length > 10 ? currentBaseURI : errorMetadataUri;
          
  }


 


  function getNFTURI(uint256 _NFTType, uint256 _NFTNum, uint256 _NFTFileName) public view returns (string memory) {

    string memory NFTUri = "";
    uint256 i;
    uint256  count;

    if (_NFTNum > getRevealCount(_NFTType)) {
      NFTUri = getHiddenURI(_NFTType);
    } else {
       count = 0;
        for (i = 1; i < MAX_NFT_URI_GROUPS; i++) {
          count = count + metaURIGroupCounts[_NFTType][i];
          if (_NFTNum <= count) {
            NFTUri = metaDataURIs[_NFTType][i];
            NFTUri = string(abi.encodePacked(NFTUri, _NFTFileName.toString(), '.json'));
            break;
          }
        }
    }

    return NFTUri;
  }




  function getRevealCount(uint256 _NFTType) public view returns (uint256) {

    uint256 count;
    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_totalRevealedCount.slot)
      let hash := keccak256(tempMem, 64)
      count := sload(hash)
    }
    return count;
  }


  function getHiddenURI(uint256 _NFTType) public view returns (string memory) {

    return NFT_metaDataURI_Hidden[_NFTType];
  }



  function getSupply(uint256 _NFTType) public view returns (uint256) {

    uint256 supply;
    
    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_maxSupply.slot)
      let hash := keccak256(tempMem, 64)
      supply := sload(hash)
    }

    return supply;
  }

  function getFileid(uint256 _NFTType) public view returns (uint256) {

    uint256 fileid;

    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_metaFileId.slot)
      let hash := keccak256(tempMem, 64)
      fileid := sload(hash)
    }

    return fileid;
  }



  function getMinted(uint256 _NFTType) public view returns (uint256) {

    uint256 minted;

    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_totalMinted.slot)
      let hash := keccak256(tempMem, 64)
      minted := sload(hash)
    }

    return minted;
  }


  function getCost(uint256 _NFTType) public view returns (uint256) {
    uint256 price;

    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_sellingPrice.slot)
      let hash := keccak256(tempMem, 64)
      price := sload(hash)
    }
    return price;
  }


  function getMaxMintAllowed(uint256 _NFTType) public view returns (uint256) {
    uint256 maxMints;

    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_maxMintAllowed.slot)
      let hash := keccak256(tempMem, 64)
      maxMints := sload(hash)
    }
    return maxMints;
  }



  function setContractState(uint256 _state) public contractModifyCompliance() {
    ContractState = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public contractModifyCompliance() {
    merkleRoot = _merkleRoot;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

 
  fallback() external{
  }
}
