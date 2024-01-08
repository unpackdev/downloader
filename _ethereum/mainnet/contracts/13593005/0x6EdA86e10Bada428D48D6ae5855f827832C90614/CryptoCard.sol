// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./SafeMath.sol";

contract CryptoCard is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Address for address payable;
    using Strings for uint256;
    using SafeMath for uint256;

    string[] private randColor = [
        "red", "green", "blue", "#FF00FF", "#FFFF00", "#00FFFF"
    ];

    string[] private ethColor = [
        "#594100", "#590044", "#001859", "#005915", "gray"
    ];

    string[] private randBG = [
        "#17163B", "#3B1627", "#442244", "#224444", "#163B2A",
        "#771414", "#AF8D14", "#F699CD", "#F6F199", "#99F6C2",
        "#999EF6"
    ];

    uint256 public mintFee = 0.06 ether;
    bool public mintEnable = true;

    uint256 private _deployerBalance;

    mapping(uint256 => string) private _header;
    mapping(uint256 => string) private _footer;
    mapping(uint256 => string) private _from;
    mapping(uint256 => uint256) private _CCBalance;
    mapping(uint256 => uint256) private _seed;
    uint256 public maxTokens;

    event AddCardBalance(uint256 indexed tokenId, uint256 amount);
    event WithdrawCardBalance(uint256 indexed tokenId, uint256 amount);
    event UpdateCardInfo(uint256 indexed tokenId);

    constructor() ERC721("CryptoCard", "CC") Ownable() {}

    function mintCard(string memory header, string memory footer, string memory from, address to) public payable nonReentrant {
        require(msg.value >= mintFee, "Value below mint fee");
        require(mintEnable, "Mint disabled");

        uint256 mintId = maxTokens;
        maxTokens = maxTokens.add(1);
        _safeMint(to, mintId);

        _deployerBalance = _deployerBalance.add(mintFee);
        _header[mintId] = header;
        _footer[mintId] = footer;
        _from[mintId] = from;
        _seed[mintId] = uint256(keccak256(abi.encodePacked(block.timestamp,
                                                           _msgSender(), to,
                                                           from, header, footer,
                                                           mintId, msg.value)));
        uint256 amount = msg.value.sub(mintFee);
        _CCBalance[mintId] = amount;
        emit AddCardBalance(mintId, amount);
    }

    function checkTokenOwner(uint256 tokenId) private view {
        require(ownerOf(tokenId) == _msgSender(), "ERC721: Not the owner of this token");
    }

    function addCardBalance(uint256 tokenId) public payable nonReentrant {
        checkTokenOwner(tokenId);
        require(msg.value > 0, "Value is zero");

        uint256 amount = _CCBalance[tokenId].add(msg.value);
        _CCBalance[tokenId] = amount;

        emit AddCardBalance(tokenId, msg.value);
    }

    function withdrawCardBalance(uint256 tokenId, uint256 amount) public nonReentrant {
        checkTokenOwner(tokenId);
        uint256 bal = _CCBalance[tokenId];
        require(bal > 0, "Zero balance");
        require(amount > 0, "Amount zero");
        require(bal >= amount, "Insufficient funds");

        _CCBalance[tokenId] = bal.sub(amount);
        payable(_msgSender()).sendValue(amount);

        emit WithdrawCardBalance(tokenId, amount);
    }

    function updateCardInfo(uint256 tokenId, string memory header, string memory footer, string memory from) public {
        checkTokenOwner(tokenId);

        _header[tokenId] = header;
        _footer[tokenId] = footer;
        _from[tokenId] = from;

        emit UpdateCardInfo(tokenId);
    }

    function burnCard(uint256 tokenId) public nonReentrant {
        checkTokenOwner(tokenId);

        _burn(tokenId);

        delete _header[tokenId];
        delete _footer[tokenId];
        delete _from[tokenId];
        delete _seed[tokenId];

        uint256 amount = _CCBalance[tokenId];
        if (amount > 0) {
            delete _CCBalance[tokenId];
            payable(_msgSender()).sendValue(amount);

            emit WithdrawCardBalance(tokenId, amount);
        }
    }

    // Public Getters

    function checkTokenExists(uint256 tokenId) private view {
        require(_exists(tokenId), "CC: Query on nonexistent token");
    }

    function getCardHeader(uint256 tokenId) public view returns (string memory) {
        checkTokenExists(tokenId);
        return _header[tokenId];
    }

    function getCardFooter(uint256 tokenId) public view returns (string memory) {
        checkTokenExists(tokenId);
        return _footer[tokenId];
    }

    function getCardFrom(uint256 tokenId) public view returns (string memory) {
        checkTokenExists(tokenId);
        return _from[tokenId];
    }

    function getCardBalance(uint256 tokenId) public view returns (uint256) {
        checkTokenExists(tokenId);
        return _CCBalance[tokenId];
    }

    function getCardSeed(uint256 tokenId) public view returns (uint256) {
        checkTokenExists(tokenId);
        return _seed[tokenId];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        bytes[4] memory attrib;
        bytes[9] memory parts;

        uint256 salt = 0;
        uint256 seed = _seed[tokenId];
        {
            parts[0] = abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" ',
                'preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 300">',
                '<defs><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse">',
                '<feGaussianBlur stdDeviation="48"/></filter><clipPath id="a">',
                '<rect width="500" height="300" rx="40" ry="40"/></clipPath>',
                '<path id="c" d="M40 12h420a28 28 0 0 1 28 28v220a28 28 0 0 1-28 28H40a28 28 0 0 1-28-28V40a28 28 0 0 1 28-28z"/>',
                '<linearGradient y2="0" x2="1" y1="1" x1="0" id="d"><stop offset="0" stop-color="#D1A255"/>',
                '<stop offset="1" stop-color="#EBDD9E"/></linearGradient><mask id="e"><rect width="100%" height="100%" fill="#fff"/>',
                '<rect rx="4" x="30" y="25" width="30" height="25" fill="#fff" stroke="#000" stroke-width="3"/>');
        }

        uint256 ib = getProperty(seed, salt++, randBG.length);
        bool blk = getRarity(seed, salt++, 3);
        bool dark = !blk && (ib >= 7);
        {
            string memory cb = blk ? 'black' : randBG[ib];
            string memory c0 = getRarity(seed, salt++, 4) ? 'gold' : dark ? 'black' : 'white';
            string memory c1 = getRarity(seed, salt++, 4) ? 'gold' : dark ? 'black' : 'white';
            attrib[0] = abi.encodePacked(c0);
            attrib[1] = abi.encodePacked(c1);
            attrib[2] = abi.encodePacked(cb);

            parts[1] = abi.encodePacked(
                '<path stroke="#000" stroke-width="3" d="M0 37.5h30M60 37.5h30M45 0v25M45 50v25"/></mask>',
                '</defs><style>text{font-family:Courier New,monospace;}.btxt{fill:',c0,'}.htxt{fill:',c1,
                ';font-size:14px;}.ftxt{fill:',c1,';font-size:14px;}</style>',
                '<g clip-path="url(#a)"><path fill="',cb,'" d="M0 0h500v300H0z"/><g style="filter:url(#b)">',
                '<path fill="',cb,'" d="M0 0h500v300H0z"/>');
        }

        {
        uint256 offset = getProperty(seed, salt++, randColor.length);
        {
            string memory c4 = randColor[offset];
            string memory c5 = randColor[(offset + 1) % randColor.length];
            string memory c6 = randColor[(offset + 2) % randColor.length];

            uint256 r0 = 60 + getProperty(seed, salt++, 40);
            uint256 r1 = 60 + getProperty(seed, salt++, 40);
            uint256 r2 = 60 + getProperty(seed, salt++, 40);

            parts[2] = abi.encodePacked(
                '<circle cx="20" cy="20" r="',r0.toString(),'" fill="',c4,'">',
                '<animateMotion dur="10s" repeatCount="indefinite" path="M20,50 C20,-50 180,150 180,50 C180-50 20,150 20,50 z"/>'
                '</circle><circle cx="300" cy="40" r="',r1.toString(),'" fill="',c5,'">'
                '<animateMotion dur="7s" repeatCount="indefinite" path="M20,50 C20,-50 180,150 180,50 C180-50 20,150 20,50 z"/>'
                '</circle><circle cx="40" cy="250" r="',r2.toString(),'" fill="',c6,'">');
        }

        {
            uint256 r3 = 60 + getProperty(seed, salt++, 40);
            string memory c7 = randColor[(offset + 3) % randColor.length];
            parts[3] = abi.encodePacked(
                '<animateMotion dur="5s" repeatCount="indefinite" path="M20,50 C20,-50 180,150 180,50 C180-50 20,150 20,50 z"/>'
                '</circle><circle cx="300" cy="250" r="',r3.toString(),'" fill="',c7,'">'
                '<animateMotion dur="11s" repeatCount="indefinite" path="M20,50 C20,-50 180,150 180,50 C180-50 20,150 20,50 z"/>'
                '</circle></g></g><text text-rendering="optimizeSpeed" xml:space="preserve" class="htxt">');
        }
        }

        {
            string memory header = _header[tokenId];
            string memory footer = _footer[tokenId];
            parts[4] = abi.encodePacked(
                '<textPath startOffset="-100%" xlink:href="#c">',header,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>',
                '<textPath startOffset="0%" xlink:href="#c">',header,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>',
                '</text><text text-rendering="optimizeSpeed" xml:space="preserve" class="ftxt">',
                '<textPath startOffset="50%" xlink:href="#c">',footer,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>',
                '<textPath startOffset="-50%" xlink:href="#c">',footer,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>',
                '</text><g style="transform:translate(360px,22px)">'
                '<g style="transform:scale(.7)">');
        }

        {
            bool rare = getRarity(seed, salt++, 3);
            string memory ec0 = rare ? ethColor[getProperty(seed, salt++, ethColor.length)] : 'black';

            attrib[3] = abi.encodePacked(ec0);

            parts[5] = abi.encodePacked(abi.encodePacked(
                '<path d="M83 100.1 0 137.8l83 49.1 83.1-49.1Z" style="opacity:.5" fill="',ec0,'"/>',
                '<path d="m0 137.8 83 49.1V0Z" style="opacity:.45" fill="',ec0,'"/>',
                '<path d="M83 0v186.9l83.1-49.1Z" style="opacity:.7" fill="',ec0,'"/>',
                '<path d="m0 153.6 83 117v-68Z" style="opacity:.45" fill="',ec0,'"/>',
                '<path d="M83 202.6v68l83.1-117Z" style="opacity:.7" fill="',ec0,'"/></g></g>'),
                '<text y="70" x="32" class="btxt" style="font-size:36px;font-weight:500">CRYPTO CARD</text>',
                '<rect x="30" y="120" width="55" height="47.5" rx="14" fill="rgba(0,0,0,0.4)"/>',
                '<g style="transform:translate(35px,125px)"><rect x="0" y="0" width="90" height="75" rx="20" ',
                'fill="url(#d)" mask="url(#e)" style="transform:scale(.5)"/></g>');
        }

        {
            string memory balance = formatBalance(_CCBalance[tokenId]);
            uint256 fwidth1 = 60 + 72*bytes(tokenId.toString()).length/10;
            string memory color = dark ? '0,0,0' : '255,255,255';
            string memory fsz = bytes(balance).length > 10 ? '20' : '24';
            parts[6] = abi.encodePacked(
                '<text y="100" x="32" class="btxt" style="font-size:',fsz,'px;font-weight:200">',balance,' ETH</text>',
                '<rect x="16" y="16" width="468" height="268" rx="24" ry="24" fill="rgba(0,0,0,0)" stroke="rgba(',color,',0.2)"/>',
                '<g style="transform:translate(30px,185px);font-size:12">',
                '<rect width="',fwidth1.toString(),'" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.55)"/>');

        }

        {
            string memory from = _from[tokenId];
            uint256 fwidth2 = 70 + 72*bytes(from).length/10;
            parts[7] = abi.encodePacked(
                '<text x="12" y="17" fill="#fff" xml:space="preserve"><tspan fill="rgba(255,255,255,0.6)">ID: </tspan>',tokenId.toString(),'</text></g>',
                '<g style="transform:translate(30px,215px);font-size:12"><rect width="',fwidth2.toString(),'" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.55)"/>',
                '<text x="12" y="17" fill="#fff" xml:space="preserve"><tspan fill="rgba(255,255,255,0.6)">From: </tspan>',from,'</text></g>');
        }

        {
            uint256 tokenOwner = uint256(uint160(ownerOf(tokenId)));
            parts[8] = abi.encodePacked(
                '<g style="transform:translate(30px,245px);font-size:12">',
                '<rect width="375" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.55)"/>',
                '<text x="12" y="17" fill="#fff" xml:space="preserve"><tspan fill="rgba(255,255,255,0.6)">',
                'Owner: </tspan>0x', checksum(tokenOwner.toHexString()), '</text></g></svg>');
        }

        bytes memory output = abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]);

        string memory json = Base64.encode(
            abi.encodePacked(abi.encodePacked(
                '{"name": "CryptoCard #', tokenId.toString(),
                '", "description": "CryptoCard is a fully on-chain, generative NFT gift card. ',
                'The text is customizable to celebrate special occasions and lives forever on the blockchain. ',
                'The gift card value is rechargable and redeemable via contract and https://www.raritycard.com.", '),
                '"image": "data:image/svg+xml;base64,', Base64.encode(output), '", "attributes": [{"trait_type": "Main Text Color","value": "',
                attrib[0],'"}, {"trait_type": "Border Text Color","value": "',attrib[1],'"}, {"trait_type": "Card Color","value": "',attrib[2],
                '"}, {"trait_type": "Logo Color","value": "',attrib[3],'"}]}')
        );

        output = abi.encodePacked('data:application/json;base64,', json);

        return string(output);
    }

    // Public Owner

    function ownerToggleEnable() public onlyOwner {
        mintEnable = !mintEnable;
    }

    function ownerSetMintFee(uint256 val) public onlyOwner {
        mintFee = val;
    }

    function ownerGetBalance() public view onlyOwner returns (uint256) {
        return _deployerBalance;
    }

    function ownerSendFee() public nonReentrant onlyOwner {
        uint256 amount = _deployerBalance;
        require(amount > 0, "Invalid balance");
        _deployerBalance = 0;

        payable(owner()).sendValue(amount);
    }

    // Internal

    function getRarity(uint256 seed, uint256 salt, uint8 num) internal pure returns (bool) {
        uint256 hash = uint256(keccak256(abi.encodePacked(seed, salt)));
        for (uint8 i = 0; i < num; i++) {
            if ((hash & (0x1 << i)) != 0) {
                return false;
            }
        }
        return true;
    }

    function getProperty(uint256 seed, uint256 salt, uint256 mod) internal pure returns (uint256) {
        uint256 num = uint256(keccak256(abi.encodePacked(seed, salt))) % mod;
        return num;
    }

    function formatBalance(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 whole = value / 1 ether;
        uint256 fraction =  value % 1 ether;

        string memory frac = fraction.toString();
        bytes memory tmp = bytes(frac);
        uint256 i = tmp.length;
        uint256 nz = (i == 1 && tmp[0] == '0') ? 0 : 18 - i;
        bytes memory zeros = new bytes(nz);
        for (uint256 j = 0; j < nz; j++) {
            zeros[j] = '0';
        }
        if (i > 1) {
            for (; i > 0; i--) {
                if (tmp[i-1] != '0') {
                    break;
                }
            }
        }
        string memory strFrac = substring(frac, 0, i);
        return string(abi.encodePacked(whole.toString(), '.', string(zeros), strFrac));
    }

    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint256 endMax = endIndex > strBytes.length ? strBytes.length : endIndex;
        bytes memory result = new bytes(endMax - startIndex);
        for (uint256 i = startIndex; i < endMax ; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function checksum(string memory addr) internal pure returns (string memory) {
        assert(bytes(addr).length == 42);
        bytes memory tmp = abi.encodePacked(substring(addr,2, 42));
        bytes memory sum = abi.encodePacked(keccak256(tmp));

        bytes memory buffer = new bytes(40);
        for (uint8 i = 0; i < 20; i++) {
            bytes1 ch = sum[i];
            bytes1 a0 = tmp[2*i];
            bytes1 a1 = tmp[2*i+1];
            buffer[2*i] = (ch & 0x80) != 0 && a0 >= 'a' ? a0 ^ ' ' : a0;
            buffer[2*i+1] = (ch & 0x08) != 0 && a1 >= 'a' ? a1 ^ ' ' : a1;
        }
        return string(buffer);
    }
}
