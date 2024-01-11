// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Owned.sol";
import "./Strings.sol";
import "./AccessControl.sol";

//                               8DDDDDDDDDDDDDDDDDD
//                          8DDDDDDDDDDDDDDDDDDDDDDDDDDDD.
//                       DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
//                    NDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDN
//                 .8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDN
//               .DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD.
//             .   DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
//            ,DDDZ    :DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD.  .DD?
//           DDDDDDDDDD,     ONDDDDDDDDDDDDDDDDDDDDDDDDDDDDDZ    DDDDDDD
//          DDDDDDDDDDDDDDDD8,.      ?8DDDDDDDDDDDDDDO~ .   .NDDDDDDDDDDD.
//         DDDDDDDDDDDDDDDDDDDDDDDDDD+,.             :$NDDDDDDDDDDDDDDDDDD.
//        DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
//      .DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD.
//      NDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
//     =DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDI
//     DDDDDDDDDDDDDDDDD+ .  NDDDDDDDDDDDDDDDDDDDDDDDD$$$$$DDDDDDDDDDDDDDDDDDD.
//    DDDDDDDDDDDDDDN          .NDDDDDDDDDDDDDDDDDDDD.     DDDD????INDDDDDDDDDD
//    DDDDDDDDDDDDD.             NDDDDDDDDDDDDDDDDDDD.     DDD.     DDDDDDDDDDD
//   IDDDDDDDDDDDD:      .        DDDDDDDDDDDDDDDDDDD      DDD.    .DDDDDDDDDDDO
//   DDDDDDDDDDDDD     .DDDD      DD.....,DD8.....~D7      N...     ..=DDDDDDDDD
//   DDDDDDDDDDDD7      DDDD.  ..~D7      DD.     ,D,      D          +DDDDDDDDD.
//  .DDDDDDDDDDDD      ~DDDDDDDDDDD      ~DD      DD      DZ          DDDDDDDDDD,
//  =DDDDDDDDDDDD.     8DDDDDDDDDDD      DDD      DD      DDD      8DDDDDDDDDDDD?
//  7DDDDDDDDDDDD      DDDDDDDDDDDD      DDD      DD      DDD.     DDDDDDDDDDDDD$
//  IDDDDDDDDDDDD      DDDDDDDDDDDD      DDZ      DO      DDD.     DDDDDDDDDDDDD$
//  ~DDDDDDDDDDD$      DDDD?ZDDDDDD      DD,     .D:     .DDD      DDDDDDDDDDDDD+
//   DDDDDDDDDDD:      DDD:      D      :DD      DD      NDDD      DDDDDDDDDDDDD.
//   DDDDDDDDDDD$      ., .     DD      .,.      N:      ..D:      ..DDDDDDDDDDD.
//   DDDDDDDDDDDD.             ZDD               DD       DD.       ODDDDDDDDDDD
//   IDDDDDDDDDDDD            DDDDD             NDI       DDI       DDDDDDDDDDDZ
//    DDDDDDDDDDDDDD.      IDDDDDDDD           IDDDN      DDDN      DDDDDDDDDDD
//    DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
//     DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD.
//     :DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD?
//      NDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD.
//      .DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD.
//       .NDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
//         DDDDDDDDDDDDDDDDDDDDDDD:.                   .,8DDDDDDDDDDDDDDDD
//          DDDDDDDDDDDDDDD,.    .$DDDDDDDDDDDDDDDDDDDDDO.    =DDDDDDDDDD
//           8DDDDDDD?   . ODDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD~   DDDDDD
//            .DD.    NDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD7  :D:
//              :7DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8
//                8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
//                 .DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD.
//                    DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
//                       DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
//                          ZDDDDDDDDDDDDDDDDDDDDDDDDDDD8
//                               $DDDDDDDDDDDDDDDDDO

contract Cult is ERC721, Owned, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    string baseURI;
    string fileExt;
    string ball;

    uint256 public totalSupply;

    constructor(address premintRecipient)
        ERC721("Cult", "CULT")
        Owned(msg.sender)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < 50; i++) {
            _safeMint(premintRecipient, i);
            totalSupply++;
        }

        require(balanceOf(premintRecipient) == 50, "PREMINT FAILED");
        require(totalSupply == 50, "PREMINT FAILED");
    }

    // INTERNAL
    function _exists(uint256 id) internal view returns (bool) {
        return _ownerOf[id] != address(0);
    }

    // ADMIN
    function setBall(string calldata _ball) external onlyRole(ADMIN_ROLE) {
        ball = _ball;
    }

    function setBaseURI(string calldata _baseURI, string calldata _fileExt)
        public
        onlyRole(ADMIN_ROLE)
    {
        baseURI = _baseURI;
        fileExt = _fileExt;
    }

    // PUBLIC
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "ERC721Metadata: URI query for nonexistent token");

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, Strings.toString(id), fileExt)
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f ||
            interfaceId == type(IAccessControl).interfaceId;
    }

    // EXTERNAL
    function mint(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, totalSupply);
            totalSupply++;
        }
    }

    function fetch() external view returns (string memory) {
        return ball;
    }
}
