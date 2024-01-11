// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Base64.sol";

contract WagmiGuestbook is ERC721, Ownable {
  struct Sender {
    uint256 firstGmTimestamp;
    uint256 lastGmTimestamp;
    uint256 count;
  }
  struct Gm {
    uint256 timestamp;
    address sender;
  }

  Gm[] public gms;
  uint256 public totalGms;
  uint256 public totalSupply;
  mapping(address => Gm[]) public senderGms;
  mapping(address => Sender) public senders;

  event GmSent(Gm gm, Sender sender);

  constructor() ERC721('wagmi guestbook', 'GM') Ownable() {}

  function gm() external payable {
    require(balanceOf(msg.sender) != 0, 'sender must gmWithMint first');
    require(
      block.timestamp - senders[msg.sender].lastGmTimestamp > 86400,
      'gm can only be sent once per day'
    );
    sendGm();
  }

  function gmWithMint() external payable {
    require(balanceOf(msg.sender) == 0, 'sender has already minted');
    senders[msg.sender].firstGmTimestamp = block.timestamp;
    senders[msg.sender].lastGmTimestamp = block.timestamp;
    sendGm();
    _safeMint(msg.sender, ++totalSupply);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Proof of GM #',
            toString(tokenId),
            '", "description": "Proof of GM sent on the wagmi guestbook", "image": "data:image/svg+xml;base64,',
            Base64.encode(
              bytes(
                '<svg width="512" height="512" viewBox="0 0 512 512" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="512" height="512" fill="black"/><path d="M273.929 287C280.517 287 285.857 281.628 285.857 275V227C285.857 220.373 291.197 215 297.786 215H321.643C328.231 215 333.571 220.373 333.571 227V275C333.571 281.628 338.911 287 345.5 287C352.089 287 357.429 281.628 357.429 275V227C357.429 220.373 362.769 215 369.357 215H393.214C399.803 215 405.143 220.373 405.143 227V275C405.143 281.628 410.483 287 417.071 287C429 287 429 275 429 275V203C429 196.373 423.66 191 417.071 191H273.929C267.34 191 262 196.373 262 203V275C262 281.628 267.34 287 273.929 287Z" fill="white"/><path fill-rule="evenodd" clip-rule="evenodd" d="M83 274.364C83 280.941 88.34 286.273 94.9286 286.273H220.179C223.472 286.273 226.143 288.939 226.143 292.227C226.143 295.516 223.472 298.182 220.179 298.182H94.9286C88.34 298.182 83 303.513 83 310.091C83 316.669 88.34 322 94.9286 322H238.071C244.66 322 250 316.669 250 310.091V202.909C250 196.332 244.66 191 238.071 191H94.9286C88.34 191 83 196.332 83 202.909V274.364ZM118.786 214.818C112.197 214.818 106.857 220.15 106.857 226.727V250.545C106.857 257.123 112.197 262.455 118.786 262.455H214.214C220.803 262.455 226.143 257.123 226.143 250.545V226.727C226.143 220.15 220.803 214.818 214.214 214.818H118.786Z" fill="white"/></svg>'
              )
            ),
            '", "attributes": [{ "trait_type": "count", "value": "',
            toString(senders[ownerOf(tokenId)].count),
            '" }, { "trait_type": "lastGm", "display_type": "date", "value": ',
            toString(senders[ownerOf(tokenId)].lastGmTimestamp),
            ' }, { "trait_type": "firstGm", "display_type": "date", "value": ',
            toString(senders[ownerOf(tokenId)].firstGmTimestamp),
            ' }]}'
          )
        )
      )
    );
    string memory output = string(
      abi.encodePacked('data:application/json;base64,', json)
    );
    return output;
  }

  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function sendGm() internal {
    Gm memory gm_ = Gm({timestamp: block.timestamp, sender: msg.sender});
    gms.push(gm_);
    senderGms[msg.sender].push(gm_);

    unchecked {
      ++senders[msg.sender].count;
      ++totalGms;
    }
    senders[msg.sender].lastGmTimestamp = block.timestamp;

    emit GmSent(gm_, senders[msg.sender]);
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}
