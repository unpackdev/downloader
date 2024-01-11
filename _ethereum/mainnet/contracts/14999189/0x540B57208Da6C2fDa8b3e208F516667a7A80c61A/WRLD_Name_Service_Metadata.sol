// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./base64.sol";
import "./IWRLD_Name_Service_Metadata.sol";
import "./StringUtils.sol";

contract WRLD_Name_Service_Metadata is IWRLD_Name_Service_Metadata {
    using StringUtils for *;
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampToDate(uint timestamp) internal pure returns (string memory) {
        (uint year, uint month, uint day ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        return string(abi.encodePacked(Strings.toString(year), "-" ,Strings.toString(month), "-", Strings.toString(day)));
    }

    function getName(string calldata _name) internal pure returns (string memory) {
        if (bytes(_name).length > 15) {
            return string(abi.encodePacked(string(_name[0:7]), "...", string(_name[bytes(_name).length-5:])));
        }
        return _name;
    }

    function getMetadata(string calldata _name, uint256 _expiresAt) public view override returns (string memory) {
        string memory image = getImage(_name, _expiresAt);

        string memory json = Base64.encode(
            bytes(
                string(
                abi.encodePacked(
                '{"name":"',
                _name,
                '","image":"',
                image,
                '","attributes":[{"display_type":"date","trait_type":"expiresAt","value":"',
                Strings.toString(_expiresAt),
                '"},{"trait_type":"length","value":"',
                Strings.toString(_name.strlen()),
                '"},{"trait_type":"unicode","value":"',
                _name.strlen() == bytes(_name).length?'no':'yes',
                '"}]}'
                ))));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }


    function getImage (string calldata _name, uint256 _expiresAt) public view override returns (string memory) {
        string memory backgroundColor = "url(#paint0_linear_17_3)";
        string memory textColor = "#FFFFFF";
        string memory borderColor = "class='gyellow'";
        if (_name.strlen() == bytes(_name).length) {
            backgroundColor = "url(#paint0_linear_17_2)";
            borderColor = "";

        }
        if (block.timestamp > _expiresAt) {
            textColor = "#FF0000";
        } else if (block.timestamp > _expiresAt - 2592000) {
            textColor = "#FF9933";
        }
        return string(abi.encodePacked(
            "<svg width='1500' height='1500' viewBox='0 0 1500 1500' fill='none' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'><g clip-path='url(#clip0_17_2)'><rect id='rectBg' width='1500' height='1500' fill='",
            backgroundColor,
            "'/><g opacity='0.6'><use xlink:href='#gframe' class='use-gframe' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.9;transform:scale(1.5,1.5);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.8;transform:scale(2,2);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.7;transform:scale(2.5,2.5);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.6;transform:scale(3,3);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.5;transform:scale(3.5,3.5);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.4;transform:scale(4,4);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.3;transform:scale(4.5,4.5);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.2;transform:scale(5,5);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.1;transform:scale(5.5,5.5);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.1;transform:scale(6,6);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.1;transform:scale(6.5,6.5);' /><use xlink:href='#gframe' class='use-gframe' style='opacity:0.1;transform:scale(7,7);' /></g><text id='domainTextWrap1' transform='translate(200 1066)' fill='white' xml:space='preserve' style='white-space: pre;text-shadow: 1px 2px 12px rgba(0,0,0,0.3);' font-family='Maison Neue' font-size='140' font-weight='bold' letter-spacing='0em'><tspan id='domainText1' x='0' y='118.92' >",
            getName(_name),
            "</tspan></text><text id='domainTextWrap2' transform='translate(200 866)' fill='white' xml:space='preserve' style='white-space: pre;' font-family='Maison Neue' font-size='140' font-weight='bold' letter-spacing='0em'><tspan id='domainText2' x='0' y='138.92' ></tspan></text><text id='textColor' transform='translate(900 1100)' fill='",
            textColor,
            "' xml:space='preserve' style='white-space: pre;text-shadow: 1px 2px 12px rgba(0,0,0,0.3);' font-family='Maison Neue' font-size='90' font-weight='bold' letter-spacing='0em'><tspan id = 'timeText' x='0' y='300'>",
            timestampToDate(_expiresAt),
            "</tspan></text><g filter='url(#filter0_dddddd_17_2)'><path d='M880.84 338.641C880.774 338.603 880.702 338.578 880.628 338.566L751.425 288.325C750.946 288.111 750.428 288 749.904 288C749.444 288.01 748.993 288.121 748.582 288.325L619.267 338.641C618.882 338.709 618.524 338.882 618.232 339.141L617.857 339.391C617.617 339.656 617.422 339.96 617.284 340.291V340.403C617.189 340.515 617.12 340.648 617.084 340.79C617.029 340.921 617 341.061 617 341.203C617 341.344 617.029 341.485 617.084 341.615V383.647C617.071 384.248 617.275 384.834 617.658 385.297L619.092 386.384L748.582 436.75C749.003 436.916 749.451 437.001 749.904 437C750.421 436.998 750.934 436.914 751.425 436.75L881.002 386.384C881.579 386.169 882.082 385.792 882.449 385.297C882.743 384.797 882.898 384.227 882.898 383.647V341.615C882.965 341.475 883 341.321 883 341.165C883 341.009 882.965 340.856 882.898 340.715C882.897 340.654 882.882 340.594 882.854 340.54C882.826 340.485 882.785 340.439 882.735 340.403V340.291C882.588 339.965 882.395 339.662 882.162 339.391L881.862 339.141C881.556 338.911 881.209 338.741 880.84 338.641V338.641ZM866.585 342.977V343.402L750.278 388.633L631.414 343.402V342.977L694.232 319.112L750.278 297.796L761.776 302.244L768.012 304.681L775.108 307.442L866.585 342.977Z' fill='white'/></g></g><defs><g id='gframe' style='mix-blend-mode:overlay' opacity='0.9' ",
            borderColor,
            "><path class='gpath' d='M1012.88 314.84C1012.75 314.761 1012.61 314.71 1012.45 314.69L752.954 213.97C751.991 213.54 750.948 213.319 749.894 213.32C748.973 213.339 748.068 213.561 747.244 213.97L487.514 314.84C486.741 314.973 486.02 315.32 485.434 315.84L484.684 316.34C484.193 316.869 483.804 317.482 483.534 318.15V318.37C483.341 318.597 483.201 318.863 483.124 319.15C483.015 319.412 482.959 319.692 482.959 319.975C482.959 320.259 483.015 320.539 483.124 320.8V405.06C483.098 406.268 483.51 407.443 484.284 408.37L487.164 410.55L747.244 511.55C748.088 511.881 748.987 512.051 749.894 512.05C750.934 512.05 751.967 511.881 752.954 511.55L1013.21 410.55C1014.37 410.119 1015.38 409.362 1016.11 408.37C1016.7 407.368 1017.02 406.224 1017.01 405.06V320.8C1017.15 320.521 1017.23 320.213 1017.23 319.9C1017.23 319.588 1017.15 319.28 1017.01 319C1017.01 318.878 1016.98 318.757 1016.93 318.648C1016.87 318.538 1016.79 318.443 1016.69 318.37V318.15C1016.4 317.497 1016.01 316.887 1015.54 316.34L1014.93 315.84C1014.32 315.379 1013.62 315.04 1012.88 314.84'  stroke-width='6' stroke-miterlimit='6'/></g><filter id='filter0_dddddd_17_2' x='525' y='288' width='450' height='341' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feFlood flood-opacity='0' result='BackgroundImageFix'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='2.76726'/><feGaussianBlur stdDeviation='1.27294'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.030926 0'/><feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow_17_2'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='6.6501'/><feGaussianBlur stdDeviation='3.05905'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0444282 0'/><feBlend mode='normal' in2='effect1_dropShadow_17_2' result='effect2_dropShadow_17_2'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='12.5216'/><feGaussianBlur stdDeviation='5.75991'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.055 0'/><feBlend mode='normal' in2='effect2_dropShadow_17_2' result='effect3_dropShadow_17_2'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='22.3363'/><feGaussianBlur stdDeviation='10.2747'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0655718 0'/><feBlend mode='normal' in2='effect3_dropShadow_17_2' result='effect4_dropShadow_17_2'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='41.7776'/><feGaussianBlur stdDeviation='19.2177'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.079074 0'/><feBlend mode='normal' in2='effect4_dropShadow_17_2' result='effect5_dropShadow_17_2'/><feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/><feOffset dy='100'/><feGaussianBlur stdDeviation='46'/><feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.11 0'/><feBlend mode='normal' in2='effect5_dropShadow_17_2' result='effect6_dropShadow_17_2'/><feBlend mode='normal' in='SourceGraphic' in2='effect6_dropShadow_17_2' result='shape'/></filter><linearGradient id='paint0_linear_17_2' x1='1239' y1='-26.0002' x2='1633.1' y2='1187.11' gradientUnits='userSpaceOnUse'><stop stop-color='#01E7CB'/><stop offset='1' stop-color='#61E66E'/></linearGradient><linearGradient id='paint0_linear_17_3' x1='1239' y1='-26.0002' x2='1633.1' y2='1187.11' gradientUnits='userSpaceOnUse'><stop stop-color='#ffff00'/><stop offset='1' stop-color='#ffcc00'/></linearGradient><clipPath id='clip0_17_2'><rect width='1500' height='1500' fill='white'/></clipPath></defs><style><![CDATA[ .use-gframe { transform-origin:50% 24% } .gpath { stroke: #02FFE1 } .gyellow .gpath { stroke: #ffaa00 } ]]></style></svg>"
        ));
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IWRLD_Name_Service_Metadata).interfaceId;
    }
}
