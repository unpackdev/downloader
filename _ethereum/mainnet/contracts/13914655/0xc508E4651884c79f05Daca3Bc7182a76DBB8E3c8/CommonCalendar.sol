// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./DateTime.sol";

contract CommonCalendar is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;

    using SafeMath for uint256;
    
    address public steward;
    address public auction;
    address dateLibrary;
    mapping (uint8 => mapping (uint8 => bool)) internal mintedDates; // month -> day -> was minted bool
    mapping (uint8 => mapping (uint8 => string)) internal dayNames;  // User set names
    mapping (uint8 => mapping (uint8 => uint256)) internal daySellPrices;  // User set forced sale prices
    mapping (uint8 => mapping (uint8 => bool)) internal auctionedDates; // month -> day -> was minted bool
    mapping (uint8 => mapping (uint8 => bool)) internal foreCloseDates; // month -> day -> was minted bool

    event AuctionAdded(uint8 month, uint8 day);

  function setSteward(address _steward) public {
    require(steward == address(0)); // ensure steward is null at first and only can be set once
    steward = _steward;
  }
  
  // Day Name methods 
  function setDayName(uint8 _monthNumber, uint8 _dayOfMonth, string memory newName) public {
      require(bytes(newName).length <= 36, "Day name must be less than 36 chars"); // Move to DAO
      dayNames[_monthNumber][_dayOfMonth] = newName;
  }

  function getDayName(uint8 _monthNumber, uint8 _dayOfMonth) public view returns (string memory) {
      return dayNames[_monthNumber][_dayOfMonth];
  }
  function getTodayName() public view returns (string memory) {
    DateTime datetimelib = DateTime(dateLibrary);
    uint8 monthNumber = datetimelib.getMonth(block.timestamp);
    uint8 dayOfMonth = datetimelib.getDay(block.timestamp);
    return dayNames[monthNumber][dayOfMonth];
  }

  function getMintedDay(uint8 _monthNumber, uint8 _dayOfMonth) public view returns(bool) {
    return mintedDates[_monthNumber][_dayOfMonth];
  }

  modifier onlyMintOnDay(uint8 _monthNumber, uint8 _dayOfMonth) {
    DateTime datetimelib = DateTime(dateLibrary);
    uint8 monthNumber = datetimelib.getMonth(block.timestamp);
    uint8 dayOfMonth = datetimelib.getDay(block.timestamp);
    require(monthNumber >= _monthNumber, 'Cannot mint this NFT this month');
    require(dayOfMonth >= _dayOfMonth, 'Cannot mint NFT on this day');
    _;
  }

    modifier notToday(uint8 _monthNumber, uint8 _dayOfMonth) {
        DateTime datetimelib = DateTime(dateLibrary);
        uint8 monthNumber = datetimelib.getMonth(block.timestamp);
        uint8 dayOfMonth = datetimelib.getDay(block.timestamp);
        bool isToday = monthNumber == _monthNumber && dayOfMonth == _dayOfMonth;
        require(!isToday, 'Cannot change name on the day itself');
        _;
    }

  modifier notAlreadyMinted(uint8 _monthNumber, uint8 _dayOfMonth) {
    require(mintedDates[_monthNumber][_dayOfMonth] == false, "This NFT was already minted");
    _;
  }

  modifier onlyValidInputs(uint8 _monthNumber, uint8 _dayOfMonth) {
    require(_monthNumber < 13 && _monthNumber > 0, "Month out of range");
    require(_dayOfMonth < 32 && _dayOfMonth > 0, "Day out of range");
    _;
  }

  modifier notAlreadyAuctioned(uint8 _monthNumber, uint8 _dayOfMonth, bool status) {
    if(!status) {
      require(auctionedDates[_monthNumber][_dayOfMonth] == false, "This NFT was already auctioned");
    }
    _;
  }


  function calculateTokenID(uint8 month, uint8 dayOfMonth) public returns (uint256 tokenID) {
    return uint256(month).mul(100).add(dayOfMonth);
  }

  //onlyMintOnDay(month, dayOfMonth)
  function mintItem(address to, uint8 month, uint8 dayOfMonth)
      public
      notAlreadyMinted(month, dayOfMonth)
      onlyValidInputs(month, dayOfMonth)
      returns (uint256)
  {
      uint256 tokenID = calculateTokenID(month, dayOfMonth);
      _mint(to, tokenID);
      _setTokenURI(tokenID, string(abi.encodePacked(uint2str(month), "/", uint2str(dayOfMonth))));
      mintedDates[month][dayOfMonth] = true;

      return tokenID;
  }


  // function foreClosedDay(uint8 month, uint8 day) public {
  //   foreCloseDates[month][day] = true;
  // } 

    // Override methods

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://days.calendar.org/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        return;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override(ERC721)
        returns (bool)
    {
        return (spender == steward);
        /*
          // NOTE: temporarily disabling sending of the tokens independently. A protective messure since it isn't clear to users how this function should work.
          //       Will re-add once a mechanism is agreed on by the community.
          || ERC721._isApprovedOrOwner(spender, tokenId)
          */
    }


    constructor(address _dateLibrary) ERC721("CommonCalendar", "CC")  {
        dateLibrary = _dateLibrary;
      }

       function uint2str(
  uint256 _i
)
  internal
  pure
  returns (string memory str)
{
  if (_i == 0)
  {
    return "0";
  }
  uint256 j = _i;
  uint256 length;
  while (j != 0)
  {
    length++;
    j /= 10;
  }
  bytes memory bstr = new bytes(length);
  uint256 k = length;
  j = _i;
  while (j != 0)
  {
    bstr[--k] = bytes1(uint8(48 + j % 10));
    j /= 10;
  }
  str = string(bstr);
}

}






