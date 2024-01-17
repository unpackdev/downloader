// SPDX-License-Identifier: UNLICENSED
//
// ╋┛╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┛
// ╋╋┏━┳┓┏┳┓╋╋┏┓╋╋╋┏┓╋╋┏┓┏┓╋╋╋
// ╋╋┃━┫┗╋┫┗┳━┫┗┳━┳┛┃┏━┫┗┫┗┓╋╋
// ┳╋┣━┃┏┫┃┏┫━┫┃┃┻┫╋┣┫┻┫┏┫┃┃╋┳
// ╋╋┗━┻━┻┻━┻━┻┻┻━┻━┻┻━┻━┻┻┛╋╋
// ╋┛╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┛
//
// stitched.eth smart contract by ryan meyers
//
// the world will be saved by beauty
//

pragma solidity ^0.8.17;

import "ERC721.sol";
import "DateTime.sol";
import "Ownable.sol";
import "ERC2981.sol";
import "Base64.sol";
import "Strings.sol";
import "BytesToString.sol";


/*
v2 Changes:

[X] IPFS -> CID 
[X] IPFS Gateway for description links
[X] 0-index fix for series list
Burn method
[X] Artist slug
[X] Series slug
*/

contract StitchedETHv2 is ERC2981, ERC721, Ownable {

  error NotAllowed();
  error BadTiming();
  error BadMintKey();
  error IncompleteDetails();
  error NoRemainingAllocations();
  error DoesNotExist();

  event SubjectWorkSeriesCreated(address created_by, uint seriesId);
  event ItemProduced(address licensee, uint subjectWork, uint item);

  struct SubjectWorkSeriesDetails {
    bytes32 creatorName;
    bytes32 workTitle;
    bytes32 creatorSlug;
    bytes32 seriesSlug;
    string copyrightAssignmentIPFS;
    string originalArtFileIPFS;
    uint yearlyAllocation;
  }

  struct SubjectWorkSeries {
    SubjectWorkSeriesDetails details;
    bytes32 status;
    uint[] subjectWorks;
  }

  struct SubjectWorkDetails {
    bytes32 title;
    string subjectWorkArtFileIPFS;
    string copyrightLicenseAgreementIPFS;
  }

  struct SubjectWork {
    SubjectWorkDetails details;
    uint mintDate;
    uint mintYear;
    uint[] items;
  }

  struct SubjectWorkVerbose {
    SubjectWork subjectWork;
    SubjectWorkSeriesDetails subjectWorkSeries;
    uint seriesId;
    uint totalAllocations;
    uint numberProduced;
    uint currentAllocations;
    address currentPossessor;
    Item[] items;
  }

  /*
  struct ItemDetails {
    bytes32 licenseeName;
    string photographicDepictionIPFS;
    bytes32 descriptiveAttributes;
    uint productionDate;
  }

  struct Item {
    ItemDetails details;
    address licensee;
    uint reportedDate;
  }
  */

  struct ItemDetails {
    uint16 chain;
    bytes32 txHash;
    uint productionDate;
  }

  struct Item {
    ItemDetails details;
    address licensee;
    uint reportedDate;
  }

  mapping(uint256 => SubjectWorkSeries) private _subjectWorkSeries;
  mapping(uint256 => SubjectWork) private _subjectWorks;
  mapping(uint256 => Item) private _items;
  mapping(uint16 => bytes8) private _chains;

  uint _nextSubjectWorkSeriesId = 1;
  uint _nextSubjectWorkId = 1;
  uint _nextItemId = 1;
  uint16 _nextChainId = 1;

  string public IPFS_GATEWAY = "https://nftstorage.link/ipfs/";

  constructor(
      string memory name,
      string memory symbol,
      address receiver
    )
     ERC721(name, symbol)
    {
      _setDefaultRoyalty(receiver, 0);
      addChain(bytes8('ethereum'));
      addChain(bytes8('stacks'));
    }
  
  /// @notice Creates a new series
  /// @param details (creatorAddress, creatorName, title, copyrightIPFS, artFileIPFS, yearlyAllocation)
  function newSubjectWorkSeries(SubjectWorkSeriesDetails calldata details) public onlyOwner {
    if(bytes(details.copyrightAssignmentIPFS).length == 0) revert IncompleteDetails();
    if(bytes(details.originalArtFileIPFS).length == 0) revert IncompleteDetails();
    if(details.creatorName == "") revert IncompleteDetails();
    if(details.workTitle == "") revert IncompleteDetails();
    if(details.yearlyAllocation == 0) revert IncompleteDetails();

    _subjectWorkSeries[_nextSubjectWorkSeriesId].details = details;
    _subjectWorkSeries[_nextSubjectWorkSeriesId].status = "ACTIVE";
    
    emit SubjectWorkSeriesCreated(msg.sender, _nextSubjectWorkSeriesId);
    _nextSubjectWorkSeriesId += 1;
  }

  /// @notice mints a subject work (needs series ID)
  /// @param seriesId use {listSubjectWorkSeries} to find
  /// @param details (title, artFileIPFS, licenseIPFS)
  function mintSubjectWork(uint seriesId, SubjectWorkDetails calldata details) public onlyOwner {
    mintSubjectWorkTo(seriesId, details, msg.sender);
  }

  /// @notice mints a subject work (needs series ID)
  /// @param seriesId use {listSubjectWorkSeries} to find
  /// @param details (title, artFileIPFS, licenseIPFS)
  /// @param recipient who should the subject work be minted directly to
  function mintSubjectWorkTo(uint seriesId, SubjectWorkDetails calldata details, address recipient) public onlyOwner {
    if(seriesId >= _nextSubjectWorkSeriesId) revert DoesNotExist();
    if(bytes(details.copyrightLicenseAgreementIPFS).length == 0) revert IncompleteDetails();
    if(bytes(details.subjectWorkArtFileIPFS).length == 0) revert IncompleteDetails();
    if(details.title == "") revert IncompleteDetails();
    
    // uint subjectWorkId = _subjectWorkSeries[seriesId].subjectWorks.length;
    
    uint tokenId = calculateTokenId(seriesId, _subjectWorkSeries[seriesId].subjectWorks.length);
    
    SubjectWork memory sw;
    sw.details = details;
    sw.mintDate = block.timestamp;
    sw.mintYear = DateTime.getYear(block.timestamp);

    _subjectWorks[_nextSubjectWorkId] = sw;

    _subjectWorkSeries[seriesId].subjectWorks.push(_nextSubjectWorkId);
    _nextSubjectWorkId += 1;
    
    _safeMint(recipient, tokenId);
  }

  /// @notice reports use of a license
  /// @param tokenId NFT Token ID
  /// @param details (licenseeName, photoIPFS, description, timestamp)
  function reportItemProductionDetails(uint tokenId, ItemDetails calldata details) public {
    if(_msgSender() != ownerOf(tokenId)){
      if(_msgSender() != owner()){
        revert NotAllowed();
      }
    }
    
    uint subjectWorkSeriesId;
    uint subjectWorkId;

    (subjectWorkSeriesId, subjectWorkId) = decalculateTokenId(tokenId);

    if(currentAllocation(subjectWorkSeriesId, subjectWorkId) < 1) revert NoRemainingAllocations();

    Item memory item = Item(details, ownerOf(tokenId), block.timestamp);
    _items[_nextItemId] = item;
    _subjectWorks[_subjectWorkSeries[subjectWorkSeriesId].subjectWorks[subjectWorkId]].items.push(_nextItemId);
    _nextItemId += 1;

  }

  /// @notice reports multiple identical uses of a license
  /// @param tokenId NFT Token ID
  /// @param details (licenseeName, photoIPFS, description, timestamp)
  /// @param howMany number of licenses used
  function reportItemProductionDetailsBulk(uint tokenId, ItemDetails calldata details, uint howMany) public {
    if(_msgSender() != ownerOf(tokenId)){
      if(_msgSender() != owner()){
        revert NotAllowed();
      }
    }
    
    uint subjectWorkSeriesId;
    uint subjectWorkId;

    (subjectWorkSeriesId, subjectWorkId) = decalculateTokenId(tokenId);

    if(currentAllocation(subjectWorkSeriesId, subjectWorkId) < howMany) revert NoRemainingAllocations();

    Item memory item = Item(details, ownerOf(tokenId), block.timestamp);
    _items[_nextItemId] = item;

    for(uint i = 0; i < howMany; ++i) {
      _subjectWorks[_subjectWorkSeries[subjectWorkSeriesId].subjectWorks[subjectWorkId]].items.push(_nextItemId);
    }
    _nextItemId += 1;
  }
   

  function calculateTokenId(uint subjectWorkSeriesId, uint subjectWorkId) public pure returns (uint){
    return (subjectWorkSeriesId << 16) + subjectWorkId;
  }

  function decalculateTokenId(uint tokenId) public pure returns (uint, uint){
    return (tokenId >> 16, tokenId % 2 ** 16);
  }

  function allocationYears(uint startYear) public view returns (uint){
    return DateTime.getYear(block.timestamp) - startYear + 1;
  }

  function currentAllocationForTokenId(uint tokenId) public view returns (uint) {
    uint subjectWorkSeriesId;
    uint subjectWorkId;

    (subjectWorkSeriesId, subjectWorkId) = decalculateTokenId(tokenId);

    return currentAllocation(subjectWorkSeriesId, subjectWorkId);
  }

  function currentAllocation(uint seriesId, uint subjectWorkId) public view returns (uint) {
    return totalAllocation(seriesId, subjectWorkId) - numberProduced(seriesId, subjectWorkId);
  }

  function totalAllocation(uint seriesId, uint subjectWorkId) public view returns (uint) {
    return _subjectWorkSeries[seriesId].details.yearlyAllocation * allocationYears(_subjectWorks[_subjectWorkSeries[seriesId].subjectWorks[subjectWorkId]].mintYear);
  }

  function numberProduced(uint seriesId, uint subjectWorkId) public view returns (uint) {
    return _subjectWorks[_subjectWorkSeries[seriesId].subjectWorks[subjectWorkId]].items.length;
  }

  function setRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }


  function tokenInformation(uint256 tokenId) public view returns (SubjectWorkVerbose memory) {
    uint seriesId;
    uint subjectWorkId;

    (seriesId, subjectWorkId) = decalculateTokenId(tokenId);

    Item[] memory items = new Item[](_subjectWorks[_subjectWorkSeries[seriesId].subjectWorks[subjectWorkId]].items.length);

    for(uint256 i = 0; i < items.length; ++i){
      items[i] = _items[_subjectWorks[_subjectWorkSeries[seriesId].subjectWorks[subjectWorkId]].items[i]];
    }
    
    return SubjectWorkVerbose(
      _subjectWorks[_subjectWorkSeries[seriesId].subjectWorks[subjectWorkId]],
      _subjectWorkSeries[seriesId].details,
      seriesId,
      totalAllocation(seriesId, subjectWorkId),
      numberProduced(seriesId, subjectWorkId),
      currentAllocation(seriesId, subjectWorkId),
      ownerOf(tokenId),
      items
    );
  }

  function listSubjectWorkSeriesVerbose() public view returns (SubjectWorkSeries[] memory) {
    SubjectWorkSeries[] memory sws = new SubjectWorkSeries[](_nextSubjectWorkSeriesId - 1);
    for(uint256 i = 0; i < sws.length; ++i){
      sws[i] = _subjectWorkSeries[i+1];
    }
    return sws;
  }

  function listSubjectWorkSeries() public view returns (string[] memory) {
    string[] memory sws = new string[](_nextSubjectWorkSeriesId - 1);
    for(uint256 i = 0; i < sws.length; ++i){
      // sws[i] = string(abi.encodePacked(Strings.toString(i+1), ': ', _subjectWorkSeries[i+1].details.creatorName, ': ', _subjectWorkSeries[i+1].details.workTitle));
      sws[i] = string.concat(Strings.toString(i+1), ': ', BytesToString.convert32(_subjectWorkSeries[i+1].details.creatorName), ': ', BytesToString.convert32(_subjectWorkSeries[i+1].details.workTitle));
    }
    return sws;
  }

  function itemInformation(uint256 item) public view returns (Item memory) {
    return _items[item];
  }

  function subjectWorkInformation(uint256 sw) public view returns (SubjectWork memory) {
    return _subjectWorks[sw];
  }

  function itemsInformation(uint256[] calldata itemIds) public view returns (Item[] memory) {
    Item[] memory items = new Item[](itemIds.length);
    for(uint256 i = 0; i < itemIds.length; ++i){
      items[i] = _items[itemIds[i]];
    }
    return items;
  }

  function setIPFSGateway(string memory gateway) public onlyOwner {
    IPFS_GATEWAY = gateway;
  }

  function addChain(bytes8 chain) public onlyOwner {
    _chains[_nextChainId] = chain;
    _nextChainId += 1;
  }

  function listChains() external view returns(string[] memory) {
    string[] memory chs = new string[](_nextChainId - 1);
    for(uint16 i = 0; i < chs.length; ++i){
      chs[i] = string.concat(
        Strings.toString(i+1),
        ": ",
        BytesToString.convert8(_chains[i+1])
      );
    }
    return chs;
  }

  function b2s(bytes32 b) external pure returns(string memory) {
    return BytesToString.convert32(b);
  }

  function setSubjectWorkSeriesStatus(uint series, bytes32 status) public onlyOwner {
    _subjectWorkSeries[series].status = status;
  }

  // https://xp.flowergirlsnft.com/store/
  function SEED_PUZZLE_HINT() public pure returns (string memory) {
    return "0:00 disintegration";
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
      if (!_exists(tokenId)) revert DoesNotExist();
      
      uint seriesId;
      uint subjectWorkId;

      (seriesId, subjectWorkId) = decalculateTokenId(tokenId);

      SubjectWorkSeries storage sws = _subjectWorkSeries[seriesId];
      SubjectWork storage sw = _subjectWorks[sws.subjectWorks[subjectWorkId]];

      // SubjectWorkVerbose memory subjectWork = subjectWorkInformation(tokenId);
      
      // string memory json = "";

      string memory description = string.concat(
        string.concat(
            "The ", 
            BytesToString.convert32(sws.details.workTitle),
            ' by [',
            BytesToString.convert32(sws.details.creatorName),
            "](https://stitched.eth.limo/",
            BytesToString.convert32(sws.details.creatorSlug),
            ") series contains ",
            Strings.toString(sws.subjectWorks.length),
            " works, including the original work assigned to stitched.eth in the [Copyright Assignment](",
            IPFS_GATEWAY,
            sws.details.copyrightAssignmentIPFS,
            ") and the complete set of authorized derivative works. The owner of each of the NFTs in this series is granted a limited exclusive copyright license to produce clothing featuring this artwork, subject to the [Non-fungible Token Agreement](",
            IPFS_GATEWAY,
            sw.details.copyrightLicenseAgreementIPFS,
            "), which limits the amount of clothing that may be produced at any given time. REVIEW THIS LICENSE CAREFULLY prior to acquiring the NFT.\\n\\n The use of the copyright embedded in this NFT is subject to other important limitations, terms, and conditions of this [Non-fungible Token Agreement]("
          ),
          string.concat(
            IPFS_GATEWAY,
            sw.details.copyrightLicenseAgreementIPFS,
            "). Acquiring or minting this NFT or attempting to invoke any of the rights granted by the exclusive license contained in the metadata constitutes the NFT owner's electronic signature and consent to this agreement.\\n\\n The total number of fashion articles authorized by the license agreement increases each year by the Yearly Allocation number and is reflected by the Total Allocation attribute. The NFT holder must report the number of garments produced as they are manufactured, and the Number Produced attribute increases accordingly. The Current Allocation is the difference between the Total Allocation and the Number Produced, which reflects the remaining number of garments that the current NFT holder may produce at any given time. \\n\\n Prior to purchasing the NFT, review all information about the production history, including records you can use for garment authentication on the [Subject Work Page](https://stitched.eth.limo/",
            BytesToString.convert32(sws.details.seriesSlug),
            '#',
            Strings.toString(subjectWorkId+1),
            ") and learn more about the whole series on the [Series Page](https://stitched.eth.limo/",
            BytesToString.convert32(sws.details.seriesSlug),
            ")."
          )
      );


      string memory json = string.concat(
        string.concat(
          '{"name": "',
          BytesToString.convert32(sw.details.title),
          ' (',
          BytesToString.convert32(sws.details.workTitle),
          ' by ',
          BytesToString.convert32(sws.details.creatorName),
          ' #',
          Strings.toString(subjectWorkId+1),
          ')", "external_url": "https://stitched.eth.limo/',
          BytesToString.convert32(sws.details.seriesSlug),
          '#',
          Strings.toString(subjectWorkId+1),
          '", "description": "',
          description,
          '", "image":"ipfs://',
          sw.details.subjectWorkArtFileIPFS
        ),
        string.concat(
          '", "attributes": [{"trait_type": "Creator Name", "value": "',
          BytesToString.convert32(sws.details.creatorName),
          '"}, {"trait_type": "Series", "value": "',
          BytesToString.convert32(sws.details.workTitle),
          ' by ',
          BytesToString.convert32(sws.details.creatorName),
          '"}, {"trait_type": "Creator Status", "value": "',
          BytesToString.convert32(sws.status),
          '"}, {"trait_type": "Yearly Allocation", "value": "',
          Strings.toString(sws.details.yearlyAllocation)
        ),
        string.concat(
          '"}, {"trait_type": "Number Produced", "value": "',
          Strings.toString(numberProduced(seriesId, subjectWorkId)),
          '"}, {"trait_type": "Current Allocation", "value": "',
          Strings.toString(currentAllocation(seriesId, subjectWorkId)),
          '"}, {"trait_type": "Total Allocation", "value": "',
          Strings.toString(totalAllocation(seriesId, subjectWorkId)),
          '"}, { "display_type": "date", "trait_type": "Minted Date", "value": ',
          Strings.toString(sw.mintDate),
          '}]}'
        )
      );

      /*
      string memory json = string(
          abi.encodePacked(
          string(abi.encodePacked(
              '{"name": "',
              sw.details.title,
              ' (',
              sws.details.workTitle,
              ' by ',
              sws.details.creatorName,
              ' #',
              Strings.toString(subjectWorkId+1),
              ')", "external_url": "https://stitched.eth.limo/',
              sws.details.seriesSlug,
              '#',
              Strings.toString(subjectWorkId+1),
              '", "description": "The ',
               sws.details.workTitle,
               ' series by ',
              sws.details.creatorName
          )),
          string(abi.encodePacked(    
              ' contains ',
              Strings.toString(sws.subjectWorks.length),
              ' variants of the original work. Each NFT contains a limited exclusive copyright license to that variant only embedded in the contract metadata. Carefully review the license and the corresponding NFT page on stitched.eth before acquiring the NFT. Learn more at stitched.eth.limo. \\n\\n [Exclusive License to NFT Holder](',
              IPFS_GATEWAY,
              sw.details.copyrightLicenseAgreementIPFS,
              ') \\n\\n [Copyright Assignment of Artist](',
              IPFS_GATEWAY,
              sws.details.copyrightAssignmentIPFS,
              ') \\n\\n [Series Page at stitched.eth](https://stitched.eth.limo/',
              sws.details.seriesSlug,
              ') \\n\\n [Creator Page at stitched.eth](https://stitched.eth.limo/',
              sws.details.creatorSlug,
              ')", "image":"ipfs://',
              sw.details.subjectWorkArtFileIPFS
          )),
          string(abi.encodePacked(
              '", "attributes": [{"trait_type": "Artist Name", "value": "',
              sws.details.creatorName,
              '"}, {"trait_type": "Series", "value": "',
              sws.details.workTitle,
              '"}, {"display_type": "number", "trait_type": "Yearly Allocation", "value": ',
              Strings.toString(sws.details.yearlyAllocation),
              '}, {"display_type": "number", "trait_type": "Number Produced", "value": ',
              Strings.toString(numberProduced(seriesId, subjectWorkId)),
              '}, {"display_type": "number", "trait_type": "Current Allocation", "value": ',
              Strings.toString(currentAllocation(seriesId, subjectWorkId)),
              '}, {"display_type": "number", "trait_type": "Total Allocation", "value": ',
              Strings.toString(totalAllocation(seriesId, subjectWorkId)),
              '}, { "display_type": "date", "trait_type": "Minted Date", "value": ',
              Strings.toString(sw.mintDate),
              '}]}'
          )))
      );
      
      
      // string memory jsonBase64Encoded = ;
      return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
      */
      return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
  }

  function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }


  // Override to support royalties via ERC2981
  function supportsInterface(
  bytes4 interfaceId
  ) public view virtual override(ERC721, ERC2981) returns (bool) {
      // Supports the following `interfaceId`s:
      // - IERC165: 0x01ffc9a7
      // - IERC721: 0x80ac58cd
      // - IERC721Metadata: 0x5b5e139f
      // - IERC2981: 0x2a55205a
      return 
          ERC721.supportsInterface(interfaceId) ||
          ERC2981.supportsInterface(interfaceId);
  }

  // just in case anyt eth ever gets sent here
  function withdraw() public payable {
    require(payable(owner()).send(address(this).balance));
  }

}

// if you made it this far, you deserve a good fork.
// go mint one at forkhunger.art and feed someone real food