pragma solidity ^0.5.14;

contract OfferStorage {

  mapping(address => bool) public accessAllowed;
  mapping(address => mapping(uint => bool)) public userOfferClaim;
  mapping(uint256 => address[]) public claimedUsers;

  constructor() public {
    accessAllowed[msg.sender] = true;
  }

  modifier platform() {
    require(accessAllowed[msg.sender] == true);
    _;
  }

  function allowAccess(address _address) platform public {
    accessAllowed[_address] = true;
  }

  function denyAccess(address _address) platform public {
    accessAllowed[_address] = false;
  }

  function setUserClaim(address _address, uint offerId, bool status) platform public returns(bool) {
    userOfferClaim[_address][offerId] = status;
    if (status) {
      claimedUsers[offerId].push(_address);
    }
    return true;
  }

  function getClaimedUsersLength(uint _offerId) platform public view returns(uint256){
      return claimedUsers[_offerId].length;
  }

}