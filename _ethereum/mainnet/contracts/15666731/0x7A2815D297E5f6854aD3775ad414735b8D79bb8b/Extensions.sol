// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./console.sol";
import "./ERC721.sol";
//access control
import "./AccessControl.sol";

// Helper functions OpenZeppelin provides.
import "./Counters.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Base64.sol";
import "./EnumerableMap.sol";

//import "./MetropolisWorldGenesis.sol";

/**
 * @dev functions which this contract call in the main property contract */
interface PropInterface {
  function attachExtension(uint propTokenId, uint extTokenId, address owner)external;

  function detachExtension(uint propId, uint extTokenId, address owner)external;

  function ownerOf(uint256 tokenId) external returns (address);

  function checkExtensionOwnership(uint propTokenId, uint extTokenId)external view returns (bool);
}

interface PropInterfaceCity2 {
  function attachExtension(uint propTokenId, uint extTokenId, address owner)external;

  function detachExtension(uint propId, uint extTokenId, address owner)external;

  function ownerOf(uint256 tokenId) external returns (address);

  function checkExtensionOwnership(uint propTokenId, uint extTokenId)external view returns (bool);
}

interface PropInterfaceCity3 {
  function attachExtension(uint propTokenId, uint extTokenId, address owner)external;

  function detachExtension(uint propId, uint extTokenId, address owner)external;

  function ownerOf(uint256 tokenId) external returns (address);

  function checkExtensionOwnership(uint propTokenId, uint extTokenId)external view returns (bool);
}

interface PropInterfaceCity4 {
  function attachExtension(uint propTokenId, uint extTokenId, address owner)external;

  function detachExtension(uint propId, uint extTokenId, address owner)external;

  function ownerOf(uint256 tokenId) external returns (address);

  function checkExtensionOwnership(uint propTokenId, uint extTokenId)external view returns (bool);
}

interface PropInterfaceCity5 {
  function attachExtension(uint propTokenId, uint extTokenId, address owner)external;

  function detachExtension(uint propId, uint extTokenId, address owner)external;

  function ownerOf(uint256 tokenId) external returns (address);

  function checkExtensionOwnership(uint propTokenId, uint extTokenId)external view returns (bool);
}

interface PropInterfaceCity6 {
  function attachExtension(uint propTokenId, uint extTokenId, address owner)external;

  function detachExtension(uint propId, uint extTokenId, address owner)external;

  function ownerOf(uint256 tokenId) external returns (address);

  function checkExtensionOwnership(uint propTokenId, uint extTokenId)external view returns (bool);
}

