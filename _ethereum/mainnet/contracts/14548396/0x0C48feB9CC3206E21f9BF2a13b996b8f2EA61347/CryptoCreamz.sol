// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";



// ____                           __           ____
///\  _`\                        /\ \__       /\  _`\
//\ \ \/\_\  _ __   __  __  _____\ \ ,_\   ___\ \ \/\_\  _ __    __     __      ___ ___   ____
// \ \ \/_/_/\`'__\/\ \/\ \/\ '__`\ \ \/  / __`\ \ \/_/_/\`'__\/'__`\ /'__`\  /' __` __`\/\_ ,`\
//  \ \ \L\ \ \ \/ \ \ \_\ \ \ \L\ \ \ \_/\ \L\ \ \ \L\ \ \ \//\  __//\ \L\.\_/\ \/\ \/\ \/_/  /_
//   \ \____/\ \_\  \/`____ \ \ ,__/\ \__\ \____/\ \____/\ \_\\ \____\ \__/.\_\ \_\ \_\ \_\/\____\
//    \/___/  \/_/   `/___/> \ \ \/  \/__/\/___/  \/___/  \/_/ \/____/\/__/\/_/\/_/\/_/\/_/\/____/
//                      /\___/\ \_\
//                      \/__/  \/_/


//                                                      _     _
//  _ __     ___   __      __   ___   _ __    ___    __| |   | |__    _   _     _ __ ___    ___    __ _   _ __
// | '_ \   / _ \  \ \ /\ / /  / _ \ | '__|  / _ \  / _` |   | '_ \  | | | |   | '_ ` _ \  / __|  / _` | | '_ \
// | |_) | | (_) |  \ V  V /  |  __/ | |    |  __/ | (_| |   | |_) | | |_| |   | | | | | | \__ \ | (_| | | |_) |
// | .__/   \___/    \_/\_/    \___| |_|     \___|  \__,_|   |_.__/   \__, |   |_| |_| |_| |___/  \__, | | .__/
// |_|                                                                |___/                       |___/  |_|
contract CryptoCreamz is Ownable, ERC721A {

    string private _baseTokenURI;
    bool public isMSGPAuthorised = true;
    uint256 public immutable COLLECTION_SIZE = 3333;

    address BROKER_WALLET = 0xaEbA9F5fDcd60B180499Bb16011F2629759200Ea;
    address MARKETING_WALLET = 0x39f81debABb503ddE3520Ad13a7E7eE4ba9e297e;
    address MSGP_COMMUNITY_WALLET = 0x7F74136303A72EC17A079f5742a8136C0F19a21c;
    address MSGP_MINTER_WALLET = 0x9C22CE2DF2d3BED0EB6EEdE5CB36aa15DcC95cA6;
    address PARTNER_WALLET = 0x1852F816671f257E3B43c70A49aC6b6e44A337a4;

    constructor(string memory collectionName, string memory collectionAlias)
        ERC721A(collectionName, collectionAlias, COLLECTION_SIZE) {
    }

    modifier onlyMSGP() {
        require(isMSGPAuthorised, "onlyMSGP: MSGP is not authorised");
        require(MSGP_MINTER_WALLET == _msgSender(), "onlyMSGP: caller is not the MSGP");
        _;
    }

    function bulkMintMap(address[] memory who, uint256[] memory quantityList) public onlyMSGP {
        for (uint256 i = 0; i < who.length; i++) internalMint(who[i], quantityList[i]);
    }

    function internalMint(address to, uint256 quantity) internal virtual {
        require(totalSupply() + quantity <= COLLECTION_SIZE, "reached max supply");
        _safeMint(to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURIOwner(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setBaseURI(string calldata baseURI) external onlyMSGP {
        _baseTokenURI = baseURI;
    }

    function authoriseMSGPToggle() external onlyOwner {
        isMSGPAuthorised = !isMSGPAuthorised;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "NO FUNDS AVAILABLE");

        payable(msg.sender).transfer((balance * 65)/100);
        payable(PARTNER_WALLET).transfer((balance * 25)/100);
        payable(BROKER_WALLET).transfer((balance * 2)/100);
        payable(MARKETING_WALLET).transfer((balance * 2)/100);
        payable(MSGP_COMMUNITY_WALLET).transfer((balance * 3)/100);
        payable(MSGP_MINTER_WALLET).transfer((balance * 3)/100);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external  view  returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    receive () external payable {}
}
