// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Strings.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   .d8888b.                             888     888       d8888      888b    888 8888888888 88888888888
//  d88P  Y88b                            888     888      d88888      8888b   888 888            888
//  Y88b.                                 888     888     d88P888      88888b  888 888            888
//   "Y888b.    8888b.  888  888  .d88b.  888     888    d88P 888      888Y88b 888 8888888        888
//      "Y88b.     "88b 888  888 d8P  Y8b 888     888   d88P  888      888 Y88b888 888            888
//        "888 .d888888 Y88  88P 88888888 888     888  d88P   888      888  Y88888 888            888
//  Y88b  d88P 888  888  Y8bd8P  Y8b.     Y88b. .d88P d8888888888      888   Y8888 888            888
//   "Y8888P"  "Y888888   Y88P    "Y8888   "Y88888P" d88P     888      888    Y888 888            888
//
//  Support & own a digital piece of Ukraine's heroic resistance to the russian aggression 2022!
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  From the Author:
//
//  I am Ukrainian born in Lviv, and my heart is torn apart and enraged seeing all the havoc russia releases
//  upon my beloved free Ukrainian land. Thus, I decided to make this symbolic generative NFT collection,
//  first in a series to support Ukraine on its path to victory over the russian invasion 2022.
//
//  95% of the mint proceeds are directed to the official ETH donation address by the Government of Ukraine:
//  0x165CD37b4C644C2921454429E7F9358d18A45e14 (https://twitter.com/Ukraine/status/1497594592438497282)
//  Also verified by Vitalik Buterin https://twitter.com/VitalikButerin/status/1497608588822466563
//  Remaining 5% will fund individual causes and approaches to help fight back and rebuild my country!
//
//  This smart contract ensures ETH goes directly to the official donation address. Every wei counts!!!
//
//  More details at https://saveuanft.org
//
//  The contract is based on ERC-721A (optimized for multiple mints) See https://github.com/chiru-labs/ERC721A
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//                             Боже, Бережи Україну!
//
//                                     * * *
//
//                          Слава Україні! Героям Слава!
//
//                                     * * *
//
//                          Слава Нації! Смерть Ворогам!
//
//                                     * * *
//
//                               Герої Не Вмирають!
//
//                                     * * *
//
//                               Все Буде Україна!
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Національний Гімн України
//  National Anthem of Ukraine
//  https://uk.wikipedia.org/wiki/%D0%93%D1%96%D0%BC%D0%BD_%D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D0%B8
//
//  Ще не вмерла України і слава, і воля.
//  Ще нам, браття молодії, усміхнеться доля.
//  Згинуть наші вороженьки, як роса на сонці,
//  Запануєм і ми, браття, у своїй сторонці.
//
//  Приспів:
//
//  Душу й тіло ми положим за нашу свободу,
//  І покажем, що ми, браття, козацького роду.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract SaveUA is ERC721A {
    using Strings for uint256;

    uint public lastTokenId;
    uint256 public constant maxSupply = 5000;
    uint256 public constant price = 0.2 ether;
    address private _owner;
    string private metadataBaseURI;

    // Ukraine's official ETH donation address. See legit proof above ^^^
    address public constant donationRecipient = 0x165CD37b4C644C2921454429E7F9358d18A45e14;

    constructor(string memory baseUri) ERC721A("SaveUA NFT", "UA") {
        _owner = msg.sender;
        metadataBaseURI = baseUri;
    }

    function mint(uint qty) external payable {
        require(lastTokenId + qty <= maxSupply, "Sold out");
        require(msg.value >= qty * price, "Insufficient funds");

        _safeMint(msg.sender, qty);
    }

    function mintFor(uint qty, address addr) external {
        require(_owner == msg.sender, "You cannot do that");
        require(lastTokenId + qty <= maxSupply, "Sold out");

        _safeMint(addr, qty);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(metadataBaseURI, tokenId.toString(), ".json"));
    }

    // Anyone can initiate the withdrawal.
    // This is made to ensure that the donation can always be claimed,
    // independently from the original contract owner.
    // The caller will incur a minor gas fee though
    function withdraw() external {
        require(address(this).balance > 0, "Nothing to withdraw");
        (bool sent,) = donationRecipient.call{value : address(this).balance * 95 / 100}("");
        require(sent, "Could not send the withdrawal");
        (sent,) = _owner.call{value : address(this).balance}("");
        require(sent, "Could not send the withdrawal");
    }

    function setMetadataBaseUri(string memory uri) external {
        require(_owner == msg.sender, "You cannot do that");
        metadataBaseURI = uri;
    }
}