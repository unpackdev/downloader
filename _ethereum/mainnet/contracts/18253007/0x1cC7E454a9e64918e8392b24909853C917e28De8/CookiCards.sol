// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Base64.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ICookiStructs.sol";

contract CookiCards is Ownable, ICookiStructs {
    uint256 public totalSupply;
    uint256 public fee;

    string[] public backgroundColours;
    DoubleString[] public faceColours;
    TripleString[] public hatColours;
    DoubleString[] public neutralColours;

    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );

    constructor() {
        _init();
        fee = 0.001 ether;
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        (bool success, ) = (msg.sender).call{value: address(this).balance }("");
        require(success);
    }

    function mint() external payable {
        require(msg.value >= fee);
        _mint(msg.sender);
    }

    function mintTo(address _to) external onlyOwner {
        _mint(_to);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function _mint(address _to) internal {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.number, _to, totalSupply)));
        
        string memory data = _generateSVG(
            backgroundColours[seed % backgroundColours.length],
            faceColours[seed % faceColours.length],
            hatColours[seed % hatColours.length],
            neutralColours[seed % neutralColours.length]
        );

        totalSupply++;
        emit ethscriptions_protocol_CreateEthscription(_to, string.concat('data:image/svg+xml;base64,', Base64.encode(bytes(data))));
    }

    function _generateSVG(
        string memory _backgroundColour,
        DoubleString memory _faceColours,
        TripleString memory _hatColours,
        DoubleString memory _neutralColours
    ) internal view returns (string memory) {
        string memory svgHTML0 = string.concat('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 240 240"><style id="', Strings.toString(totalSupply), '"/><rect width="100%" height="100%" fill="', _backgroundColour, '" /><polygon points="200,160 200,70 180,70 180,60 60,60 60,160" fill="', _hatColours.light, '"/><rect width="10.1" height="10" x="20" y="170" fill="', _faceColours.dark, '"/><rect width="10" height="10.1" x="40" y="150" fill="', _faceColours.dark);
        svgHTML0 = string.concat(svgHTML0, '"/><polygon points="30,160 50,160 50,180 60,180 60,190 70,190 70,180 80,180 80,200 50,200 50,190 40,190 40,180 30,180" fill="', _neutralColours.dark,'"/><polygon points="70,180 70,190 60,190 60,180 50,180 50,160 60,160 60,150 70,150" fill="', _neutralColours.light, '"/><rect width="10" height="10" x="60" y="170" fill="', _faceColours.dark, '"/><rect width="10" height="10" x="60" y="160" fill="', _faceColours.light);
        
        string memory svgHTML1 = string.concat('"/><rect width="10.1" height="10.1" x="59.95" y="229.95" fill="', _faceColours.dark, '"/><polygon points="70,240 170,240 170,160 70,160 70,180 80,180 80,220 70,220" fill="', _neutralColours.light, '"/><polygon points="90,210 90,200 80,200 80,220 60,220 60,240 50,240 50,230 70,230 70,210" fill="', _neutralColours.dark,'"/><rect width="10" height="10" x="110" y="220" fill="', _faceColours.dark);
        svgHTML1 = string.concat(svgHTML1, '"/><polygon points="90,210 110,210 110,230 100,230 100,220 90,220" fill="', _neutralColours.dark, '"/><polygon points="110,220 170,220 170,200 180,200 180,170 110,170 110,180 100,180 100,200 110,200" fill="', _faceColours.light, '"/><polygon points="120,220 150,220 150,230 140,230 140,240 130,240 130,230 120,230" fill="', _neutralColours.dark, '"/><rect width="10" height="10" x="120" y="200" fill="', _neutralColours.dark);
        
        string memory svgHTML2 = string.concat('"/><polygon points="130,210 130,200 140,200 140,220 150,220 150,210" fill="', _faceColours.dark, '"/><rect width="10.1" height="10" x="179.9" y="230" fill="', _faceColours.dark, '"/><polygon points="150,220 150,210 170,210 170,240 180,240 180,220" fill="', _neutralColours.dark, '"/><rect width="10" height="10" x="160" y="200" fill="', _faceColours.dark);
        svgHTML2 = string.concat(svgHTML2, '"/><polygon points="170,200 170,210 180,210 180,180 160,180 160,160 130,160 130,170 200,170 200,70 190,70 190,90 210,90 210,120 190,120 190,150 210,150 210,180 190,180 190,200" fill="', _neutralColours.dark, '"/><rect width="20.1" height="30.1" x="59.95" y="89.95" fill="', _hatColours.medium, '"/><polygon points="59,120 59,141 90,141 90,130 110,130 110,110 140,110 140,130 170,130 170,120 90,120 90,100 100,100 100,60 90,60 90,90 80,90 80,110 70,110 70,120" fill="', _hatColours.dark, '"/><polygon points="50,160 50,90 60,90 60,140 100,140 100,180 90,180 90,160 120,160 120,150 80,150 80,160 70,160 70,150 60,150 60,160" fill="', _neutralColours.dark);
        
        string memory svgHTML3 = string.concat('"/><rect width="20.1" height="10.1" x="79.95" y="149.95" fill="', _faceColours.dark, '"/><rect width="20" height="10.1" x="110" y="159.95" fill="', _faceColours.dark, '"/><polygon points="130,180 140,180 140,190 150,190 150,180 160,180 160,170 130,170" fill="', _faceColours.dark, '"/><rect width="10" height="10.1" x="50" y="79.95" fill="', _hatColours.dark);
        svgHTML3 = string.concat(svgHTML3, '"/><rect width="10.1" height="10.1" x="59.95" y="69.95" fill="', _neutralColours.dark, '"/><rect width="10.1" height="10.1" x="59.95" y="59.95" fill="', _hatColours.dark, '"/><rect width="50" height="20" x="90" y="40" fill="', _hatColours.dark, '"/><rect width="20.1" height="10" x="69.95" y="50" fill="', _neutralColours.dark);
        
        string memory svgHTML4 = string.concat('"/><rect width="10" height="10" x="90" y="50" fill="', _hatColours.medium, '"/><rect width="30" height="10" x="100" y="40" fill="', _neutralColours.dark, '"/><rect width="10" height="20" x="160" y="50" fill="', _hatColours.dark, '"/><rect width="20.1" height="10" x="139.95" y="50" fill="', _neutralColours.dark);
        svgHTML4 = string.concat(svgHTML4, '"/><rect width="10.1" height="10" x="169.95" y="60" fill="', _neutralColours.dark, '"/><rect width="10.1" height="20" x="179.95" y="60" fill="', _hatColours.dark, '"/><rect width="10.1" height="10.1" x="189.95" y="89.95" fill="', _hatColours.dark, '"/><rect width="20.1" height="10" x="169.95" y="130" fill="', _hatColours.dark);
        
        return string.concat(svgHTML0, svgHTML1, svgHTML2, svgHTML3, svgHTML4, '"/><polygon points="160,60 150,60 150,120 140,120 140,100 160,100" fill="', _hatColours.medium, '"/><polygon points="100,130 90,130 90,140 120,140 120,160 200,160 200,170 160,170 160,150 100,150" fill="', _hatColours.medium, '"/></svg>');
    }

    function _init() internal {
        _storeBackgroundColours();
        _storeFaceColours();
        _storeHatColours();
        _storeNeutralColours();
    }

    function _storeBackgroundColours() internal {
        backgroundColours.push("#fff8dc");
        backgroundColours.push("#dbc9c9");
        backgroundColours.push("#84b4d0");
        backgroundColours.push("#d0a7c7");
        backgroundColours.push("#80ebeb");
        backgroundColours.push("#dee5e5");
        backgroundColours.push("#efcd76");
        backgroundColours.push("#ed8f90");
        backgroundColours.push("#747470");
        backgroundColours.push("#69a975");
        backgroundColours.push("#8467a9");
        backgroundColours.push("#df6cc3");
        backgroundColours.push("#f18c51");
        backgroundColours.push("#1fc29f");
        backgroundColours.push("#79916f");
        backgroundColours.push("#cf5108");
        backgroundColours.push("#a11C06");
        backgroundColours.push("#280575");
        backgroundColours.push("#348505");
        backgroundColours.push("#b20560");
        backgroundColours.push("#057eb2");
        backgroundColours.push("#3F3F3F");
        backgroundColours.push("#DCB40E");
    }

    function _storeFaceColours() internal {
        DoubleString memory _faceColours0 = DoubleString({
            light: "#896bef",
            dark: "#2d0ba7"
        });
        DoubleString memory _faceColours1 = DoubleString({
            light: "#68bee1",
            dark: "#0b7ba7"
        });
        DoubleString memory _faceColours2 = DoubleString({
            light: "#c8a968",
            dark: "#775303"
        });
        DoubleString memory _faceColours3 = DoubleString({
            light: "#6475b8",
            dark: "#082084"
        });
        DoubleString memory _faceColours4 = DoubleString({
            light: "#9d95a5",
            dark: "#48444d"
        });
        DoubleString memory _faceColours5 = DoubleString({
            light: "#499568",
            dark: "#025524"
        });
        DoubleString memory _faceColours6 = DoubleString({
            light: "#af60a2",
            dark: "#5b014a"
        });
        DoubleString memory _faceColours7 = DoubleString({
            light: "#eb885e",
            dark: "#8e2c02"
        });
        DoubleString memory _faceColours8 = DoubleString({
            light: "#d55d6b",
            dark: "#8e0214"
        });
        DoubleString memory _faceColours9 = DoubleString({
            light: "#ac74df",
            dark: "#500095"
        });
        DoubleString memory _faceColours10 = DoubleString({
            light: "#e371b3",
            dark: "#99085d"
        });
        DoubleString memory _faceColours11 = DoubleString({
            light: "#71a59a",
            dark: "#044d41"
        });
        DoubleString memory _faceColours12 = DoubleString({
            light: "#f4d963",
            dark: "#b99500"
        });

        faceColours.push(_faceColours0);
        faceColours.push(_faceColours1);
        faceColours.push(_faceColours2);
        faceColours.push(_faceColours3);
        faceColours.push(_faceColours4);
        faceColours.push(_faceColours5);
        faceColours.push(_faceColours6);
        faceColours.push(_faceColours7);
        faceColours.push(_faceColours8);
        faceColours.push(_faceColours9);
        faceColours.push(_faceColours10);
        faceColours.push(_faceColours11);
        faceColours.push(_faceColours12);
    }

    function _storeHatColours() internal {
        TripleString memory _hatColours0 = TripleString({
            light: "#f8869d",
            medium: "#dc143c",
            dark: "#740e23"
        });
        TripleString memory _hatColours1 = TripleString({
            light: "#635ab5",
            medium: "#2717ed",
            dark: "#100880"
        });
        TripleString memory _hatColours2 = TripleString({
            light: "#e576ed",
            medium: "#e216f1",
            dark: "#870891"
        });
        TripleString memory _hatColours3 = TripleString({
            light: "#79e178",
            medium: "#0eb80c",
            dark: "#025d01"
        });
        TripleString memory _hatColours4 = TripleString({
            light: "#e39f4f",
            medium: "#dc7a05",
            dark: "#a35903"
        });
        TripleString memory _hatColours5 = TripleString({
            light: "#5acfea",
            medium: "#05b4d5",
            dark: "#03819a"
        });
        TripleString memory _hatColours6 = TripleString({
            light: "#69dfa0",
            medium: "#13cc69",
            dark: "#008c3e"
        });
        TripleString memory _hatColours7 = TripleString({
            light: "#a5a5a8",
            medium: "#6f6f73",
            dark: "#3d3d3f"
        });
        TripleString memory _hatColours8 = TripleString({
            light: "#a55454",
            medium: "#af0c0c",
            dark: "#610303"
        });
        TripleString memory _hatColours9 = TripleString({
            light: "#745473",
            medium: "#9b0297",
            dark: "#4d004b"
        });
        TripleString memory _hatColours10 = TripleString({
            light: "#f4d963",
            medium: "#f8cb04",
            dark: "#c19C00"
        });

        hatColours.push(_hatColours0);
        hatColours.push(_hatColours1);
        hatColours.push(_hatColours2);
        hatColours.push(_hatColours3);
        hatColours.push(_hatColours4);
        hatColours.push(_hatColours5);
        hatColours.push(_hatColours6);
        hatColours.push(_hatColours7);
        hatColours.push(_hatColours8);
        hatColours.push(_hatColours9);
        hatColours.push(_hatColours10);
    }

    function _storeNeutralColours() internal {
        DoubleString memory _neutralColours0 = DoubleString({
            light: "#cfc497",
            dark: "#000000"
        });
        DoubleString memory _neutralColours1 = DoubleString({
            light: "#969176",
            dark: "#000000"
        });
        DoubleString memory _neutralColours2 = DoubleString({
            light: "#756c59",
            dark: "#000000"
        });

        neutralColours.push(_neutralColours0);
        neutralColours.push(_neutralColours1);
        neutralColours.push(_neutralColours2);
    }
}