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


contract StitchedETH is ERC2981, ERC721, Ownable {

  error NotAllowed();
  error BadTiming();
  error BadMintKey();
  error IncompleteDetails();
  error NoRemainingAllocations();
  error DoesNotExist();

  event SubjectWorkSeriesCreated(address created_by, uint seriesId);
  event ItemProduced(address licensee, uint subjectWork, uint item);

  struct SubjectWorkSeriesDetails {
    address creatorAddress;
    string creatorName;
    string workTitle;
    string copyrightAssignmentIPFS;
    string originalArtFileIPFS;
    uint yearlyAllocation;
  }

  struct SubjectWorkSeries {
    SubjectWorkSeriesDetails details;
    bool expired;
    uint[] subjectWorks;
  }

  struct SubjectWorkDetails {
    string title;
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

  struct ItemDetails {
    string licenseeName;
    string photographicDepictionIPFS;
    string descriptiveAttributes;
    uint productionDate;
  }

  struct Item {
    ItemDetails details;
    address licensee;
    uint reportedDate;
  }

  struct MetaData {
    string m1;

  }

  mapping(uint256 => SubjectWorkSeries) private _subjectWorkSeries;
  mapping(uint256 => SubjectWork) private _subjectWorks;
  mapping(uint256 => Item) private _items;

  uint _nextSubjectWorkSeriesId = 1;
  uint _nextSubjectWorkId = 1;
  uint _nextItemId = 1;


  constructor(
      string memory name,
      string memory symbol,
      address receiver
    )
     ERC721(name, symbol)
    {
      _setDefaultRoyalty(receiver, 0);
    }
  
  /// @notice Creates a new series
  /// @param details (creatorAddress, creatorName, title, copyrightIPFS, artFileIPFS, yearlyAllocation)
  function newSubjectWorkSeries(SubjectWorkSeriesDetails calldata details) public onlyOwner {
    if(details.creatorAddress == address(0)) revert IncompleteDetails();
    if(bytes(details.copyrightAssignmentIPFS).length == 0) revert IncompleteDetails();
    if(bytes(details.originalArtFileIPFS).length == 0) revert IncompleteDetails();
    if(bytes(details.creatorName).length == 0) revert IncompleteDetails();
    if(bytes(details.workTitle).length == 0) revert IncompleteDetails();
    if(details.yearlyAllocation == 0) revert IncompleteDetails();

    _subjectWorkSeries[_nextSubjectWorkSeriesId].details = details;
    
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
    if(bytes(details.title).length == 0) revert IncompleteDetails();
    
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
  function reportItemProduction(uint tokenId, ItemDetails calldata details) public {
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
  function reportItemProductionBulk(uint tokenId, ItemDetails calldata details, uint howMany) public {
    if(_msgSender() != ownerOf(tokenId)){
      if(_msgSender() != owner()){
        revert NotAllowed();
      }
    }
    
    uint subjectWorkSeriesId;
    uint subjectWorkId;

    (subjectWorkSeriesId, subjectWorkId) = decalculateTokenId(tokenId);

    if(currentAllocation(subjectWorkSeriesId, subjectWorkId) < howMany) revert NoRemainingAllocations();

    for(uint i = 0; i < howMany; ++i) {
      Item memory item = Item(details, ownerOf(tokenId), block.timestamp);
      _items[_nextItemId] = item;
      _subjectWorks[_subjectWorkSeries[subjectWorkSeriesId].subjectWorks[subjectWorkId]].items.push(_nextItemId);
      _nextItemId += 1;
    }
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
      sws[i] = string(abi.encodePacked(Strings.toString(i), ': ', _subjectWorkSeries[i+1].details.creatorName, ': ', _subjectWorkSeries[i+1].details.workTitle));
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

  // https://codebeautify.org/html-decode-string
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
      
      string memory json = string(
          abi.encodePacked(
          string(abi.encodePacked(
              '{"name": "',
              sw.details.title,
              '", "description": "The ',
               sws.details.workTitle,
               ' series by ',
              sws.details.creatorName,
              ' contains ',
              Strings.toString(sws.subjectWorks.length),
              ' variants of the original work. Each NFT contains a limited exclusive copyright license to that variant only embedded in the contract metadata. Carefully review the license and the corresponding NFT page on stitched.eth before acquiring the NFT. Learn more at stitched.eth.limo. \\n\\n [Exclusive License to NFT Holder](',
              sw.details.copyrightLicenseAgreementIPFS,
              ')\\n [Copyright Assignment of Artist](',
              sws.details.copyrightAssignmentIPFS,
              ')\\n [Series Page at stitched.eth](https://stitched.eth.limo/series/',
              Strings.toString(seriesId),
              ')", "image":"',
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