//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

interface IDawnChorus {

  enum RequestStatus {
    NONE,       // 0
    PENDING,    // 1
    OK          // 2
  }

  enum RequestType {
    NONE,       // 0
    SALE,       // 1
    TRANSFER    // 2
  }

  event TransferRequest(
    uint256 tokenId,
    address to,
    RequestType requestType
  );

  event TransferRequestCancellation(
    uint256 tokenId,
    address to,
    RequestType requestType
  );

  event TransferApproval(
    uint256 tokenId,
    address to,
    RequestType requestType
  );

  event Purchase(
    uint256 indexed tokenId,
    address indexed from,
    address indexed to,
    uint256 price
  );

  event ExhibitionRequest(
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime,
    string occasion,
    string institution,
    string location,
    string uri
  );

  event ExhibitionRequestCancellation(
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime,
    string uri
  );

  event ExhibitionApproval(
    address indexed owner,
    uint256 indexed tokenId,
    uint256 indexed startTime
  );

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
}
