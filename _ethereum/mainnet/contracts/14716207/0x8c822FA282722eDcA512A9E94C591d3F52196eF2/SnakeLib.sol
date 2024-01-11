// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./Strings.sol";
import "./Base64.sol";


library SnakeLib {

    struct ColorScheme {
        string metadata;
        string title;
        string start;
        string directions;
        string score;
        string background;
        string map;
        string food;
        string snake;
    }

    struct SnakeParams {
        address _owner;
        uint _id;
        uint _schemeIndex;
        ColorScheme _scheme;
        string _frontEnd;
    }

    string internal constant svgStart = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1000 1000">';

    string internal constant svgMid = '<g stroke="#000" > <rect class="background" x="0" y="0" rx="15" width="1000" height="1000"/> <rect class="map" x="200" y="200" width="600" height="600"/> </g> <text y="120" x="50%" text-anchor="middle" class="title">snake</text> <text id="startText" x="50%" y="600" text-anchor="middle" class="start" ></text> <text id="directions" x="50%" y="650" text-anchor="middle" class="directions" ></text> <text x="900" y="250" text-anchor="middle" class="score" > Score:</text> <text id="scoreCounter" x="830" y="300" class="score" ></text> <text  x="900" y="550" text-anchor="middle" class="highScore" > high scores:</text> <text id="hs1" x="830" y="600" class="score" ></text> <text id="hs2" x="830" y="650" class="score" ></text> <text id="hs3" x="830" y="700" class="score" ></text> <text id="hs4" x="830" y="750" class="score" ></text> <text id="hs5" x="830" y="800" class="score" ></text>';
    
    string internal constant svgEnd = '<rect id="snake" class="snake" x="500" y="500" width="20" height="20"/> <rect id="food" class="food" x="-50" y="-50" width="20" height="20"/> <script type="text/javascript"><![CDATA[var foodCoords,KEY={w:87,a:65,s:83,d:68,space:32},moveSpeed=20,score=0,highScores=[],snakeHead=document.getElementById("snake"),svg=document.getElementsByTagName("svg")[0],startText=document.getElementById("startText"),directions=document.getElementById("directions"),food=document.getElementById("food"),scoreCounter=document.getElementById("scoreCounter");startText.textContent="press space to start",directions.textContent="then w, a, s, d";var snakeBody=[];isTurning=!1,isRunning=!1;var currentDirection="right";document.documentElement.addEventListener("keydown",e=>{handleInput(e)},!1);var timerFunction=null;function startGame(){null==timerFunction&&(timerFunction=setInterval(go,80),random_food(),startText.textContent="",directions.textContent="",scoreCounter.textContent=score,isRunning=!0)}function updateScore(){score+=1,scoreCounter.textContent=score}function random_food(){var e=Math.floor(30*Math.random()),t=Math.floor(30*Math.random());e+200>780&&(e=780),t+200>780&&(t=780),foodCoords=[20*e+200,20*t+200],food.setAttribute("x",20*e+200),food.setAttribute("y",20*t+200)}function updateHighScore(){var e=highScores.length;if(score<=highScores[e-1]||highScores.includes(score))return;e>=5&&highScores.pop();let t=highScores.findIndex(e=>score>e);highScores.splice(t,0,score);for(var n=1;n<=highScores.length;n++){document.getElementById(`hs${n}`).textContent=highScores[n-1]}}function reset(){if(1!=isRunning){document.documentElement.removeEventListener("keydown",function(e){handleInput(e)},!1),clearInterval(timerFunction),timerFunction=null,isTurning=!1;for(var e=0;e<snakeBody.length;e++)svg.removeChild(snakeBody[e]);snakeBody=[],scoreCounter.textContent=score=0,food.setAttribute("x",-50),food.setAttribute("y",-50),startText.textContent="press space to start",directions.textContent="then w, a, s, d",snakeHead.setAttribute("x",500),snakeHead.setAttribute("y",500),document.documentElement.addEventListener("keydown",function(e){handleInput(e)},!1)}}function appendSnake(){var e=snakeHead.cloneNode(!0),t=snakeBody.length;t>0&&(e.setAttribute("x",1*snakeBody[t-1].getAttribute("x")),e.setAttribute("y",1*snakeBody[t-1].getAttribute("y"))),snakeBody.push(e),svg.appendChild(e)}function updateSnake(){for(var e=1*snakeHead.getAttribute("x"),t=1*snakeHead.getAttribute("y"),n=snakeBody.length-1;n>=0;n--)if(0==n)snakeBody[0].setAttribute("x",e),snakeBody[0].setAttribute("y",t);else{var o=1*snakeBody[n-1].getAttribute("x"),r=1*snakeBody[n-1].getAttribute("y");if(snakeBody[n].setAttribute("x",o),snakeBody[n].setAttribute("y",r),o==e&&r==t){isRunning=!1,updateHighScore(),reset();break}}isTurning=!1}function go(){var e=1*snakeHead.getAttribute("x"),t=1*snakeHead.getAttribute("y");if(updateSnake(),1==isRunning)switch(currentDirection){case"right":snakeHead.setAttribute("x",e+=moveSpeed);break;case"left":snakeHead.setAttribute("x",e-=moveSpeed);break;case"up":snakeHead.setAttribute("y",t-=moveSpeed);break;case"down":snakeHead.setAttribute("y",t+=moveSpeed)}(e<=180||e>=800||t<=180||t>=800)&&(isRunning=!1,updateHighScore(),reset()),e==foodCoords[0]&&t==foodCoords[1]&&(random_food(),updateScore(),appendSnake())}function handleInput(e){if(e.keyCode==KEY.space&&startGame(),1!=isTurning)switch(isTurning=!0,e.keyCode){case KEY.w:"down"!=currentDirection&&(currentDirection="up");break;case KEY.s:"up"!=currentDirection&&(currentDirection="down");break;case KEY.a:"right"!=currentDirection&&(currentDirection="left");break;case KEY.d:"left"!=currentDirection&&(currentDirection="right")}}]]></script> </svg>';


    function base64ImageUrl(SnakeParams memory snakeParams) internal pure returns (string memory) {
        string memory metadata = getMetaData(snakeParams._owner, snakeParams._id);
        string memory styles = getStyle(snakeParams._scheme);

        string memory svg = Base64.encode(abi.encodePacked(
            svgStart, 
            styles, 
            svgMid, 
            metadata, 
            svgEnd 
            ));

        return string(abi.encodePacked("data:image/svg+xml;base64,",svg)); 

    }


    

    function getMetaData(address owner, uint id) internal pure returns (string memory){
        string memory _owner = Strings.toHexString(uint160(owner), 20);
        string memory _id = Strings.toString(id);

        return string(abi.encodePacked(
        '<g class="metadata"> <text x="50" y="900" >owner: ', 
        _owner, 
        '</text> <text x="50" y="950">',
        _id, 
        '/10000</text> </g>'
        ));



    }
    function getStyle(ColorScheme memory scheme) internal pure returns(string memory ) {


        bytes memory style1 = abi.encodePacked(
            '<style> .metadata { font:  30px Courier; fill: #',
            scheme.metadata, 
            ' } .title { font:  80px Courier; fill: #', 
            scheme.title, 
            ' } .start {font: 35px Courier; fill-opacity: .70; fill: #', 
            scheme.start,
            '} .directions {font: italic 30px Courier; fill-opacity: .70; fill: #',
            scheme.directions,
            ' } .score {font: 40px Courier; fill: #',
            scheme.score);
        
        bytes memory style2 = abi.encodePacked( 
            style1,
            '} .highScore {font: 25px Courier; fill: #',
            scheme.score,
            '} .background {fill: #',
            scheme.background,
            '} .map {fill: #',
            scheme.map,
            '} .food {stroke: #000; fill: #',
            scheme.food,
            '} .snake{stroke: #000; fill: #',
            scheme.snake,
            '} </style>'
            
            );
            return string(style2);


    }


    


    function generateTokenURI(SnakeParams memory snakeParams) internal pure returns(string memory tokenURI) {

        string memory imageUrl = base64ImageUrl(snakeParams);
        string memory base64Html = string(abi.encodePacked(
            'data:text/html;base64,', 
        
            Base64.encode(abi.encodePacked('<!DOCTYPE html> <html><object type="image/svg+xml" data="',
                              imageUrl,
                '" alt="snake"></object></html>'
                ))));

        bytes memory json1 = abi.encodePacked(
            '{"name": "Snake #',
            Strings.toString(snakeParams._id),
            '", "description": "Fully on chain game of Snake. To play, simply copy the image url and paste it in a web browser. Or, visit the [Official Website](',
            snakeParams._frontEnd,
            ') to view and play your games.", "external_url":"',
            snakeParams._frontEnd,
            '", "attributes": [{"trait_type": "Color Scheme", "value":"',
            Strings.toString(snakeParams._schemeIndex),
            '"}], "owner":"'
        );

        bytes memory json2 = abi.encodePacked(
            json1,
            Strings.toHexString(uint160(snakeParams._owner), 20),
            '", "image": "',
            imageUrl,
            '", "animation_url":"',
            base64Html,
            '"}'
            );

        tokenURI = string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(json2)));

    }


}

