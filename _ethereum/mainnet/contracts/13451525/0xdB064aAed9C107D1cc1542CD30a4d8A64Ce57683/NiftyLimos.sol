// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//@author: Mehrdad, Salehi (@mhrsalehi)
//
//             _   _   _    __   _                 _       _
//            | \ | | (_)  / _| | |               | |     (_)
//            |  \| |  _  | |_  | |_   _   _      | |      _   _ __ ___     ___    ___
//            | . ` | | | |  _| | __| | | | |     | |     | | | '_ ` _ \   / _ \  / __|
//            | |\  | | | | |   | |_  | |_| |     | |____ | | | | | | | | | (_) | \__ \
//            \_| \_/ |_| |_|    \__|  \__, |     \_____/ |_| |_| |_| |_|  \___/  |___/
//                                      __/ |
//                                     |___/
//                                                     `,";^"^^;!;,
//                                              .;\l1SGH9KPSSS- `x5S1+^;_
//                                           ;xPNBWWWWWWWWWWBP  *BWWBBQ99{i*;-
//                                        '(HBWWWWWWWWWWWWBBP'  CBWWWWWWWQPNK9%l!~
//                                      .iRBBWWWWWWWWWWWBBBk`   xBBKyuu5RBSRBWBBRg5{*:
//                        _:^!!!;!^::^>l5$KqqGSSSuCiiivuSkl":`  'uy_`   `GguBWWWWWBBNQE1*,
//                  `^*=x1=*~,.  ::""!\!-        `~~~~~:-`      ^!:;***!!lx!ggNBBWWWWBBBNQP=;`
//                _\*:!: ..._:,_!``^~"_.:::::::` "`         `_:_^i`         r `,^*=xy5KRBBBHN$,
//             ,^Cj:;;"!~::::::y_*!`uNBWWWWWWWBG        ,~~~,"!*\r*""-      >           `,"!xvy*
//           -yNKv  - _  _     z\, *BWWWWWWWWWBq       !, '>+l!:~""~;*!     +~              ;**\!!
//           yqH5  :!^u *!    .uz  *RNRQQNBBRQP\      _  "C_       ,^vl"    ~\               +,j`{
//          '> "!  \`C" l     *y=    `   `..            ~o           .iv_   ->               z\i\H`
//         .i` __  "_o .*    `v!yzvl=i=\!!!!!!  :;,    `e' -CqgP*     `vx    \              ~w:CSA
//        `k:  _       ``    =^     `...          :+,  !=  5BWWWB+     vC    \         .,:;!zC,ix.
//        :5   !^^!^-`:::;;~!:                     `=  z:  iBWWWH:     iC;!*l%sCySPPk2uxl*^,!:~*;
//        .y      ..``::,.                         -l  >    ~\l*`     *vKBNgP%xl*^,`
//         !!                                      >_  \            '(x*;,`
//          :lvz>!~_`                             !, `;^ ^:      -">x*.
//             `,!*lvisvsi1ii1siiii+\\\\\\*!!!~:,!:~""-   ,~~:*i=>^~
//

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./IERC2981.sol";


contract NiftyLimos is ERC721Enumerable, IERC2981, Ownable {

    using SafeMath for uint256;

    uint256 public  maxLimos              = 10000;
    uint256 public  teamReserveCount      = 1000;
    uint256 public  teamReserveMinted     = 0;
    bool    public  maxLimosFrozenForever = false;
    bool    public  publicSale            = false;
    bool    public  revealed              = false;
    uint256 public  price                 = 0.08 ether;
    uint256 public  publicSaleOffset      = teamReserveCount; //first 1000 Limos are reserved for team
    address private ticketSignerAddress   = 0x78e0eA5fc64eb1f05FB04EE2FBbd9c49d3629c49;
    string  private baseURI;

    struct LimoTicket {
        uint256 tokenId;
        uint256 expire;
        bytes signature;
    }

    event Reveal();


    constructor() ERC721('NiftyLimos', 'NL') {
        baseURI = "https://niftylimos.com/api/limo/";
        transferOwnership(0x8d640BAD3C8aFa0FA15B9d1C641f9264694099cC);
    }


    //public interface
    function mintLimoPublic(uint count) external payable {
        require(publicSale, 'Public Sale is Not Active');
        require(count >= 1 && count <= 10, "count must be larger than 0 and smaller than 10");
        require(totalSupply().sub(teamReserveMinted).add(count) <= maxLimos.sub(teamReserveCount), "Not Enough Limos");
        require(msg.value >= price.mul(count), "Not Enough Ether");
        uint256[] memory limos = getUnmintedLimos(count);
        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, limos[i]);
        }
    }

    function mintLimoByTicket(LimoTicket[] calldata tickets) external {
        require(totalSupply().add(tickets.length) <= maxLimos, "Not Enough Limos");
        for (uint i = 0; i < tickets.length; ++i) {
            verifyTicketAndMint(tickets[i]);
        }
    }


    //owner interface
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setMaxLimos(uint256 max) external onlyOwner {
        require(!maxLimosFrozenForever, "maxLimos is Frozen Forever");
        require(max > maxLimos, "max is must be larger than current value");
        maxLimos = max;
    }

    function freezeMaxLimosForever() external onlyOwner {
        require(!maxLimosFrozenForever, "Already Frozen");
        maxLimosFrozenForever = true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function setPublicSale(bool open) external onlyOwner {
        publicSale = open;
    }

    function setPrice(uint256 newPrice) external onlyOwner() {
        price = newPrice;
    }

    function reveal() external onlyOwner {
        require(!revealed, "already revealed");
        revealed = true;
        emit Reveal();
    }


    //internal
    function verifyTicketAndMint(LimoTicket calldata ticket) private {
        bytes32 ticketHash = keccak256(abi.encode(msg.sender, ticket.tokenId, ticket.expire));
        bytes32 ethMsgHash = ECDSA.toEthSignedMessageHash(ticketHash);
        require(ticketSignerAddress == ECDSA.recover(ethMsgHash, ticket.signature), 'Invalid LimoTicket signature');
        require(block.timestamp <= ticket.expire, "Expired LimoTicket");
        require(ticket.tokenId >= 0 && ticket.tokenId < maxLimos, "Invalid LimoTicket tokenId");
        _safeMint(msg.sender, ticket.tokenId);
        if (ticket.tokenId < teamReserveCount) {
            ++teamReserveMinted;
        }
    }

    function getUnmintedLimos(uint256 count) private returns (uint256[] memory) {
        uint256[] memory limos = new uint256[](count);
        uint256 checked;
        uint256 found;
        for (uint256 id = publicSaleOffset; id < maxLimos; ++id) {
            ++checked;
            if (!_exists(id)) {
                limos[found] = id;
                ++found;
                if (found == count) {
                    break;
                }
            }
        }
        publicSaleOffset += checked;
        return limos;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override(IERC2981) returns (
        address receiver,
        uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = _salePrice.mul(75).div(1000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