contract Extensions is ERC721, AccessControl {
  bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
  // bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
  address private PROPERTY_CONTRACT;
  address private PROPERTY_CONTRACT_2;
  address private PROPERTY_CONTRACT_3;
  address private PROPERTY_CONTRACT_4;
  address private PROPERTY_CONTRACT_5;
  address private PROPERTY_CONTRACT_6;
  PropInterface PropContract;
  PropInterfaceCity2 PropContract2;
  PropInterfaceCity3 PropContract3;
  PropInterfaceCity4 PropContract4;
  PropInterfaceCity5 PropContract5;
  PropInterfaceCity6 PropContract6;
  // The tokenId is the NFTs unique identifier, it's just a number that goes
  // 0, 1, 2, 3, etc.
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  Counters.Counter private _extensionIds;

  uint16 _percentMetWorldTakes = 10;
  address payable private _paymentSplitContract;

  struct Extension {
    uint256 id;
    string category;
    string name;
    string description;
    string image;
    string media;
    string artist;
    address payable createdBy;
    uint16 available;
    uint256 price;
    bool approved;
  }
  //wallets that can build extensions
  mapping(address => bool) approvedWallet;
  // default of if a extension is approved or not
  bool public defaultApproved = false;
  // map extension to extension id
  mapping(uint256 => Extension) _extensions_list;
  //array of approved extensions
  using EnumerableMap for EnumerableMap.UintToUintMap; //maps the extension id to value to indicate approval, 1 is not approved 2 is approved 
  EnumerableMap.UintToUintMap private approved;
  // Extension[] private _approved_extensions;
  // uint256[] private not_approved_extensions;
  //map extension to token ID
  mapping(uint256 => uint256) _nftExtensionAttributes; //maps tokenid to extension id

  constructor(address prop, address payable paySplit)
    ERC721("Metropolis World Property Extension", "METPE")
  {
    PROPERTY_CONTRACT = prop;
    PropContract = PropInterface(PROPERTY_CONTRACT);
    _paymentSplitContract = paySplit;
    // I increment _tokenIds here so that my first NFT has an ID of 1.
    _tokenIds.increment();
    _extensionIds.increment();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(UPDATER_ROLE, msg.sender);
  }

  function supportsInterface(bytes4 interfaceId)public view virtual override(ERC721, AccessControl) returns (bool){
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev used to add the addreses of the various city contracts so the extension can be added to a property.
   * @param city the number of the from 1 to 6
   * @param contractAddress the address of the contract to be connected
   */
  function addCityContractDetials(uint8 city, address contractAddress) external onlyRole(UPDATER_ROLE){
    require(contractAddress != address(0), "Please enter valid contract address");
    if (city == 1) {
      PROPERTY_CONTRACT = contractAddress;
      PropContract = PropInterface(PROPERTY_CONTRACT);
    } else if (city == 2) {
      PROPERTY_CONTRACT_2 = contractAddress;
      PropContract2 = PropInterfaceCity2(PROPERTY_CONTRACT_2);
    } else if (city == 3) {
      PROPERTY_CONTRACT_3 = contractAddress;
      PropContract3 = PropInterfaceCity3(PROPERTY_CONTRACT_3);
    } else if (city == 4) {
      PROPERTY_CONTRACT_4 = contractAddress;
      PropContract4 = PropInterfaceCity4(PROPERTY_CONTRACT_4);
    } else if (city == 5) {
      PROPERTY_CONTRACT_5 = contractAddress;
      PropContract5 = PropInterfaceCity5(PROPERTY_CONTRACT_5);
    } else if (city == 6) {
      PROPERTY_CONTRACT_6 = contractAddress;
      PropContract6 = PropInterfaceCity6(PROPERTY_CONTRACT_6);
    }
  }

  /**
   *@dev step1 in the extension process is to build it, add the metadata
   *@notice extensions can not be minted until approved
   *@param ex a object which is the metadata for the extension
   */
  function buildExtension(Extension memory ex) external {
    require(ex.createdBy != address(0), "invalid created by wallet");
    
    ex.id = _extensionIds.current();
    //check to determine approval.
    ex.approved = defaultApproved;
    if (approvedWallet[msg.sender] == true) {
      ex.approved = true;
    }
    _extensions_list[ex.id] = ex;
    if (ex.approved) {
      EnumerableMap.set(approved, ex.id, 2);
      // _approved_extensions.push(ex);
    } else {
      EnumerableMap.set(approved, ex.id, 1);
      // not_approved_extensions.push(ex.id);
    }
    // console.log("Built an extension: ", _extensionIds.current());
    _extensionIds.increment();
  }

  /**
   * @dev step 2 is approve the extension for sale/minting.
   * @notice approvals done by Metropolis team to avoid offensive images
   *@param exId the id of the extension
   */
  function approveExtension(uint256 exId) external onlyRole(UPDATER_ROLE) {
    Extension memory ex = _extensions_list[exId];
    ex.approved = true;
    _extensions_list[exId] = ex;
    EnumerableMap.set(approved, ex.id, 2);
  }


  /**
  @dev main payable function to mint the extension 
  @notice only extensions which have been approved can be minted. 
  @param exId the id of the extension 
   */
  function mintExtension(uint256 exId) external payable {
    //check if available
    require(_extensions_list[exId].available > 0, "None left of these");
    //check if approved
    require(
      _extensions_list[exId].approved,
      "Extention still awaitng approval"
    );
    //check paid enough
    require(_extensions_list[exId].price <= msg.value, "not paid enough");
    _safeMint(msg.sender, _tokenIds.current());
    _nftExtensionAttributes[_tokenIds.current()] = exId;
    _tokenIds.increment();
    //split payment between creator and us
    uint256 toCreator = (msg.value * (100 - _percentMetWorldTakes)) / 100;
    address payable toCreatorAdd = _extensions_list[exId].createdBy;
    Address.sendValue(toCreatorAdd, toCreator);
    Address.sendValue(_paymentSplitContract, address(this).balance);
  }

  /**
  @dev used by the creator of an extension to set the mint price 
  @param exId the id of the extension
  @param newPrice how much you want it to mint for 
   */
  function setMintPrice(uint256 exId, uint256 newPrice) external {
    require(
      msg.sender == _extensions_list[exId].createdBy,
      "You can't update this price"
    );
    _extensions_list[exId].price = newPrice;
  }

  /**
  @dev used if a users wants to transfer the ownership of an extension
  @notice this transfer the rights to mint proceeds but not NFT itself.  
  @param exId id of the extension to transer 
  @param to the address of the new owner 
   */
  function transferCreatedBy(uint256 exId, address payable to) external {
    require(to != address(0), "Needs to be a valid address");
    require(
      msg.sender == _extensions_list[exId].createdBy,
      "You can't do this transfer"
    );
    _extensions_list[exId].createdBy = to;
  }

  /**
  @dev changes defualt setting fro approving extensions 
  @param val bool to set default too
  */
  function setDefaultApprove(bool val) external onlyRole(UPDATER_ROLE) {
    defaultApproved = val;
  }

  /**
  @dev checks if an extension is approved. 
  @param exId the id of the extension.  
   */
  function checkNotApproved(uint exId) external view returns (uint256) {
    return EnumerableMap.get(approved,exId,"Id is not found");
  }

  /**
    @dev some wallets don't need approval, they can be added here. 
    @param wallet address to add to list 
  */
  function addApprovedWallet(address wallet) external onlyRole(UPDATER_ROLE) {
    approvedWallet[wallet] = true;
  }

  /**
    @dev some wallets don't need approval, they can be removed here. 
    @param wallet address to remove from list 
  */
  function removeApprovedWallet(address wallet)external onlyRole(UPDATER_ROLE){
    approvedWallet[wallet] = false;
  }

  /**
    @dev some wallets don't need approval, check it is approved here. 
    @param wallet address to check 
  */
  function checkIfApproved(address wallet) external view returns (bool) {
    return approvedWallet[wallet];
  }

  /**
  @dev as the platform we take a cut this set that amount. 
  @param percent the percentage amount 2 = 2% 
   */
  function setPercentageMetWorldTakes(uint16 percent)external onlyRole(UPDATER_ROLE){
    _percentMetWorldTakes = percent;
  }

  /**
  @dev used to change the payment split contract if needed 
  @param newContract address of the new split contract 
   */
  function updatePaymentSplitContract(address payable newContract) external onlyRole(UPDATER_ROLE) {
    require(newContract != address(0), "Needs to be a valid address");
    _paymentSplitContract = newContract;
  }

  /**
  @dev get detials of an extension which has been built but might not yet be minted
  @param exId the id of the extension you want to get detials of. 
   */
  function getBuiltExtension(uint256 exId)external view returns (Extension memory){
    Extension memory ex = _extensions_list[exId];
    return ex;
  }

  /**
  @dev return full metadata of an extension after it is minted. 
  @param tokenId the tokenId of the extension 
   */
  function getExtensionMetaData(uint tokenId)external view returns(Extension memory){
    return _extensions_list[_nftExtensionAttributes[tokenId]];
  }

  /**
   *@dev this transfer ownership to the property contract which links it to a property
   *@dev the owner of the property can unlink it at anytime or sell the property with the extension attached
   *@notice you must own the property and extension to call this function
   *@param tokenId this is the tokenId of the extension NFT
   *@param propTokenId this it the tokenId of the property NFT
   @param city number rep city 1 = city1 etc.
   */
  function attachToProperty(uint8 city, uint256 tokenId, uint256 propTokenId) external {
    if (city == 1) {
      require(PropContract.ownerOf(propTokenId) == msg.sender, "Not the owner of the property");
      require(ownerOf(tokenId) == msg.sender, "Not the owner of the extension");
      _transfer(msg.sender, PROPERTY_CONTRACT, tokenId);
      console.log("transfered to property contract");
      PropContract.attachExtension(propTokenId, tokenId, msg.sender);
    } else if (city == 2) {
      require(PropContract2.ownerOf(propTokenId) == msg.sender,"Not the owner of the property");
      require(ownerOf(tokenId) == msg.sender, "Not the owner of the extension");
      _transfer(msg.sender, PROPERTY_CONTRACT_2, tokenId);
      console.log("transfered to property contract");
      PropContract2.attachExtension(propTokenId, tokenId, msg.sender);
    } else if (city == 3) {
      require(
        PropContract3.ownerOf(propTokenId) == msg.sender,
        "Not the owner of the property"
      );
      require(ownerOf(tokenId) == msg.sender, "Not the owner of the extension");
      _transfer(msg.sender, PROPERTY_CONTRACT_3, tokenId);
      console.log("transfered to property contract");
      PropContract3.attachExtension(propTokenId, tokenId, msg.sender);
    } else if (city == 4) {
      require(
        PropContract4.ownerOf(propTokenId) == msg.sender,
        "Not the owner of the property"
      );
      require(ownerOf(tokenId) == msg.sender, "Not the owner of the extension");
      _transfer(msg.sender, PROPERTY_CONTRACT_4, tokenId);
      console.log("transfered to property contract");
      PropContract4.attachExtension(propTokenId, tokenId, msg.sender);
    } else if (city == 5) {
      require(
        PropContract5.ownerOf(propTokenId) == msg.sender,
        "Not the owner of the property"
      );
      require(ownerOf(tokenId) == msg.sender, "Not the owner of the extension");
      _transfer(msg.sender, PROPERTY_CONTRACT_5, tokenId);
      console.log("transfered to property contract");
      PropContract5.attachExtension(propTokenId, tokenId, msg.sender);
    } else if (city == 6) {
      require(
        PropContract6.ownerOf(propTokenId) == msg.sender,
        "Not the owner of the property"
      );
      require(ownerOf(tokenId) == msg.sender, "Not the owner of the extension");
      _transfer(msg.sender, PROPERTY_CONTRACT_6, tokenId);
      console.log("transfered to property contract");
      PropContract6.attachExtension(propTokenId, tokenId, msg.sender);
    }
  }

  function detachFromProperty(uint8 city, uint256 tokenId, uint propId) external {
    if (city == 1) {
      require(PropContract.ownerOf(propId) == msg.sender, "Not the owner of the property");
      require(PropContract.checkExtensionOwnership(propId, tokenId),"This extension not owned by this property");
      _transfer(PROPERTY_CONTRACT, msg.sender, tokenId);
      PropContract.detachExtension(propId, tokenId, msg.sender);
    } else if (city == 2) {
      require(
        PropContract2.ownerOf(propId) == msg.sender,
        "Not the owner of the property"
      );
      require(
        PropContract2.checkExtensionOwnership(propId, tokenId),
        "This extension not owned by this property"
      );
      _transfer(PROPERTY_CONTRACT_2, msg.sender, tokenId);
      PropContract2.detachExtension(propId, tokenId, msg.sender);
    } else if (city == 3) {
      require(
        PropContract3.ownerOf(propId) == msg.sender,
        "Not the owner of the property"
      );
      require(
        PropContract3.checkExtensionOwnership(propId, tokenId),
        "This extension not owned by this property"
      );
      _transfer(PROPERTY_CONTRACT_3, msg.sender, tokenId);
      PropContract3.detachExtension(propId, tokenId, msg.sender);
    } else if (city == 4) {
      require(
        PropContract4.ownerOf(propId) == msg.sender,
        "Not the owner of the property"
      );
      require(
        PropContract4.checkExtensionOwnership(propId, tokenId),
        "This extension not owned by this property"
      );
      _transfer(PROPERTY_CONTRACT_4, msg.sender, tokenId);
      PropContract4.detachExtension(propId, tokenId, msg.sender);
    } else if (city == 5) {
      require(
        PropContract5.ownerOf(propId) == msg.sender,
        "Not the owner of the property"
      );
      require(
        PropContract5.checkExtensionOwnership(propId, tokenId),
        "This extension not owned by this property"
      );
      _transfer(PROPERTY_CONTRACT_5, msg.sender, tokenId);
      PropContract5.detachExtension(propId, tokenId, msg.sender);
    } else if (city == 6) {
      require(
        PropContract6.ownerOf(propId) == msg.sender,
        "Not the owner of the property"
      );
      require(
        PropContract6.checkExtensionOwnership(propId, tokenId),
        "This extension not owned by this property"
      );
      _transfer(PROPERTY_CONTRACT_6, msg.sender, tokenId);
      PropContract6.detachExtension(propId, tokenId, msg.sender);
    }
  }

  function extensionNameList(uint256[] calldata exts)
    external
    view
    returns (bytes memory)
  {
    if (exts.length > 0) {
      bytes memory st = abi.encodePacked(
        '"},{"trait_type": "Extensions", "value": " '
      );
      for (uint i = 0; i < exts.length; i++) {
        st = abi.encodePacked(
          st,
          _extensions_list[_nftExtensionAttributes[exts[i]]].name,
          " "
        );
      }
      return st;
    }
    bytes memory x = abi.encodePacked("");
    return x;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    Extension memory ex = _extensions_list[_nftExtensionAttributes[_tokenId]];
    bytes memory dataURI = abi.encodePacked(
      '{"name": "',
      ex.name,
      '", "description": "',
      ex.description,
      '", "image": "',
      ex.image,
      '", "animation_url": "',
      ex.media,
      '", "attributes": [{ "trait_type": "Category", "value": "',
      ex.category,
      '"},{"trait_type": "Artist", "value": "',
      ex.artist,
      '"}]}'
    );
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(dataURI)
        )
      );
  }
}
// '"},{"trait_type": "Lore", "value": "',
//       ex.text,