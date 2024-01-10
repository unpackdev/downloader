// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./Base64.sol";
import "./Strings.sol";


/// @title PuzzleGenerator
/// @notice Provides functionaliy to create mondrian puzzles, svg-representations and metadata
library PuzzleGenerator {

    struct Rect {
        uint x; 
        uint y;
        uint width;
        uint height;
        Color color;
    }
    
    enum Color {
        red,
        blue,
        white,
        yellow,
        black
     }

    struct Traits {
        uint score;
        string dominantColor;
        uint rectangles;
    }

    uint internal constant denominator = 20;
    uint internal constant tolerance = 25;

    function generateMetadata(uint tokenId) public view returns (string memory)
    {   
//        if((tokenId+1) % 512 == 0)
//            return Base64.encode(abi.encodePacked('{"name":"Mondrian puzzle #', Strings.toString(tokenId) ,'", "description":"A (not so) randomly generated and colorful Mondrian Puzzle with a clear likeliness of the Ukranian flag, fully generated and stored on the chain.","image": "data:image/svg+xml;base64,', Base64.encode('<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:v=\"https://vecta.io/nano\" width=\"600\" height=\"400\" stroke-width=\"5\" stroke=\"black\" ><rect x=\"0\" y=\"0\" width=\"600\" height=\"200\" fill=\"blue\" /><rect x=\"0\" y=\"200\" width=\"600\" height=\"200\" fill=\"yellow\" /></svg>'), '", "attributes": [ { "trait_type": "Mondrian Score", "value": "0" },{ "trait_type": "Dominant color", "value": "peace"},{ "trait_type": "Rectangles used", "value":"2" } ]}'));
  
        uint rectsWanted = uint( (random(tokenId) % 10) + 6); //6-16
        Rect[] memory rectangles = generateRectangles(tokenId, rectsWanted, 500, 500);
    
        Traits memory traits = calculateTraits(rectangles);
        string memory json =  Base64.encode(abi.encodePacked('{"name":"Mondrian puzzle #', Strings.toString(tokenId) ,'", "description":"A randomly generated and colorful Mondrian Puzzle, fully generated and stored on the chain.","image": "data:image/svg+xml;base64,', Base64.encode(generateSVG(rectangles)), '", "attributes": [ { "trait_type": "Mondrian Score", "value": "', Strings.toString(traits.score), '" },{ "trait_type": "Dominant color", "value": "', traits.dominantColor, '"},{ "trait_type": "Rectangles used", "value":"', Strings.toString(traits.rectangles), '" } ]}'));

        return json;
    }


    function generateSVG(Rect[] memory rectangles) internal pure returns (bytes memory)
    {
        bytes memory output = abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' xmlns:v='https://vecta.io/nano' width='", Strings.toString(rectangles[0].width), "' height='", Strings.toString(rectangles[0].height), "' stroke-width='5' stroke='black' >");         
        for(uint i = 0; i < rectangles.length; i ++)
        {
            output = abi.encodePacked(output, "<rect x='", Strings.toString(rectangles[i].x), "' y='", Strings.toString(rectangles[i].y), "' width='", Strings.toString(rectangles[i].width), "' height='", Strings.toString(rectangles[i].height), "' fill='", stringFromColor(rectangles[i].color), """' />" );
        }
        return abi.encodePacked(output, "</svg>");        
    }

    function calculateTraits(Rect[] memory rectangles) private pure returns (Traits memory)
    {
        uint small = 99999;
        uint large = 0;        
        uint[] memory colorsUsed = new uint[](5);

        for(uint i = 1; i < rectangles.length; i++)
        {
            uint area = (rectangles[i].width/denominator) * (rectangles[i].height/denominator);
            colorsUsed[uint(rectangles[i].color)] += area;

            if(area < small){
                small = area;
            } else if(area > large){
                large = area;
            }            
        }

        Color dColor = Color.red; //0
        for(uint i = 1; i < colorsUsed.length;i++)
        {
            if(colorsUsed[i] > colorsUsed[uint(dColor)])
                dColor = Color(i);
        }
        return Traits({score: large-small, dominantColor: stringFromColor(dColor), rectangles: rectangles.length-1 });
    }

    function generateRectangles(uint tokenId, uint wantedRects, uint canvas_width, uint canvas_height) private view returns (Rect[] memory)
    {

        Color[12] memory colors = [Color.red, Color.red, Color.red, Color.blue, Color.blue, Color.blue, Color.white, Color.white, Color.yellow, Color.yellow, Color.yellow, Color.black];
        Rect[] memory rectangles = new Rect[](wantedRects+1);
        uint counter = 0;
        uint probability = 5;
        uint seed = (tokenId**wantedRects) ;
        uint numerator = uint(denominator)/(wantedRects/2);        
        
        Rect memory availableRect = Rect({ x:0, y:0, width: canvas_width, height:canvas_height, color: Color.white });
        Rect memory newRect;

        rectangles[counter++] = availableRect;

        while (counter < rectangles.length && (availableRect.width >= tolerance && availableRect.height >= tolerance))
        {
            seed += counter;            
            uint fraction = (random(seed) % numerator) +1; 
            
            Color newColor = colors[random(seed) % colors.length];                
            while (newColor == availableRect.color )
                newColor = colors[random(++seed) % colors.length];
 
            if((random(seed) % 10) > probability) //Vertical 
            {
                probability = probability+2;
                uint new_width = (canvas_width * fraction) / denominator;
                                
                while(new_width >= availableRect.width)
                {
                    fraction = (random(++seed) % numerator) + 1;
                    new_width = (canvas_width * fraction) / denominator;
                }

                uint newX = availableRect.x;
                uint deltaX = availableRect.x + new_width;
                if((random(++seed) % 10) >= 5 ){
                    newX = availableRect.width + availableRect.x - new_width;
                    deltaX = availableRect.x;
                }

                newRect = Rect({x: newX, y: availableRect.y, width: new_width, height: availableRect.height, color: newColor});
                rectangles[counter++] = newRect;
                availableRect = Rect({x: deltaX, y: availableRect.y, width: availableRect.width - newRect.width, height: availableRect.height, color: newRect.color});
            }
            else //Horizontal
            {
                if(probability > 2)
                    probability = probability - 2;

                uint new_height = (canvas_height * fraction) / denominator;

                while(new_height >= availableRect.height)
                {
                    fraction = (random(++seed)% numerator) +1;
                    new_height = (canvas_height * fraction) / denominator;
                }        

                uint newY = availableRect.y;
                uint deltaY = availableRect.y + new_height;
                if((random(++seed) % 10) < 5){
                    newY = availableRect.height + availableRect.y - new_height;
                    deltaY = availableRect.y;
                }

                newRect = Rect({x: availableRect.x, y: newY, width: availableRect.width, height: new_height, color: newColor});
                rectangles[counter++] = newRect;
                availableRect = Rect({x: availableRect.x, y: deltaY, width: availableRect.width, height: availableRect.height-new_height, color: newRect.color});
            }
        }            
        return rectangles;
    }


    function random(uint seed) private view returns (uint) {
        return uint(keccak256(abi.encodePacked( block.difficulty, seed)));
    }
    
    function stringFromColor(Color color) private pure returns (string memory) {
        if(color == Color.red)
            return "red";
        else if(color == Color.blue)
            return "blue";
        else if(color == Color.white)
            return "white";
        else if(color == Color.yellow)
            return "yellow";
        else if(color == Color.black)
            return "black";
        else
            return "green";
    }
}