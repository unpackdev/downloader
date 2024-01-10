// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Strings.sol";
import "./Base64.sol";


library CalcLib {
    struct ColorScheme {
        string[2] gradient1;
        string[2] gradient2;
        string[2] gradient3;
        string[2] gradient4;
        string buttonBackground;
        string borderStrip;
        string buttonText;
        string screenText;
        string screen;
        string ownerText;

    }

    string internal constant svgStart = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 550 760">';
    
    string internal constant svgButtons = ' <g stroke="#303133" stroke-width="5" fill="url(#Gradient2)" > <rect onclick="handleNumber(1)" rx="7" x="50" y="530" width="80" height="80"/> <rect onclick="handleNumber(2)" rx="7" x="150" y="530" width="80" height="80"/> <rect onclick="handleNumber(3)" rx="7" x="250" y="530" width="80" height="80"/> <rect onclick="handleNumber(4)" rx="7" x="50" y="430" width="80" height="80"/> <rect onclick="handleNumber(5)" rx="7" x="150" y="430" width="80" height="80"/> <rect onclick="handleNumber(6)" rx="7" x="250" y="430" width="80" height="80"/> <rect onclick="handleNumber(7)" rx="7" x="50" y="330" width="80" height="80"/> <rect onclick="handleNumber(8)" rx="7" x="150" y="330" width="80" height="80"/> <rect onclick="handleNumber(9)" rx="7" x="250" y="330" width="80" height="80"/> <rect onclick="handleNumber(0)" rx="7" x="50" y="630" width="80" height="80"/> <rect onclick="handleNumber(symbols.dec)" rx="7" x="150" y="630" width="80" height="80"/> //. <rect onclick="handleOp(add, symbols.add)" rx="7" x="350" y="530" width="150" height="80"/> //+ <rect onclick="handleOp(sub, symbols.sub)" rx="7" x="350" y="430" width="150" height="80"/> //- <rect onclick="handleOp(mul, symbols.mul)" rx="7" x="350" y="330" width="150" height="80"/> //x <rect onclick="handleOp(div, symbols.div)" rx="7" x="350" y="230" width="150" height="80"/> // / <rect onclick="handleOp(mod, symbols.mod)" rx="7" x="150" y="230" width="80" height="80"/> <rect onclick="handleOp(pow, symbols.pow)" rx="7" x="250" y="230" width="80" height="80"/> <rect onclick="clearScreen()" fill="url(#Gradient3)" rx="7" x="50" y="230" width="80" height="80"/> <rect onclick="equals()" fill="url(#Gradient1)" rx="7" x="250" y="630" width="250" height="80"/> </g >';
    
    string internal constant svgButtonText = '<g class="button"> <text onclick="equals()" stroke="none" x="360" y="685">=</text> <text onclick="clearScreen()" x="71" y="285">C</text> <text onclick="handleNumber(1)" x="75" y="585">1</text> <text onclick="handleNumber(2)" x="175" y="585">2</text> <text onclick="handleNumber(3)" x="275" y="585">3</text> <text onclick="handleNumber(4)" x="75" y="485">4</text> <text onclick="handleNumber(5)" x="175" y="485">5</text> <text onclick="handleNumber(6)" x="275" y="485">6</text> <text onclick="handleNumber(7)" x="75" y="385">7</text> <text onclick="handleNumber(8)" x="175" y="385">8</text> <text onclick="handleNumber(9)" x="275" y="385">9</text> <text onclick="handleNumber(0)" x="75" y="685">0</text> <text onclick="handleNumber(symbols.dec)" x="183" y="674">.</text> <text onclick="handleOp(add, symbols.add)" x="408" y="585">+</text> <text onclick="handleOp(sub, symbols.sub)" x="415" y="481">-</text> <text onclick="handleOp(mul, symbols.mul)" x="410" y="380">x</text> <text onclick="handleOp(div, symbols.div)" x="410" y="286">/</text> <text onclick="handleOp(mod, symbols.mod)" x="165" y="285">%</text> <text onclick="handleOp(pow, symbols.pow)" x="275" y="293">^</text> </g>';
    string internal constant svgEnd = '<script type="text/javascript"><![CDATA[ var symbols={mul:"x",div:"/",mod:"%",sub:"-",add:"+",dec:".",pow:"^"},screenLarge=document.getElementById("screenLarge"),screenTop=document.getElementById("screenTop"),screenTiny=document.getElementById("screenTiny");function add(e,t){var n=e+t;return sizeResult(n),n}function sub(e,t){var n=e-t;return sizeResult(n),n}function mul(e,t){var n=e*t;return sizeResult(n),n}function div(e,t){var n=e/t;return sizeResult(n),n}function mod(e,t){var n=e%t;return sizeResult(n),n}function pow(e,t){var n=e**t;return sizeResult(n),n}function equals(){if(0==Number(secondNum)&&operationSym==symbols.div)return screenLarge.textContent="error",void(readyToClear=!0);firstNum.length+secondNum.length<19?screenTop.textContent=firstNum+" "+operationSym+" "+secondNum+" =":firstNum.length<19?(secondNum=secondNum.slice(0,19-firstNum.length),screenTop.textContent=firstNum+" "+operationSym+" "+secondNum+"... ="):screenTop.textContent=firstNum.slice(0,20)+"... =",firstNum=operation(Number(firstNum),Number(secondNum)).toString(),readyToClear=!0}function sizeResult(e){if(e.toString().length<13)screenLarge.setAttribute("class","large"),screenLarge.textContent=e.toString();else{if(!(e.toString().length<24))return screenLarge.textContent=e.toString().slice(0,24)+"...",void(screenTiny.textContent="too large");screenLarge.setAttribute("class","small"),screenLarge.textContent=e.toString()}}function clearScreen(){screenLarge.textContent="",screenTop.textContent="",numCounter=1,firstNum="",secondNum="",operation=null,operationSym="",screenTiny.textContent="",readyToClear=!1}function handleNumber(e){if(readyToClear&&clearScreen(),1==numCounter)if(firstNum.length<13)screenLarge.setAttribute("class","large"),screenLarge.textContent=firstNum+e.toString(),firstNum+=e.toString();else{if(!(firstNum.length<24))return void(screenTiny.textContent="too large");screenLarge.setAttribute("class","small"),screenLarge.textContent=firstNum+e.toString(),firstNum+=e.toString()}else if(secondNum.length<13)screenLarge.setAttribute("class","large"),screenLarge.textContent=secondNum+e.toString(),secondNum+=e.toString();else{if(!(secondNum.length<24))return void(screenTiny.textContent="too large");screenLarge.setAttribute("class","small"),screenLarge.textContent=secondNum+e.toString(),secondNum+=e.toString()}}function handleOp(e,t){secondNum="",screenLarge.textContent="",operationSym=t.toString(),firstNum.length<19?screenTop.textContent=firstNum+" "+operationSym:screenTop.textContent=firstNum.slice(0,20)+"... =",operation=e,numCounter=2}numCounter=1,firstNum="",secondNum="",operation=null,operationSym="",readyToClear=!1; ]]></script> </svg>';


    function generateTokenURI(address owner, uint id, uint schemeIndex, ColorScheme memory scheme, string memory frontEnd) public pure returns(string memory) {

        string memory imageUrl = base64ImageUrl(owner, id, scheme);
        return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              "Calculator #",
                              Strings.toString(id),
                              '", "description":',
                              '"A Fully working, completely on chain calculator. To use, simply copy the image url and paste it in a web browser. Or, visit our [Official Website](',
                              frontEnd,
                              ")",
                              '", "external_url":"',
                              frontEnd,
                              '", "attributes": [{"trait_type": "Color Scheme", "value":"',
                              Strings.toString(schemeIndex),
                              '"}], "owner":"',
                              Strings.toHexString(uint160(owner), 20),
                              '", "image": "',
                              imageUrl,
                              '"}'
                          )
                        )
                    )
              )
          );

    }


    function base64ImageUrl(address owner, uint id, ColorScheme memory scheme) public pure returns (string memory) {
        string memory ownerId = OwnerandIdText(owner, id, scheme.ownerText);
        string memory gradients = getGradients(scheme);
        string memory background = getBackground(scheme);
        string memory screenText = getScreenText(scheme);
        string memory styles = getStyle(scheme);

        string memory svgBase64 = Base64.encode(abi.encodePacked(svgStart, styles, gradients, background, svgButtons, screenText, svgButtonText, ownerId, svgEnd));
        return string(abi.encodePacked("data:image/svg+xml;base64,",svgBase64));

    }



    function OwnerandIdText(address owner, uint id, string memory color) public pure returns (string memory){
        string memory _owner = Strings.toHexString(uint160(owner), 20);
        string memory _id = Strings.toString(id);

        return string(abi.encodePacked('<text fill="#',
        color,
        '" x="190" y="743" class="metadata">', 
        "Owner: ", 
        _owner, 
        '</text> <text fill="#d8e1e0" x="30" y="743" class="metadata">', 
        _id, 
        "/10000", 
        "</text>"));



    }

    function getGradients(ColorScheme memory scheme) public pure returns (string memory) {
        string memory first = '<linearGradient id="';
        string memory second = '" x1="1" x2="0" y1="0" y2="0"> <stop offset="0%" stop-color="#';
        string memory third = '"/> <stop offset="100%" stop-color="#';
        string memory fourth = '" /> </linearGradient>';

        string memory grad1 = string(abi.encodePacked(
            first, 
            "Gradient1",  
            second, 
            scheme.gradient1[0],
            third,
            scheme.gradient1[1],
            fourth
            ));
        string memory grad2 = string(abi.encodePacked(
            first, 
            "Gradient2",  
            second, 
            scheme.gradient2[0],
            third,
            scheme.gradient2[1],
            fourth
            ));
        string memory grad3 = string(abi.encodePacked(
            first, 
            "Gradient3",  
            second, 
            scheme.gradient3[0],
            third,
            scheme.gradient3[1],
            fourth
            ));
        string memory grad4 = string(abi.encodePacked(
            first, 
            "Gradient4",  
            second, 
            scheme.gradient4[0],
            third,
            scheme.gradient4[1],
            fourth
            ));

        return string(abi.encodePacked(grad1, grad2, grad3, grad4));

    }

    function getBackground(ColorScheme memory scheme) public pure returns (string memory) {
        string memory first = '<g  stroke="#';
        string memory second = '" stroke-width="3" > <rect id="border" fill="url(#Gradient4)" rx="7" x="0" y="0" width="550" height="760"/> <rect class="buttonBackground"   rx="7" x="30" y="30" width="490" height="700"/> <rect id="screenBorder" rx="7" fill="url(#Gradient2)" x="45" y="50" width="460" height="150"/> <rect class="screen"  rx="7" x="65" y="70" width="420" height="110"/> <rect rx="7" stroke-width="5" fill="none" x="10" y="10" width="530" height="740"/> </g>';
    

        return string(abi.encodePacked(
            first, 
            scheme.borderStrip,
            second

            ));

    }

    function getScreenText(ColorScheme memory scheme) public pure returns(string memory) {
        string memory first = '<g fill= "#'; 
        string memory second = '"> <text id="screenLarge" x="70" y="160"></text> <text id="screenTop" x="70" y="105" class="light"></text> <text id="screenTiny" x="430" y="170" class="tiny"></text> </g >';
        return string(abi.encodePacked(first, scheme.screenText, second));

    }

    function getStyle(ColorScheme memory scheme) public pure returns(string memory ) {
        return string(abi.encodePacked(
            '<style> .light { font: italic 30px sans-serif; } .tiny { font: 8px sans-serif;  } .large { font: bold 50px sans-serif; } .small { font: bold 30px sans-serif; } .button { font: bold 50px sans-serif; fill: #',
            scheme.buttonText, 
            '} .metadata{ font: bold 12px sans-serif; fill: #', 
            scheme.ownerText, 
            ' } .buttonBackground{fill: #', 
            scheme.buttonBackground,
            '} .screen{fill: #',
            scheme.screen,
            '} .borderStrip{stroke: #',
            scheme.borderStrip,
            '} </style>'
            ));
            
        
    }


}

