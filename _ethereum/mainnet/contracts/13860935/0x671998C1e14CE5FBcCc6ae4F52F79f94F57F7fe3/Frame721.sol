// SPDX-License-Identifier: GPL-3.0

/*
       %%%%%%%   &%%%%%,      %%      %%%     %%%    %%%%%%    %%%%%%        %%%%%%%%%%%%%%%%%%%    
       %%#       &%   %%.    (%%%     %%%%   #%%%    %%        %%   %%                       %%%    
       %%#       &%   &%     %&.%.    %%%%%  % %%    %%        %%   %%                       %%%    
       %%%%%%    &%%%%#     &%  %%    %%% %%%% %%    %%%%%%    %%   %%                       %%%    
       %%#       &%  %%     %%%%%%(   %%% #%%  %%    %%        %%   %%                       %%%    
       %%#       &%   %%    %%   %%   %%%      %%    %%        %%   %%                       %%%    
       %%#       &%    %%   %%   %%   %%%      %%    %%%%%%    %%&%&%%                       %%%    
                                                                                             %%%    
                                                                                             %%%    
                                                                                             %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                               Frames Contract                                     %%%    
       %%#                              https://framed.app                                   %%%    
       %%#                                 @nft_framed                                       %%%    
       %%#                                   2021-12                                         %%%    
       %%#                               Code by JD & BC                                     %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   %%%    
       %%#                                                                                   &%%    
       %%#                                                                                          
       %%#                                                                                          
       %%#                                                                                          
       %%#                                                         %%    %%    %%%%%%  %%%%%%%%%%    
       %%#                                                         %%%   %%    %%          %%       
       %%#                                                         %%%%  %%    %%          %%       
       %%#                                                         %% %% %%    %%%%%%      %%       
       %%#                                                         %%  %%%%    %%          %%       
       %%%                                                         %%   %%%    %%          %%       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&          %%    %%    %%          %%           
*/

pragma solidity >=0.7.0 <0.9.0;

import "./Strings.sol";
import "./Counters.sol";

import "./ERC721Extended.sol";
import "./IFrameMetadata.sol";

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy { }

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract Frame721 is IFrameMetadata, ERC721Extended {
    using Strings for uint256;
    using Counters for Counters.Counter;

    struct Record {
      string record;
      uint256 lastIndex;
    } 

    Record[] public records;
    string baseFramedURI;

    /// Specifically whitelist an OpenSea proxy registry address.
    address public proxyRegistryAddress;
    address public framerAddress;

    event UpdateSupply(Record record);

    constructor(
        uint256 _price, 
        string memory name, 
        string memory symbol, 
        string memory baseTokenURI,
        string memory _baseFramedURI,
        uint256 _maxMultiple, 
        uint256 _available,
        bool _saleEnabled,
        string memory record,
        address _openseaProxy,
        address _framerAddress 
    ) ERC721Extended(
        _price, name, symbol, baseTokenURI, _maxMultiple, _available, _saleEnabled
    ) {
      //  1. initialize provenance records array
      Record memory rec = Record(record, 0);
      records.push(rec);

      //2. Set base framed URI
      baseFramedURI = _baseFramedURI;

      // set whitelist operators
      proxyRegistryAddress = _openseaProxy;
      framerAddress = _framerAddress;

      emit UpdateSupply(rec);
    }

    /**
        * @dev Updates supply with additional availability and new provenance record
        * Must be called when paused and match the current  supply offset 
        
        @param supplyOffset the current supply, this persists the provenance record and must match the current totalSupply()
        @param newAvailability the new total availability
        @param record the new provenance record for new tokens past the current totalSupply()

     */
    function updateSupply(uint256 supplyOffset, uint256 newAvailability, string calldata record) external onlyOwner {
      // must be paused while updating
      require(_tokenIdTracker.current() == supplyOffset, "Wrong update offset");
      require(newAvailability > available, "Cannot decrease availability");

      Record memory rec = Record(record, supplyOffset);

      // insert latest record
      records.push(rec);

      // update availability
      available = newAvailability;

      emit UpdateSupply(rec);
    }


    /**
        * @dev Get the latest provenance record
        * The latest record is the currently active for newly minted tokens

        @return record latest provenance record as a Record struct
     */
    function lastRecord() public view returns (Record memory record) {
      if(records.length > 0) 
        record = records[records.length - 1];
    }

    /**
      An override to whitelist the Framer and OpenSea proxy contract to enable gas-free
      listings. This function returns true if `_operator` is approved to transfer
      items owned by `_owner`.
      @param _owner The owner of items to check for transfer ability.
      @param _operator The potential transferrer of `_owner`'s items.
    */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
      // whitelist framer contract
      if(_operator == framerAddress) {
        return true;
      }

      if(super.isApprovedForAll(_owner, _operator)) {
        return true;
      }
        
      // whitelist opensea contract
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(_owner)) == _operator) {
        return true;
      }

      return false;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IFrameMetadata).interfaceId || super.supportsInterface(interfaceId);
    }


    function framedURI(uint256 tokenId) public view virtual override returns (string memory) {
      return bytes(baseFramedURI).length > 0 ? string(abi.encodePacked(baseFramedURI, tokenId.toString())) : "";
    }

    /** 
        * @dev Get framed token metadata base uri
        * @param newURI new base URI
    */
    function setBaseFramedURI(string memory newURI) public onlyOwner {
        baseFramedURI = newURI;
    }

    /**
      * @dev Update Framer Address
     */
    function setFramerAddress(address framer) public onlyOwner {
      framerAddress = framer;
    }
}