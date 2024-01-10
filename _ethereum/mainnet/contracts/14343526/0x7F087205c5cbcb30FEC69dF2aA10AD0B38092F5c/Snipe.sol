// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./NFTEnumerable.sol";
import "./Strings.sol";

//                           *((/.
//                     .#&%(*,(@%.                          .*/,
//                 *&&/*****%&.                              /%***,/%
//              (&(,******%&.                                  &/****,/%
//          ,&#*,******,/@,                                      %*,**,,,(
//         /%********,,*@*                                        %**,,*,,,#
//        %%,*,*,,*,,*,@(                                         (%*,,,,,,,,,
//       &(,,,**,,,,,,,@/                                         /&,,,,,,,,,,(
//      &#*,,,,*,,,,,,,#%                                         @(,,,,,,,,,,/
//     (@//(/,,*,,,,,,,.%&               *&##&(                  @(,,,,,,,,,*@@@
//      @@#/,***,,,,,,,,.,&         /#%(.  @##&%    *##(       *&*,,*******,*(/&
//      #&(//**,*****,,,,...#    ,@#%%%%%#&@&%%@.@%&%@&       @,,,*********%@@%@.
//       @&/@%/******,**,*,..,%,     /&%%%%%&&&&&&%&@&&%,  *&/,,*********/((((%@
//        /@(((/(/%/*****,,,*,.(@&%%%%&%&&@@@@@@@@@@&&@%#%&**,,,*****//(#@&//#@
//          @(/(@&//*********,&&##%%#%%%&@@@@@@@@@@&&&&@@&@&*,,,,,////////(#@@
//           *@@((((((#&&*****@##&@/@@&&@@@@@@@@&&@@@&&&@%/@/**////(/%@%(/%@.
//             /@(///&&///((//(@@%/@&@@@&@@@@@@@@@@@@@@@@/*///(((/(((//(@@.
//                @#@#/((((%@#/((//@@#&@@&@@@#*(@&&@@%@@@%/((((((#&&(#@@
//                  /&(*(@@%@(/(/((/#%#@@@@@@/#&@@&#///(((@%/((//((&@
//                   .@&//(@@*(@%(((((((%@@@@%((((((//(@@@(//&@&@*
//               /@#///(@@@/*%%..#@*(/(/(&#/(/////&@#./%//@#///*#/
//           (&%////%@( /@///@,....#@#/(%@(//((@&* ....@(//@%#@(////(@,
//        @%*/#@@(     (@////@(....*(%@&&&/(@@(*.    ,@(///#@,     /&@@%/@&
//     /@@&/.          @%/////%#....,*./@@@@.*,.....%@//////@(            /@
//     #              .@&////%(///(#@@@##(##(&@@%//(#@%/////@/            /#
//       .#/....  .*    @(////(%&@@@@########(#&&/(///(//(/@% #/       ,&#
//                        @%@#///#@#########(###%@%/(@(//%@      .,.
//                          @///&@##(#####(######(@&/(@#
//                         .%//@@(((((#####((#((((#@%//#@.
//                         &/*&@&@@@@&%##(//(#%&@@@@@#/(//%@.
//                       ,@//&@/,,,,,,,,,,,,,***,,*,,%@/((//#@
//                      #@/*#@*#@@@%*,,,#%*,*(@@@@/*&@(((((/(#@
//                     &@////(@%**(@@#*,%%**(@@@@@@@(//((((((#&
//                    &&*//////*//(@@@@#%%/%@@@@%(((((((((((#@
//                   ,@///////////(////(#%%(///(((((/(/((/(@*
//                   #@//////////////////((/////###((/#@@&
//                    @&*///////////////&@@/. .%   /@/&
//                     (@#//(//((///(&@*  #.   % *@#/(&
//                        @@@#(/(#@&, *,  */ ,@@%*//@*
//                         /#**/*.   /#(##((**/**(@
//                           @***.   ,/*//***/%@
//                             @(        ,@,
//                             #&.  #,,& (#
//                             *&.  @  @.@
//                             .&.  @   ,
//                             .&. ,&
//                              &. .&
//                             .%  .%
//                             ,(  ,#
//                             **  **
//                             %,  %
//                             %.  @
//                              #/#
//
//     DRP + Pellar 2022
//     Snipe1

contract DRPToken is NFTEnumerable {
  using Strings for uint256;

  constructor() NFTEnumerable() {}

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Non exists token");
    if (!isBlank(defaultURI)) {
      return string(abi.encodePacked(defaultURI, _tokenId.toString()));
    }
    return baseURI;
  }

  function claim(uint8 _tokenId, bytes calldata _signature) external payable {
    require(tx.origin == msg.sender, "Not allowed"); // no contract
    require(saleActive, "Not active"); // sale active
    require(eligibleClaim(_tokenId, msg.sender, _signature), "Not eligible"); // eligible to claim
    require(msg.value >= 0.05 ether, "Insufficient ether");
    _mint(msg.sender, _tokenId);
  }

  function eligibleClaim(uint8 _tokenId, address _account, bytes memory _signature) public view returns (bool) {
    bytes32 message = keccak256(abi.encodePacked(hashKey, _tokenId, _account));
    return validSignature(message, _signature);
  }

  function teamClaim() external onlyOwner {
    uint8 start = 100 - 10;
    for (uint8 i = start; i < 100; i++) {
      _mint(msg.sender, i);
    }
  }
}
