//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";

import "./Base64.sol";
import "./SmartbagsUtils.sol";

contract SmartbagsRenderer {
    using Strings for uint256;

    function render(
        address contractAddress,
        string memory tokenNumber,
        string memory name,
        SmartbagsUtils.Color memory color,
        bytes memory texture,
        bytes memory fonts
    ) external view returns (string memory) {
        name = SmartbagsUtils.getName(contractAddress);

        string memory imgDataURI = Base64.toB64SVG(
            _renderImage(
                abi.encodePacked(
                    'data:image/bmp;base64,',
                    Base64.encode(
                        bytes.concat(
                            bytes18(0x424D7C000000000000001A0000000C000000), // bmp header
                            bytes2(uint16(56)) << 8,
                            bytes2(uint16(56)) << 8,
                            bytes4(0x01001800),
                            SmartbagsUtils.renderContract(
                                contractAddress,
                                9408
                            ),
                            bytes2(0)
                        )
                    )
                ),
                texture,
                fonts,
                uint256(uint160(contractAddress)).toHexString(20),
                tokenNumber,
                name,
                color.color
            )
        );

        return
            Base64.toB64JSON(
                abi.encodePacked(
                    '{"name":"BAG #',
                    tokenNumber,
                    '","description":"This smartbag uses contract ',
                    uint256(uint160(contractAddress)).toHexString(20),
                    ' to generate its output.\\n\\n',
                    'Handle with care.\\n\\n',
                    '#thetokenisthecanvas","attributes":[{"trait_type":"color","value":"',
                    color.name,
                    '"},{"trait_type":"Contract Address","value":"',
                    uint256(uint160(contractAddress)).toHexString(20),
                    '"}],"image":"',
                    imgDataURI,
                    '"}'
                )
            );
    }

    function _renderImage(
        bytes memory bmpURI,
        bytes memory texture,
        bytes memory fonts,
        string memory addrString,
        string memory tokenNumber,
        string memory name,
        string memory color
    ) internal pure returns (bytes memory) {
        bytes memory shortName;
        if (bytes(name).length > 23) {
            shortName = new bytes(23);
            for (uint256 i; i < 23; i++) {
                if (i >= 20) shortName[i] = bytes1('.');
                else shortName[i] = bytes(name)[i];
            }
        } else {
            shortName = bytes(name);
        }

        // create the SVG
        return
            abi.encodePacked(
                abi.encodePacked(
                    "<svg width='2884' height='2884' viewBox='0 0 2884 2884' xmlns='http://www.w3.org/2000/svg'>",
                    '<style>',
                    fonts,
                    '.contractImage {image-rendering:optimizeSpeed;image-rendering:-moz-crisp-edges;image-rendering:-o-crisp-edges;image-rendering:-webkit-optimize-contrast;image-rendering:optimize-contrast;image-rendering:crisp-edges;image-rendering:pixelated;-ms-interpolation-mode:nearest-neighbor;}',
                    '.id {font-family:arial, sans-serif;fill:#ffeeff;font-size:130px;font-weight:800;letter-spacing:-4px;}svg {filter:contrast(1.25) saturate(1) brightness(1.1);}',
                    '</style>'
                ),
                abi.encodePacked(
                    '<defs>',
                    "<filter id='threshold' x='0%' y='0%' width='100%' height='100%'>",
                    "<feFlood x='0' y='0' height='4' width='4' result='pixel'/>",
                    "<feComposite in='pixel' width='22' height='22' result='compositedPixel'/>",
                    "<feTile in='compositedPixel' result='a'/>",
                    "<feComposite in='SourceGraphic' in2='a' operator='in' result='pix'/>",
                    "<feMorphology in='pix' operator='dilate' radius='10.5' result='pix'/>",
                    "<feColorMatrix in='pix' type='saturate' values='0'/>",
                    "<feColorMatrix type='matrix' values='-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0'/>",
                    '<feComponentTransfer>',
                    "<feFuncR type='discrete' tableValues='0 0  1'/>",
                    "<feFuncG type='discrete' tableValues='0 0 1'/>",
                    "<feFuncB type='discrete' tableValues='0 0  1'/>",
                    '</feComponentTransfer>',
                    '</filter>'
                ),
                abi.encodePacked(
                    "<pattern id='a' patternUnits='userSpaceOnUse' width='70' height='8' patternTransform='scale(2.8) rotate(140)'>",
                    "<rect x='0' y='0' width='100%' height='100%' fill='hsla(0, 0%, 0%, 1)'/>",
                    "<path d='M-.02 22c8.373 0 11.938-4.695 16.32-9.662C20.785 7.258 25.728 2 35 2c9.272 0 14.215 5.258 18.7 10.338C58.082 17.305 61.647 22 70.02 22M-.02 14.002C8.353 14 11.918 9.306 16.3 4.339 20.785-.742 25.728-6 35-6 44.272-6 49.215-.742 53.7 4.339c4.382 4.967 7.947 9.661 16.32 9.664M70 6.004c-8.373-.001-11.918-4.698-16.3-9.665C49.215-8.742 44.272-14 35-14c-9.272 0-14.215 5.258-18.7 10.339C11.918 1.306 8.353 6-.02 6.002' stroke-width='3' stroke='white' fill='none'/>",
                    '</pattern>',
                    "<linearGradient id='lgrad' x1='50%' y1='0%' x2='50%' y2='100%' >",
                    "<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1.00'/>",
                    "<stop offset='100%' style='stop-color:rgba(0,0,0,0);stop-opacity:1.00'/>",
                    '</linearGradient>',
                    "<image id='t' x='701' y='465' width='1540' height='1925' href='data:image/png;base64,",
                    texture,
                    "'/>",
                    "<mask id='smartbagMask'>",
                    "<rect x='0' y='0' width='100%' height='100%' fill='white'/>"
                ),
                abi.encodePacked(
                    "<g transform='translate(753 540)'>",
                    "<path d='M15.6986 12.0848C15.6986 1.79058 23.0156 1.48782 26.6741 2.62321C56.3635 4.10143 132.391 7.05788 198.984 7.05788C282.225 7.05788 342.7 16.3069 381.831 21.9987C420.961 27.6904 423.807 33.3821 457.246 31.2477C497.8 28.4019 500.646 32.6707 573.927 38.3624C684.915 51.4534 802.725 39.2665 847.756 31.5367C892.219 27.2158 991.598 18.4069 1033.41 17.7379C1075.23 17.0688 1091.53 14.9502 1094.46 13.9746C1138.78 4.35723 1136.28 3.93908 1178.51 3.52094C1220.74 3.10279 1394.46 2.25186 1406.44 1.12229C1418.41 -0.00728762 1415.47 6.99607 1415.92 9.48114C1416.38 11.9662 1414.34 39.9796 1414.57 62.5711C1414.79 85.1626 1412.08 124.698 1412.99 151.582C1413.89 178.465 1410.73 178.465 1410.95 188.18C1411.13 195.951 1401.99 195.635 1397.4 194.505C1394.24 193.451 1387.64 193.15 1386.55 200.379C1385.47 207.608 1390.47 210.018 1393.11 210.319C1394.24 210.319 1397.99 210.5 1403.95 211.223C1411.41 212.127 1410.95 214.838 1411.01 226.543C1410.32 279.886 1401.31 439.915 1401.31 543.829C1399.23 726.72 1399.93 758.587 1404.08 801.539C1407.41 835.9 1409.16 889.751 1409.63 912.381C1409.16 924.158 1409.63 960.875 1411.01 980.272C1415.86 1042.62 1413.78 1082.11 1410.32 1127.83C1406.85 1173.55 1402 1187.41 1401.31 1254.61C1400.62 1321.81 1403.39 1338.43 1403.39 1427.8C1403.39 1517.17 1404.77 1637.46 1405.03 1639.79C1405.24 1641.65 1407.02 1724.4 1407.89 1765.54L1407.88 1765.66C1407.69 1775.24 1407.63 1778.5 1392.41 1777.34C1374.99 1777.92 1350.42 1775.45 1316.44 1774.39C1243.17 1774.39 1175.21 1757.4 1139.11 1753.15C1068.6 1746.36 1034.7 1746.78 1026.55 1747.84C929.927 1762.71 887.453 1746.78 844.98 1743.6C745.166 1740.41 706.94 1751.03 653.848 1759.52C550.849 1779.7 542.354 1773.33 497.757 1770.14C363.964 1763.77 320.429 1768.02 280.079 1769.08C197.255 1777.57 109.075 1764.33 102.665 1762.57C94.6527 1760.16 39.8989 1755.34 31.1037 1755.49C13.215 1756.68 13.215 1739.98 12.9168 1735.66C12.6187 1731.34 11.4551 1707.99 12.5028 1700.66C13.3409 1694.79 9.35966 1673.42 7.26425 1663.47C3.07344 1638.32 3.07344 1597.99 9.88351 1548.74C16.6936 1499.5 20.3605 1435.59 19.8367 1411.49C19.3128 1349.68 20.3605 1369.06 20.3605 1308.82C20.3605 1248.58 17.7413 1236 5.69274 1185.19C-6.35585 1134.38 5.16889 1079.37 21.9321 1000.27C38.6954 921.169 29.2661 867.212 27.1707 838.4C25.0753 809.588 13.0266 729.439 7.78811 678.102C2.54959 626.764 8.31194 550.806 9.35964 537.185C10.4073 523.565 14.0743 498.42 12.671 474.187C10.4002 431.421 11.5356 368.975 12.671 345.51C13.8063 322.045 15.6986 223.267 15.6986 219.482C15.6986 215.697 15.6986 210.02 26.6741 210.399C37.6495 210.777 37.6494 208.128 39.1633 202.83C40.3744 198.591 36.6402 195.765 34.6218 194.882C33.2341 195.008 29.0205 195.185 23.2679 194.882C17.5153 194.579 15.8248 189.962 15.6986 187.691V12.0848Z' fill='black'/>",
                    '</g>',
                    '</mask>',
                    "<mask id='frontMask'>",
                    "<rect x='0' y='0' width='100%' height='100%' fill='white'/>",
                    "<rect x='910' y='1090' width='1100' height='1070' fill='black' style='opacity:.3'/>",
                    '</mask>',
                    '</defs>'
                ),
                abi.encodePacked(
                    "<rect id='bg' width='100%' height='100%' fill='black'/>",
                    "<g id='bag'>",
                    "<rect width='100%' height='574'  transform='translate(701 465)' fill='#ddccdd'/>",
                    "<image transform='translate(706 1060)' filter='url(#threshold)' class='contractImage' width='1250' height='1250' href='",
                    bmpURI,
                    "'/>",
                    "<g style='font-family:arial,sans-serif;fill:black;font-size:15em;font-style:italic;font-weight:800;letter-spacing:-15px;transform-origin:0% 0%;transform:rotate(-90deg);stroke:white;stroke-width:5px;mix-blend-mode:difference;'>",
                    "<text x='-3030' y='1928'>THETOKENISTHECANVASTHETOKENISTHECANVAS</text>",
                    "<text x='-4630' y='1735'>THETOKENISTHECANVASTHETOKENISTHECANVAS</text>",
                    '</g>',
                    "<rect x='803' y='800' width='480' height='40' fill='black'/>"
                ),
                abi.encodePacked(
                    "<rect x='1956' y='1038' width='300' height='100%' fill='black'/>",
                    "<text x='-2330' y='2150' style='font-family:InterB;fill:#ddccdd;font-size:15em;letter-spacing:.06em;transform-origin:0% 0%;transform:rotate(-90deg);mix-blend-mode:difference;'>",
                    name,
                    '</text>',
                    "<rect x='1000' y='1050' width='90' height='1300' fill='url(#a)' style='mix-blend-mode:multiply;'/>",
                    "<rect x='706' y='1060' width='1250' height='1255' style='mix-blend-mode:darken' fill='",
                    color,
                    "'/>",
                    "<circle cx='1805' cy='780' r='185' style='fill:black'/>",
                    "<text x='1675' y='825' class='id'>"
                ),
                abi.encodePacked(
                    tokenNumber,
                    '</text>',
                    "<text x='1640' y='820' class='id' style='font-family:InterB;font-size:100px;stroke:black;stroke-width:13px;'>#</text>",
                    "<text x='1640' y='820' class='id' style='font-family:InterB;font-size:100px;stroke-linecap:round;'>#</text>",
                    "<text x='803' y='780' style='font-family:InterB;fill:black;font-size:35px;letter-spacing:-2px;'>",
                    shortName,
                    '</text>',
                    "<text x='814' y='826' style='font-family:Monospace,sans-serif;fill:#ffeeff;font-size:17px;font-weight:100;letter-spacing:.8px;'>",
                    addrString,
                    '</text>',
                    "<text x='803' y='980' style='font-family:InterEB;fill:black;font-size:145px;letter-spacing:-12px;'>smartbags.</text>"
                ),
                abi.encodePacked(
                    "<g transform='translate(1860 580) scale(3)' style='fill:#ffeeff;mix-blend-mode:difference;'>",
                    "<path d='M0 10.25L10.25 0L20.5 10.25L30.75 0L41 10.25L30.75 20.5L41 30.75L30.75 41L20.5 30.75L10.25 41L0 30.75L10.25 20.5L0 10.25Z'></path>",
                    '</g>',
                    "<g style='font-family:arial,sans-serif;fill:black;font-size:12px;font-weight:300;letter-spacing:-.5px;'>",
                    "<text x='805' y='600'>&gt; node smartbags.js</text>",
                    "<text x='805' y='615'>&gt; limited editions NFTs representing smart contracts.</text>",
                    "<text x='805' y='630'>&gt; each smartbag is a visual representation of the corresponding smart contract.</text>",
                    "<text x='805' y='645'>&gt; the visual is created on-chain.</text>",
                    "<text x='805' y='660'>&gt; created by @dievardump &amp; @nahiko.</text>",
                    "<text x='805' y='675'>&gt; the token is the canvas.</text>",
                    "<text x='805' y='690'>&gt; loading...</text>"
                ),
                abi.encodePacked(
                    '</g>',
                    "<rect x='2128' width='99' height='100%' fill='",
                    color,
                    "'/>",
                    "<use href='#t' style='mix-blend-mode:screen;opacity:.8;'/>",
                    "<use href='#t' style='mix-blend-mode:multiply;opacity:.7;filter:blur(8px)' mask='url(#frontMask)'/>",
                    "<use href='#t' style='mix-blend-mode:overlay;opacity:.2;'/>",
                    "<rect x='910' y='1090' width='1100' height='1070' fill='url(#lgrad)' style='mix-blend-mode:overlay;opacity:0.2'/>",
                    "<rect x='910' y='1090' width='1100' height='1070' fill='white' style='mix-blend-mode:color;opacity:0.2'/>",
                    "<rect width='100%' height='100%' fill='black' mask='url(#smartbagMask)'/>",
                    '</g>',
                    '</svg>'
                )
            );
    }
}
