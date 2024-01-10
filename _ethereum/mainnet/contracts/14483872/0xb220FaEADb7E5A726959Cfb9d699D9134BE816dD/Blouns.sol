// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";

interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

contract Blouns is ERC721, IERC2981, Ownable {
    using Strings for uint256;

    ProxyRegistry public immutable proxyRegistry;
    string private _contractCID;
    mapping(uint256 => address) private _minter;
    uint256 public totalSupply;

    constructor(string memory contractCID) ERC721("Blouns", "BLOUN") {
        proxyRegistry = ProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1); //wyvernproxyregistry.eth
        _contractCID = contractCID;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractCID));
    }

    function setContractURI(string memory newContractCID) external onlyOwner {
        _contractCID = newContractCID;
    }

    function isApprovedForAll(address owner, address operator) override(ERC721) public view returns (bool) {
        if (proxyRegistry.proxies(owner) == operator) return true;
        return super.isApprovedForAll(owner, operator);
    }

    function minter(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "URI query for nonexistent token");
        while (_minter[tokenId] == address(0)) tokenId--;
        return _minter[tokenId];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        address tokenMinter = minter(tokenId); //
        string[241] memory colors = ['000000', '00499C', '0079FC', '009C59', '00A556', '00FCFF', '018146', '027C92', '027EE6', '0385EB', '049D43', '068940', '0ADC4D', '0B5027', '1929F4', '1E3445', '1F1D29', '235476', '254EFB', '257CED', '26B1F3', '27A463', '2A86FD', '2B2834', '2B83F6', '2BB26B', '343235', '34AC80', '375DFC', '38DD56', '395ED1', '3A085B', '3F9323', '410D66', '4243F8', '42FFB0', '45FAFF', '49B38B', '4A5358', '4B4949', '4B65F7', '4BEA69', '4D271B', '505A5C', '535A15', '552D1D', '552E05', '554543', '555353', '5648ED', '58565C', '5A423F', '5A65FA', '5A6B7B', '5C25FB', '5D3500', '5D6061', '5FD4FB', '604666', '62616D', '63A0F9', '648DF9', '667AF9', '67B1E3', '6B3F39', '6B7212', '6E3206', '6F597A', '70E890', '71BDE4', '74580D', '757576', '767C0E', '76858B', '769CA9', '7CC4F2', '7D635E', '7E5243', '807F7E', '80A72D', '834398', '85634F', '867C1D', '876F69', '87E4D9', '8BC0C5', '8DD122', '8F785E', '903707', '909B0E', '962236', '97F2FB', '99E6DE', '9CB4B8', '9D8E6E', '9EB5E1', '9F21A0', '9F4B27', 'A19C9A', 'A28EF4', 'A38654', 'A3BAED', 'A3EFD0', 'A86F60', 'AA940C', 'AAA6A4', 'AB36BE', 'ABAAA8', 'ABF131', 'ADC8CC', 'AE3208', 'AE6C0A', 'B19E00', 'B2958D', 'B2A8A5', 'B87B11', 'B8CED2', 'B9185C', 'B91B43', 'B92B3C', 'BD2D24', 'C16710', 'C16923', 'C3A199', 'C4DA53', 'C5030E', 'C54E38', 'C5B9A1', 'CAA26A', 'CAEFF9', 'CBC1BC', 'CC0595', 'CD916D', 'CEC189', 'CFC2AB', 'CFC9B8', 'D08B11', 'D0AEA9', 'D18687', 'D19A54', 'D22209', 'D26451', 'D29607', 'D31E14', 'D32A09', 'D4A015', 'D4B7B2', 'D4CFC0', 'D56333', 'D596A6', 'D5D7E1', 'D62149', 'D6C3BE', 'D7D3CD', 'D8DADF', 'D9391F', 'DA42CB', 'DB8323', 'DCD8D3', 'DF2C39', 'E11833', 'E1D7D5', 'E2C8C0', 'E4A499', 'E4AFA3', 'E5E5DE', 'E7A32C', 'E8705B', 'E8E8E2', 'E9265C', 'E9BA12', 'EAB118', 'EC5B43', 'EEB78C', 'EED811', 'EEDC00', 'EFAD81', 'EFF2FA', 'F20422', 'F3322C', 'F38B7C', 'F39713', 'F39D44', 'F59B34', 'F5FCFF', 'F681E6', 'F71248', 'F78A18', 'F7913D', 'F82905', 'F83001', 'F86100', 'F89865', 'F8CE47', 'F8D689', 'F8DDB0', 'F938D8', 'F98F30', 'F9E8DD', 'F9F4E6', 'F9F5CB', 'F9F5E9', 'F9F6D1', 'FA5E20', 'FA6FE2', 'FB4694', 'FBC311', 'FBC800', 'FCCF25', 'FD8B5B', 'FDCEF2', 'FDE7F5', 'FDF008', 'FDF8FF', 'FE500C', 'FEB9D5', 'FEE3F3', 'FF0E0E', 'FF1A0B', 'FF1AD2', 'FF3A0E', 'FF638D', 'FF7216', 'FF82AD', 'FFA21E', 'FFAE1A', 'FFB913', 'FFC110', 'FFC5F0', 'FFC925', 'FFD067', 'FFE939', 'FFEF16', 'FFF006', 'FFF0BE', 'FFF0EE', 'FFF449', 'FFF671', 'FFFDF2', 'FFFDF4', 'FFFFFF'];
        string memory tokenString = tokenId.toString();
        bytes memory image = '<svg width="2000" height="2000" version="1.1" xmlns="http://www.w3.org/2000/svg"><defs>';
        uint256 layers = tokenId % 6 + 4;
        for (uint256 l = 0; l < layers; l++ ) {
            uint256 hash = uint256(keccak256(abi.encodePacked(tokenMinter, tokenId, l)));
            image = abi.encodePacked(image, '<radialGradient id="g', l.toString(), '" cx="0.', (1 + (hash >> 0) % 9).toString(),'" cy="0.', (1 + (hash >> 4) % 9).toString(), '" r="0.', (1 + (hash >> 8) % 9).toString());
            image = abi.encodePacked(image, '" fx="0.', (6 + (hash >> 12) % 4).toString(), ((hash >> 14) % 9).toString(), '" fy="0.', (4 + (hash >> 18) % 6).toString(), ((hash >> 21) % 9).toString(), '" spreadMethod="', ['reflect', 'repeat', 'pad'][(hash >> 25) % 3], '">');
            uint256 cs = (hash >> 27) % 3 + 2;
            for (uint256 c = 0; c < cs; c++) {
                image = abi.encodePacked(image, '<stop offset="', (100 - 100 / (c + 1)).toString() , '%" stop-color="#', colors[(hash >> (29 + c * 16)) % colors.length], l == 0 ? '' : ((hash >> (37 + c * 16)) % 9).toString(), l == 0 ? '' : ((hash >> (41 + c * 16)) % 9).toString(), '"/>');
            }
            image = abi.encodePacked(image, '<stop offset="100%" stop-color="#', colors[(hash >> 29) % colors.length], (l == 0 ? '' : 'AA'), '"/></radialGradient>');
        }
        uint256 hash2 = uint256(keccak256(abi.encodePacked(tokenMinter, tokenId)));
        string memory channel = ['R', 'G', 'B'][hash2 % 3];
        image = abi.encodePacked(image,
            '</defs>',
            '<filter id="n"><feTurbulence baseFrequency="0.00', (1 + (hash2 >> 2) % 9).toString(),' 0.00', (1 + (hash2 >> 6) % 9).toString(),'" result="NOISE" numOctaves="3" /><feDisplacementMap in="SourceGraphic" in2="NOISE" scale="100" xChannelSelector="', channel, '" yChannelSelector="', channel, '"></feDisplacementMap></filter>',
            '<filter id="g" filterUnits="objectBoundingBox" x="-25%" y="-25%" width="150%" height="150%"><feTurbulence baseFrequency="0.1 0.1" result="NOISE" numOctaves="2" /><feDisplacementMap in="SourceGraphic" in2="NOISE" scale="0.66" xChannelSelector="R" yChannelSelector="B" result="tmp"></feDisplacementMap><feBlend in="tmp" in2="SourceGraphic" mode="overlay"/></filter>'
        );
        for (uint256 l = 0; l < layers; l++) {
            uint256 hash = uint256(keccak256(abi.encodePacked(hash2, l)));
            image = abi.encodePacked(image, '<rect x="10%" y="9%" rx="', (250 + hash % 750).toString(), '" ry="', (250 + (hash >> 10) % 750).toString(), '" width="77%" height="77%" fill="url(#g', l.toString(), ')" filter="url(#n)"/>');
        }
        image = abi.encodePacked(image, '<svg width="100%" height="100%" viewBox="-', (5 - (hash2 >> 18) % 3).toString(), ' -', (5 - (hash2 >> 20) % 3).toString(), ' 36 36" preserveAspectRatio="xMidYMid meet" filter="url(#g)">');
        string[14] memory glassesColors = ['000000', 'd7d3cd', '2b83f6', '5648ed', '8dd122', '9cb4b8', 'e8705b', 'd19a54', 'b9185c', 'fe500c', 'f3322c', '4bea69', 'e8705b', 'ffef16'];
        string memory glassesPart1 = 'M11,12h2M18,12h2M11,13h2M18,13h2M11,14h2M18,14h2M11,15h2M18,15h2';
        string memory glassesPart2 = 'M13,12h2M20,12h2M13,13h2M20,13h2M13,14h2M20,14h2M13,15h2M20,15h2';
        uint256 glasses = (hash2 >> 22) % 21;
        if (glasses == 0) image = abi.encodePacked(image, '<path stroke="#ffc110" d="M10,11h6M10,12h1M15,12h1M10,13h1M15,13h1M7,14h1M10,14h1M15,14h1M7,15h1M10,15h1M15,15h1M10,16h6"/><path stroke="#f98f30" d="M17,11h6M17,12h1M22,12h1M17,13h1M22,13h1M17,14h1M22,14h1M17,15h1M22,15h1M17,16h6"/><path stroke="#ffffff" d="', glassesPart1, '"/><path stroke="#000000" d="', glassesPart2, '"/><path stroke="#f78a18" d="M7,13h3M16,13h1"/>');
        else if (glasses == 1) image = abi.encodePacked(image, '<path stroke="#ff638d" d="M10,11h6M17,11h6M10,12h1M15,12h1M17,12h1M22,12h1M7,13h4M15,13h3M22,13h1M7,14h4M15,14h3M22,14h1M7,15h1M10,15h1M15,15h1M17,15h1M22,15h1M10,16h6M17,16h6"/><path stroke="#ffffff" d="', glassesPart1, '"/><path stroke="#000000" d="', glassesPart2, '"/>');
        else if (glasses == 2) image = abi.encodePacked(image, '<path stroke="#000000" d="M10,11h6M17,11h6M10,12h1M13,12h3M17,12h1M20,12h3M7,13h4M13,13h5M20,13h3M7,14h1M10,14h1M13,14h3M17,14h1M20,14h3M7,15h1M10,15h1M13,15h3M17,15h1M20,15h3M10,16h6M17,16h6"/><path stroke="#ffffff" d="', glassesPart1, '"/>');
        else if (glasses == 3) image = abi.encodePacked(image, '<path stroke="#000000" d="M10,11h6M17,11h6M10,12h3M14,12h2M17,12h3M21,12h2M7,13h16M7,14h1M10,14h1M12,14h2M15,14h1M17,14h1M19,14h2M22,14h1M7,15h1M10,15h6M17,15h6M10,16h6M17,16h6"/><path stroke="#ff0e0e" d="M13,12h1M20,12h1"/><path stroke="#0adc4d" d="M11,14h1M18,14h1"/><path stroke="#1929f4" d="M14,14h1M21,14h1"/>');
        else if (glasses == 4) image = abi.encodePacked(image, '<path stroke="#000000" d="M10,11h6M17,11h6M10,12h4M15,12h1M17,12h4M22,12h1M7,13h7M15,13h6M22,13h1M7,14h1M10,14h6M17,14h6M7,15h1M10,15h6M17,15h6M10,16h6M17,16h6"/><path stroke="#ffffff" d="M14,12h1M21,12h1M14,13h1M21,13h1"/>');
        else if (glasses <= 6) image = abi.encodePacked(image, '<path stroke="#', (glasses == 5 ? '068940' : 'ff638d'), '" d="M10,11h6M10,12h1M15,12h1M10,13h1M15,13h1M10,14h1M15,14h1M10,15h1M15,15h1M10,16h6"/><path stroke="#', (glasses == 5 ? '257ced' : 'cc0595'), '" d="M17,11h6M17,12h1M22,12h1M17,13h1M22,13h1M7,14h1M17,14h1M22,14h1M7,15h1M17,15h1M22,15h1M17,16h6"/><path stroke="#ffffff" d="', glassesPart1, '"/><path stroke="#000000" d="', glassesPart2, '"/><path stroke="#', (glasses == 5 ? '254efb' : 'ab36be'), '" d="M7,13h3M16,13h1"/>');
        else image = abi.encodePacked(image, '<path stroke="#', glassesColors[glasses - 7], '" d="M10,11h6M17,11h6M10,12h1M15,12h1M17,12h1M22,12h1M7,13h4M15,13h3M22,13h1M7,14h1M10,14h1M15,14h1M17,14h1M22,14h1M7,15h1M10,15h1M15,15h1M17,15h1M22,15h1M10,16h6M17,16h6"/><path stroke="#', (glasses == 8 ? 'fdf8ff' : 'ffffff'), '" d="', glassesPart1, '"/><path stroke="#', (glasses == 7 ? 'ff0e0e' : '000000'), '" d="', glassesPart2, '"/>');
        bytes memory color = abi.encodePacked(
            ((hash2 >> 42) % 3).toString(),
            ((hash2 >> 44) % 3).toString(),
            ((hash2 >> 46) % 3).toString(),
            ((hash2 >> 48) % 3).toString(),
            ((hash2 >> 50) % 3).toString(),
            ((hash2 >> 52) % 3).toString()
        );
        for (uint256 i = 0; i < 2; i++) {
            image = abi.encodePacked(image,
                '<rect x="', (8 - i + (hash2 >> 27) % 6).toString(), '" y="', (20 - i + (hash2 >> 30) % 5).toString(), '" width="', (i == 1 ? 1 : 3 + (hash2 >> 33) % 3).toString(), '" height="1" transform="rotate(-', ((hash2 >> 35) % 2).toString(), '.', (1 + (hash2 >> 36) % 9).toString(), ','
            );
            image = abi.encodePacked(image,
                ((3 + (hash2 >> 40) % 3) / 2).toString(),
                ',0.5)" fill="#',
                color,
                '"/>'
            );
        }
        image = abi.encodePacked(image,
            '</svg>',
            '</svg>'
        );
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"Bloun ', tokenString, '", "description":"The beautiful on-chain Bloun was born, a CC0 tribute to the iconic Nouns project.", "image": "', 'data:image/svg+xml;base64,', Base64.encode(image), '", "attributes": {"trait_type": "Layers", "value": ', layers.toString(), '}}')
                    )
                )
            )
        );
    }

    receive() external payable {}

    function mint(uint256 amount) external payable {
        uint256 supply = totalSupply;
        require(supply + amount <= 2222, "Max 2222 Blouns");
        require(msg.value >= amount * 0.02222 ether, "Mint price 0.02222 ETH");
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, supply + i);
        }
        totalSupply = supply + amount;
        _minter[supply] = msg.sender; //one slot for all minted tokens
    }

    function royaltyInfo(uint256, uint256 _salePrice) override external view returns (address receiver, uint256 royaltyAmount) {
        receiver = address(this);
        royaltyAmount = _salePrice * 2222 / 100000; //2.222%
    }

    function withdraw(address token, uint256 amount) external {
        bool success;
        uint256 half = amount / 2;
        if (token == address(0)) {
            (success, ) = 0x908c5fBae8Dec9202d8fAF7cA0277E50b87ED03B.call{value: half}("");
            require(success);
            (success, ) = 0x599b418AD25C7b11BFB6A9108bb03E0e0FF8e690.call{value: half}("");
            require(success);
        } else {
            success = IERC20(token).transfer(0x908c5fBae8Dec9202d8fAF7cA0277E50b87ED03B, half);
            require(success);
            success = IERC20(token).transfer(0x599b418AD25C7b11BFB6A9108bb03E0e0FF8e690, half);
            require(success);
        }
    }
}
