
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vera Conley Fine Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                  {__         {__{________{_______          {_                                                //
//                   {__       {__ {__      {__    {__       {_ __                                              //
//                    {__     {__  {__      {__    {__      {_  {__                                             //
//                     {__   {__   {______  {_ {__         {__   {__                                            //
//                      {__ {__    {__      {__  {__      {______ {__                                           //
//                        {___     {__      {__    {__   {__       {__                                          //
//                        {__      {________{__      {__{__         {__                                         //
//                                                                                                              //
//                                                                                                              //
//           .,ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZI.                               //
//           ..ZOZOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOZOZO..                               //
//           .,++..........................................................++++                                 //
//           ..OO.                                                       .,OOOO                                 //
//           .IOZ.                                                       .ZZZZZ                                 //
//           .,ZO.       .DD           .OD                             ..OZZOOZ                                 //
//           .,ZZ.       .88Z          .Z8                             ..ZZZZZZ                                 //
//           .,OO.        IDDZ        .OD                             ..OOZ..OZ                                 //
//           .,OZ.        .,D8       .OD                             .ZOOO..,ZZ                                 //
//           ..+?.           ??      +??                            .+++?....++                                 //
//           .,OO.         ..ND.    .ON8                          ..,OOO. ..,OO                                 //
//            ?OZ.           ~D8~  .ID8                          .+ZZZZ.. ..7ZZ                                 //
//           .,OO.            .DD  .D8                         ..:ZZOZ.   ..,OO                                 //
//           .,ZZ.            .8O .,DO                        ....ZZZ..   ...ZZ                                 //
//           .,OO.            ..N8OD8                        .,:OOO.      ...OZ                                 //
//           .,OO.             ..DDO                      ..,ZOOZO..      ...OZ                                 //
//           ..+?.               . .                    ..++=+?..         ...++                                 //
//           .,OO.                                     ..+ZOOO...         ..,OO                                 //
//           .?ZZ.                               .I=:?ZZZZZ7?.            ..7ZZ                                 //
//           ..OO.                          .:~ZZOOOOZOO. ..              ..,OO                                 //
//           ..ZZ.                   .......$..$ZZZZZZ...                 ...ZZ                                 //
//           .,OO.                 ..IZ:OOOOOOZ...                        ..,OO                                 //
//           .,OZ.              ..=ZOOOZOO.....                           ..,OZ                                 //
//           ..+?.            ..++++?....                                 ...+?                                 //
//           ..OO.          ...+OOOO..                .   ..    .         ...OO                                 //
//           .IOO.        ..=ZOOZI                   =Z8D8888888Z~        ..7ZZ                                 //
//           ..OO.       .~OOOZ..                 ..8N8Z       ,8Z        ..,OO                                 //
//            .ZZ.      ..,ZZZ.                    .ODO                   ...ZZ                                 //
//           .,OO.     .ZOOO..                    7DD.                    ..,OO                                 //
//           ..ZO.   ..ZOZO.                     .OD.                     ..,ZO                                 //
//           .,+?.  ..++=.                       .+I+                     ...++                                 //
//           ..OO....,OOO.                       .8NO                     ..,OO                                 //
//           .IOZ. .ZOZ7                          I8D                     ..IOZ                                 //
//           .,ZO..ZOZZ                             DDDO       ~O=        ..,ZZ                                 //
//           .,ZZ..ZZZ.                             .88Z$.  .. ,O.        ..,ZZ                                 //
//           .,OOZZOOI                                ..DDDDDD8.          ...OO                                 //
//           .,OZZZZ..                                                    ..,ZZ                                 //
//           ..+++?.                                                      ...++                                 //
//           .,OOOO.........................................................,OO                                 //
//           .IOZZ$?++=+++++++=+++++++=+++++++=+++++++=+++++++=+++++++=+++=+ZOZ                                 //
//           .,OZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ                                 //
//           ..ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$ZZZ$$ZZZ                                 //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VERA is ERC721Creator {
    constructor() ERC721Creator("Vera Conley Fine Art", "VERA") {}
}
