// SPDX-License-Identifier: MIT
/*
    MIT License
    Copyright (c) 2023 SomeGuy
*/
pragma solidity ^0.8.19;

error WhenTheTimeIsRight();
error YoureNotTheOwnerHomie();
error GottaUnlockGen1Please();
error ButTheseAintHiddenThough();
error YooooThatTokenIdIsWayTooHigh();
error SorryYouCantAbandonOwnershipToTheZeroAddress();



/*

     ██████   ██████   ██████  ██████  ██████  ██       ██████   ██████ ██   ██ ███████ 
    ██       ██    ██ ██    ██ ██   ██ ██   ██ ██      ██    ██ ██      ██  ██  ██      
    ██   ███ ██    ██ ██    ██ ██   ██ ██████  ██      ██    ██ ██      █████   ███████ 
    ██    ██ ██    ██ ██    ██ ██   ██ ██   ██ ██      ██    ██ ██      ██  ██       ██ 
     ██████   ██████   ██████  ██████  ██████  ███████  ██████   ██████ ██   ██ ███████ 
                                                                                        
                                                                                        
     ██████  ███████ ███    ██        ██                                                
    ██       ██      ████   ██       ███                                                
    ██   ███ █████   ██ ██  ██ █████  ██                                                
    ██    ██ ██      ██  ██ ██        ██                                                
     ██████  ███████ ██   ████        ██

    
    circles and squares
    🟡🟥

    by SomeGuy

*/

contract goodblocksGen1
{
    // gen-1 description
    string private constant Gen1Description = unicode'who said circles and squares cant get along? welcome to gen-1 where these two shapes come together in unique harmony. you know the drill... enjoy the art, explore the code, and dont forget to click around for some extra fun! 😉 🟨🟥🟦';



    /*

        ███████ ████████  ██████  ██████  ███████        
        ██         ██    ██    ██ ██   ██ ██             
        ███████    ██    ██    ██ ██████  █████          
             ██    ██    ██    ██ ██   ██ ██             
        ███████    ██     ██████  ██   ██ ███████        
                                                        
                                                        
        ██████   █████                                   
        ██   ██ ██   ██                                  
        ██   ██ ███████                                  
        ██   ██ ██   ██                                  
        ██████  ██   ██                 
               
                                                        
        ██████  ██       ██████   ██████ ██   ██ ███████ 
        ██   ██ ██      ██    ██ ██      ██  ██  ██      
        ██████  ██      ██    ██ ██      █████   ███████ 
        ██   ██ ██      ██    ██ ██      ██  ██       ██ 
        ██████  ███████  ██████   ██████ ██   ██ ███████

    */

    // contract owner 
    address private ContractOwner;
    // original goodblocks contract
    IGBContract private GBTokenContract = IGBContract(address(0x29B4Ea6B1164C7cd8A3a0a1dc4ad88d1E0589124));
    /* 
        optimization from gen-0 code:
        each bit is a flag for whether or not text should be white or black on the images

        this number:
            00000001111111111100001000000110101000110111100010110000
        replaces these strings in the gen contract for optimization
            string private constant LabelFlags =
            "00000001"  // palette 0 Joy
            "11111111"  // palette 1 Night
            "11000010"  // palette 2 Cosmos
            "00000110"  // palette 3 Earth
            "10100011"  // palette 4 Arctic
            "01111000"  // palette 5 Serenity
            "10110000"; // palette 6 Twilight
    */
    uint256 private constant LabelFlags = 562683776825520;
    // reuse block symmetry weights
    uint256[] private BlockSymmetryWeights = [40,25,15,15,4,1];
    // reuse color group names
    string[7] private ColorGroupNames = ["Joy", "Night", "Cosmos", "Earth", "Arctic", "Serenity", "Twilight"];
    // reuse color group weights
    uint256[] private ColorGroupWeights = [30,10,20,10,25,30,15];
    /* 
        optimization from gen-0 code:
        each uint256 represents a 4-color palette that is mapped to ascii characters

        for example,
        Night 0
            uint256
                1183296175157854577031491632722463825992351302656747456068
            binary (padded to 192 length)
                001100000100001000110000010000100011000001000100001101000011011100110100010000010011010100110110001110010011001000111001010000010100000101000010010001000011001101000100001101010100011001000100
            ascii
                0B0B0D474A56929AABD3D5FD
            color palette
                #0B0B0D #474A56 #929AAB #D3D5FD
    */
    uint256[56] private ColorPalettes = 
    [
        // 0 palette (Joy)        
        1722934404554201348729366417993644954268499892180661388600,
        // ['#FDFF8F','#A8ECE7','#F4BEEE','#D47AE8'],
        1722928418248847460524038327043022431014471111280592240963,
        // ['#FD6F96','#FFEBA1','#95DAC1','#6F69AC'],
        1723125218196464527198646930792784633471438866919854455108,
        // ['#FFDF6B','#FF79CD','#AA2EE6','#23049D'],
        1402738212716665681330154749417641799183811080661356593456,
        // ['#95E1D3','#EAFFD0','#FCE38A','#FF75A0'],
        1723124839644503782921222069990975963319678746178410133809,
        // ['#FFCC29','#F58634','#007965','#00AF91'],
        1403116499037504867228637477972569616281207095664540137028,
        // ['#998CEB','#77E4D4','#B4FE98','#FBF46D'],
        1698509881339924158818218547090721811442225106761431398197,
        // ['#EEEEEE','#77D970','#172774','#FF0075'],
        1181573994293619966810731042752478535937452576456742880307,
        // ['#005F99','#FF449F','#FFF5B7','#00EAD3'],

        // 1 palette (Night)
        1183296175157854577031491632722463825992351302656747456068,
        // ['#0B0B0D','#474A56','#929AAB','#D3D5FD'],
        1182242562556626812122607221338801609399248306075785639732,
        // ['#07031A','#4F8A8B','#B1B493','#FFCB74'],
        1232624496385106213304636376314333012044247519742934988098,
        // ['#2E3A63','#665C84','#71A0A5','#FAB95B'],
        1181572091366904789282201902090920653963139822626228420920,
        // ['#000000','#226089','#4592AF','#E3C4A8'],
        1207816483819194660626624753928186438635106027164195632180,
        // ['#1B1F3A','#53354A','#A64942','#FF7844'],
        1210785733379461822760266649310303341232493204710845920305,
        // ['#1a1a1a','#153B44','#2D6E7E','#C6DE41'],
        1183679297598673735033245276169107883091480197076665910594,
        // ['#0F0A3C','#07456F','#009F9D','#CDFFEB'],
        1206379362946223673176236699366397918327115252264628204592,
        // ['#130026','#801336','#C72C41','#EE4540'],
        
        // 2 palette (Cosmos)
        1206188204395529784504373821286370393680112876317865816376,
        // ['#111D5E','#C70039','#F37121','#C0E218'],
        1181764787452334280973727296291940992808625784402829652801,
        // ['#02383C','#230338','#ED5107','#C70D3A'],
        1181866548967864296392515374823870372305589162777764968501,
        // ['#03C4A1','#C62A88','#590995','#150485'],
        1181578463622937915916884477042913908575131282466401431874,
        // ['#00A8CC','#005082','#000839','#FFA41B'],
        1697354125759019098874587460972843735496947121341899813445,
        // ['#E94560','#0F3460','#16213E','#1A1A2E'],
        1672170482535347701413567349811776693278328217919730758469,
        // ['#D2FAFB','#FE346E','#512B58','#2C003E'],
        1353213864613208291156955180757907990714862673150763807539,
        // ['#706C61','#E1F4F3','#FFFFFF','#333333'],
        1722647039797242987206907486689895518314237453093734396725,
        // ['#FAF7F2','#2BB3C0','#161C2E','#EF6C35'],
        
        // 3 palette (Earth)
        1723125960724730352591241524833495038198492338713211844403,
        // ['#FFFBE9','#E3CAA5','#CEAB93','#AD8B73'],
        1598414277963937531436118304205823216013870508573848846904,
        // ['#A09F57','#C56824','#CFB784','#EADEB8'],
        1696785419003103129465305528958529858836219135706396965187,
        // ['#E3D0B9','#E1BC91','#C19277','#62959C'],
        1697359742326961329795704250533301241360585844664883622452,
        // ['#E9C891','#8A8635','#AE431E','#D06224'],
        1378025605464422021827397574345536902253231127146057185586,
        // ['#83B582','#D6E4AA','#FFFFC5','#F0DD92'],
        1255133030464834789817026233978878414701123122015613568567,
        // ['#303E27','#B4BB72','#E7EAA8','#F6FAF7'],
        1599180132596406893561285739937078139222444185901121812786,
        // ['#A8896C','#F1E8A7','#AED09E','#61B292'],
        1721401160781475903301032372806804394112790122319723115573,
        // ['#F4DFBA','#EEC373','#CA965C','#876445'],
        
        // 4 palette (Arctic)
        1279850479717986101566374421011898284803750609483886642756,
        // ['#42C2FF','#85F4FF','#B8FFF9','#EFFFFD'],
        1697265072171141542916534444934787077291477130161358844978,
        // ['#E8F0F2','#A2DBFA','#39A2DB','#053742'],
        1257145528564464104373930541022632732747621545894209603142,
        // ['#3E64FF','#5EDFFF','#B2FCFF','#ECFCFF'],
        1672074708871527899905595150760089445681629758932940633666,
        // ['#D1FFFA','#4AA9AF','#3E31AE','#1C226B'],
        1721689224238219033220141417024881005610968517418405740857,
        // ['#F7F3F3','#C1EAF2','#5CC2F2','#191BA9'],
        1721306100353001166844721355424130832848268931432162083893,
        // ['#F3F3F3','#303841','#3A4750','#2185D5'],
        1353789677333435717167229733400735324241612031748483466819,
        // ['#769FCD','#B9D7EA','#D6E6F2','#F7FBFC'],
        1257049769492558230805482258810392444115501509870169966134,
        // ['#3D6CB9','#00D1FF','#00FFF0','#FAFAF6'],
        
        // 5 palette (Serenity)
        1403121739988174702800583195012373711618086044131908601414,
        // ['#99FEFF','#94DAFF','#94B3FD','#B983FF'],
        1696972117005731040492347755183146534302783978509605028674,
        // ['#E5707E','#E6B566','#E8E9A1','#A3DDCB'],
        1329461281397530506280402045629953962146120816058213549634,
        // ['#6892D5','#79D1C3','#C9FDD7','#F8FCFB'],
        1330513398814299447253626769393243188045317948896038697269,
        // ['#6C5B7B','#C06C84','#F67280','#F8B195'],
        1255133384165670211048503380421693678075219799238809633077,
        // ['#30475E','#BA6B57','#F1935C','#E7B2A5'],
        1723125586574466746505575984771607893125819988320632193347,
        // ['#FFEBD3','#264E70','#679186','#FFB4AC'],
        1330614793481988775794266785314624655591903298842748139825,
        // ['#6DDCCF','#94EBCD','#FFEFA1','#FFCB91'],
        1672744801525859670694077834043317089631871727545208619830,
        // ['#D8EFF0','#B0E0A8','#F0F69F','#F3C1C6'],
        
        // 6 palette (Twilight)
        1255612289033585437444993878451534470432700665266407880752,
        // ['#35477D','#6C5B7B','#C06C84','#F67280'],
        1721592316357852063982625679845008202349317682013842519366,
        // ['#F6C065','#55B3B1','#AF0069','#09015F'],
        1280322302022924147060513003728168238845485443276919292980,
        // ['#470D21','#9C0F48','#D67D3E','#F9E4D4'],
        1181572497692950828953760601853026334571312612200352531009,
        // ['#001F52','#A10054','#FF8D68','#FFECBA'],
        1723119975755435620157027839780780929332479594873347126342,
        // ['#FF6C00','#A0204C','#23103A','#282D4F'],
        1723125947553932544526123585201978692984733212900337332531,
        // ['#FFF9B2','#ECAC5D','#B24080','#3F0713'],
        1723125573352757813299695957060899475309511522981632947253,
        // ['#FFE98A','#C84771','#61105E','#280B45'],
        1698414081283041489814189444330070411452527498177335867715
        // ['#EDE862','#FA9856','#F27370','#22559C']
    ];
    // function to get color palette by index (0-55)
    function getColorPalette(uint256 index) public view returns(string[4] memory)
    {
        // initialize string array with # sign
        string[4] memory paletteArray = ["#", "#", "#", "#"];
        // get palette information
        uint256 palette = ColorPalettes[index];
        unchecked
        {
            // get 1st color
            for(uint256 i=0; i<6; ++i)
            {
                paletteArray[0] = string.concat(paletteArray[0], string(abi.encodePacked(bytes1(uint8((palette & (255 << ((24-1-i)*8))) >> ((24-1-i)*8))))));
            }
            // get 2nd color
            for(uint256 i=6; i<12; ++i)
            {   
                paletteArray[1] = string.concat(paletteArray[1], string(abi.encodePacked(bytes1(uint8((palette & (255 << ((24-1-i)*8))) >> ((24-1-i)*8))))));
            }
            // get 3rd color
            for(uint256 i=12; i<18; ++i)
            {   
                paletteArray[2] = string.concat(paletteArray[2], string(abi.encodePacked(bytes1(uint8((palette & (255 << ((24-1-i)*8))) >> ((24-1-i)*8))))));
            }
            // get 4th color
            for(uint256 i=18; i<24; ++i)
            {   
                paletteArray[3] = string.concat(paletteArray[3], string(abi.encodePacked(bytes1(uint8((palette & (255 << ((24-1-i)*8))) >> ((24-1-i)*8))))));
            }
            // return the palette array
            return paletteArray;
        }
    }
    /*
        weights for shape design
        index -> shape design
        0 - none
        1 - basic circle
        2 - basic square
        3 - repeated circle
        4 - repeated square
        5 - repeated, rotated square
        6 - repeated, rotated double square 
    */
    uint256[] private ShapeDesignWeights = [40,50,50,20,20,50,50];
    // weights for repeated, rotated squares
    uint256[] private RotatedSquareWeights = [20,20,20,20,20];

    /*

        ███    ███  █████  ██   ██ ███████               
        ████  ████ ██   ██ ██  ██  ██                    
        ██ ████ ██ ███████ █████   █████                 
        ██  ██  ██ ██   ██ ██  ██  ██                    
        ██      ██ ██   ██ ██   ██ ███████               
                                                        
                                                        
        ██████   █████                                   
        ██   ██ ██   ██                                  
        ██   ██ ███████                                  
        ██   ██ ██   ██                                  
        ██████  ██   ██                       
                                                        
                                                        
        ██████  ██       ██████   ██████ ██   ██ ███████ 
        ██   ██ ██      ██    ██ ██      ██  ██  ██      
        ██████  ██      ██    ██ ██      █████   ███████ 
        ██   ██ ██      ██    ██ ██      ██  ██       ██ 
        ██████  ███████  ██████   ██████ ██   ██ ███████ 

    */

    // struct for gen-1 block
    struct Gen1Block
    {
        uint256 index;
        uint256 numLevels;
        uint256 widthInterval;
        uint256 circleCount;
        uint256 squareCount;
        uint256 noneCount;
        uint256 complexityLevel;
        uint256 colorGroupIndex;
        uint256 paletteIndex;
        uint256 shapeDesign;
        bool isSpecial; 
        bool glitchy;
        string svg;
        string name;
        string labelColor;
        string[4] palette;
    }
    // struct for gen-1 shape
    struct Gen1Shape
    {
        uint256 width;
        uint256 numIterations;
        uint256 numDegrees;
        uint256 rotationInterval;
        uint256 randSeed;
        uint256 fillColorIndex;
        uint256 strokeColorIndex;
        uint256 strokeWidth;
    }
    // get gen-1 block from token id
    function getBlockData(uint256 _tokenId) private view returns(Gen1Block memory)
    {
        unchecked
        {     
            // start up that block!
            Gen1Block memory blockData;
            // set token index
            blockData.index = _tokenId;
            // set num levels
            blockData.numLevels = (GBUtils.random(string.concat(GBUtils.toString(_tokenId), "create x innovate x impact - do some good"))%4) + 5;
            // set interval
            blockData.widthInterval = 3000/blockData.numLevels;
            // set color group
            blockData.colorGroupIndex = GBUtils.getWeightedItem(ColorGroupWeights, GBUtils.random(GBUtils.toString(_tokenId + 1)) % 140);
            // set palette index
            blockData.paletteIndex = uint8(GBUtils.random(string(abi.encodePacked("Wth?", GBUtils.toString(_tokenId + 4)))) % 8);
            // set all palette index
            uint256 allPaletteIndex = blockData.colorGroupIndex*8+blockData.paletteIndex;
            // set color palette
            blockData.palette = getColorPalette(allPaletteIndex);
            // set glitchy
            blockData.glitchy = GBUtils.getWeightedItem(BlockSymmetryWeights, GBUtils.random(GBUtils.toString(_tokenId + 22)) % 100) == 5;
            // set special status
            if(_tokenId > 2132 && _tokenId < 6121)
            {
                // 68 > x > 22
                // 2093 < x < 6187
                // 2132 < x < 6121
                if(((1 << (256-((_tokenId-2093)-(256*((_tokenId-2093)/256))))-1) & dg[((_tokenId-2093)/256)]) >> (256-((_tokenId-2093)-(256*((_tokenId-2093)/256)))-1) == 0)
                {
                    blockData.isSpecial = false;
                } else
                {
                    blockData.isSpecial = true;
                }            
            } else 
            {
                blockData.isSpecial = false;
            }
            // set label color
            blockData.labelColor = blockData.isSpecial ? '#fff' : GBUtils.readBitBool(LabelFlags, (55-allPaletteIndex)) ? '#fff' : '#000';
            // set block name
            blockData.name = string.concat(ColorGroupNames[blockData.colorGroupIndex], " #", GBUtils.toString(_tokenId));
            // return da block
            return blockData;
        }
    }
    // get shape data
    function getShapeData(uint256 _tokenId, uint256 _seed, bool _repeated, bool _rotated) private view returns(Gen1Shape memory)
    {
        unchecked
        {
            Gen1Shape memory shapeData;
            string memory tokenIdString = GBUtils.toString(_tokenId + _seed*213 + 104);
            
            // get fill color
            shapeData.fillColorIndex = GBUtils.random(tokenIdString) % 4;
            
            if(_repeated)
            {
                // set stroke color (ensure different)
                shapeData.strokeColorIndex = shapeData.fillColorIndex == 3 ? 0 : shapeData.fillColorIndex + 1;
                // check if rotated
                if(_rotated)
                {
                    shapeData.numDegrees = (GBUtils.random(string.concat(tokenIdString, "how many degrees are we rotating?"))%136)+45;
                    shapeData.numIterations = (GBUtils.random(string.concat(tokenIdString, "how many times are we spinning?"))%21)+40;
                    // get rand seed
                    shapeData.randSeed = GBUtils.getWeightedItem(RotatedSquareWeights, GBUtils.random(string.concat(unicode"what will you get? 🤔", GBUtils.toString(_seed*7 + _tokenId)))%100);
                    // set stroke width
                    shapeData.strokeWidth = _seed == 0 ? 200 : 300/(_seed+1);
                    
                } else
                {
                    // set rotation
                    shapeData.numDegrees = 0;
                    // get number of iterations
                    shapeData.numIterations = (GBUtils.random(string.concat(tokenIdString, "how many times are we spinning?"))%10)+5;
                    // set stroke width
                    shapeData.strokeWidth = _seed == 0 ? 50 : 50/_seed;
                }            
            } else
            {
                // get stroke color (can be same)
                shapeData.strokeColorIndex = GBUtils.random(string.concat(GBUtils.toString(_tokenId +_seed), "a little extra")) % 4;
                // get stroke width
                shapeData.strokeWidth = 50;
            }
            return shapeData;
        }
    }
    // get shape design
    function getShapeDesign(uint256 _seed, uint256 _limit) private view returns(uint256)
    {
        return GBUtils.getWeightedItem(ShapeDesignWeights, GBUtils.random(string.concat("its a good day", GBUtils.toString(_seed*13 << 27), "to have a good day"))%_limit);
    }
    // svg strings
    string[13] private SvgPieces;
    // update svg strings
    function updateSvgPiece(uint256 _index, string memory _text) external onlyOwner
    {
        // update svg string
        SvgPieces[_index] = _text;
    }
    // metadata strings
    string[23] private MetadataPieces = 
    [
        'data:application/json,{"name":"',                  // 0
        '","description":"',                                // 1            
        '",',                                               // 2
        ',"attributes":[',                                  // 3
        '],"image":"data:image/svg+xml;base64,',            // 4                        
        '"}',                                               // 5
        '{"trait_type": "Generations Unlocked", "value":',  // 6                                
        '},{"trait_type": "Active Generation", "value":"',  // 7                                
        '"},{"trait_type": "Times Transferred", "value":"', // 8                                
        '"},{"trait_type": "Owned Since", "value":"',       // 9                            
        '"},{"trait_type": "Color Group", "value":"',       // 10                            
        '"},{"trait_type": "Palette Index", "value":"',     // 11                           
        '"},{"trait_type": "Shape Groups", "value":"',      // 12                           
        '"},{"trait_type": "Circles", "value":"',           // 13                       
        '"},{"trait_type": "Squares", "value":"',           // 14                       
        '"},{"trait_type": "Blanks", "value":"',            // 15                       
        '"},{"trait_type": "Complexity", "value":"',        // 16                           
        '"},{"trait_type": "Glitchy", "value":"',           // 17                   
        'True',                                             // 18                           
        'False',                                            // 19
        '"},{"trait_type": "Special Trait", "value":"',     // 20
        'Do Good"}',                                        // 21
        'None"}'                                            // 22
    ];
    // update metadata strings
    function updateMetadataPiece(uint256 _index, string memory _text) external onlyOwner
    {
        // update svg string
        MetadataPieces[_index] = _text;
    }
    // struct for circle data
    struct circleData
    {
        uint256 radius;
        string fill;
        string strokeFill;
        uint256 strokeWidth;
    }
    // circle strings
    string[5] private CirclePieces = 
    [
        "<circle  cx='2000' cy='2000' r='", // 0
        "' fill='",                         // 1
        "' stroke-width='",                 // 2
        "' stroke='",                       // 3
        "'>"                                // 4
        "</circle>"
        ""
    ];
    // update circle strings
    function updateCirclePiece(uint256 _index, string memory _text) external onlyOwner
    {
        CirclePieces[_index] = _text;
    }
    // draw circle
    function drawCircle(circleData memory _circleData) private view returns(string memory)
    {
        // start svg
        string memory outputSVG = string.concat(
            CirclePieces[0],
            // add radius
            GBUtils.toString(_circleData.radius),
            // add fill
            CirclePieces[1],
            _circleData.fill,
            // add stroke width
            CirclePieces[2],
            GBUtils.toString(_circleData.strokeWidth),
            // add stroke fill
            CirclePieces[3],
            _circleData.strokeFill,
            // close
            CirclePieces[4]
        );

        return outputSVG;
    }
    // struct for square data
    struct SquareData
    {
        uint256 width;
        uint256 height;
        string startX;
        string startY;
        string strokeWidth;
        string fill;
        string strokeFill;
        string strWidth;
        string strHeight;
        string rotation;
    }
    // square strings
    string[9] private SquarePieces = 
    [
        "<rect x='",                // 0
        "' y='",                    // 1
        "' width='",                // 2
        "' height='",               // 3
        "' fill='",                 // 4
        "' stroke-width='",         // 5
        "' stroke='",               // 6
        "' transform='rotate(",     // 7
        " 2000 2000)'>"             // 8
        "</rect>"
        ""  
    ];
    // update square strings
    function updateSquarePiece(uint256 _index, string memory _text) external onlyOwner
    {
        SquarePieces[_index] = _text;
    }
    // draw square
    function drawSquare(SquareData memory _squareData) private view returns(string memory)
    {       
        // start svg
        string memory outputSVG = string.concat(
            // add x
            SquarePieces[0],
            _squareData.startX,
            // add y
            SquarePieces[1],
            _squareData.startY,
            // add width
            SquarePieces[2],
            _squareData.strWidth,
            // add height
            SquarePieces[3],
            _squareData.strHeight
        );
        // continue square...
        outputSVG = string.concat(
            outputSVG,
            // add fill
            SquarePieces[4],
            _squareData.fill,
            // add stroke width
            SquarePieces[5],
            _squareData.strokeWidth,
            // add stroke width
            SquarePieces[6],
            _squareData.strokeFill,
            // add rotation
            SquarePieces[7],
            _squareData.rotation,
            // close
            SquarePieces[8]
        );

        return outputSVG;
    }
    // repeated center square
    function simpleRepeatedSquare(Gen1Shape memory _shapeData, SquareData memory _squareData, uint256 _width) private view returns(string memory)
    {
        unchecked
        {
            // get interval
            uint256 widthInterval = _width/_shapeData.numIterations;
            string memory svg;
            // loop through and add squares
            for(uint256 i = 0; i<_shapeData.numIterations; ++i)
            {
                // update dimensions
                _squareData.width = (widthInterval)*(_shapeData.numIterations-i);
                _squareData.height = _squareData.width;
                _squareData.strWidth = GBUtils.toString(_squareData.width);
                _squareData.strHeight = _squareData.strWidth;
                _squareData.startX = GBUtils.toString(2000 - _squareData.width/2);
                _squareData.startY = _squareData.startX;
                // add square to svg
                svg = string.concat(svg, drawSquare(_squareData));
            }
            return svg;    
        }
        
    }
    // repeated squares in alternating directions
    function doubleRepeatedSquare(Gen1Shape memory _shapeData, SquareData memory _squareData, uint256 _width) private view returns(string memory)
    {
        unchecked
        {
            // start svg
            string memory svg;
            // temporary square string
            string memory tempSquare;
            // interval for each rotation
            uint256 rotationInterval = _shapeData.numDegrees/_shapeData.numIterations;
            // interval for each square width
            uint256 widthInterval = _width/_shapeData.numIterations;
            // loop through and add squares
            for(uint256 i = 0; i<_shapeData.numIterations; ++i)
            {
                // update dimensions
                _squareData.width = (widthInterval)*(_shapeData.numIterations-i);
                _squareData.height = _squareData.width;
                _squareData.strWidth = GBUtils.toString(_squareData.width);
                _squareData.strHeight = _squareData.strWidth;
                _squareData.startX = GBUtils.toString(2000 - _squareData.width/2);
                _squareData.startY = _squareData.startX;
                // update rotation
                _squareData.rotation = GBUtils.toString((rotationInterval)*i);
                tempSquare = drawSquare(_squareData);
                _squareData.rotation = string.concat("-", _squareData.rotation);
                // add to svg
                svg = string.concat(
                    svg, 
                    tempSquare,
                    drawSquare(_squareData)
                ); 
            }
            return svg;
        }   
    }
    // squares repeated in same direction but more fun
    function getRepeatedSquare(Gen1Shape memory _shapeData, SquareData memory _squareData, uint256 _width) private view returns(string memory)
    {
        unchecked 
        {
            // start svg
            string memory svg;
            // interval for square rotation
            uint256 rotationInterval = (_shapeData.numDegrees*100)/_shapeData.numIterations;
            // interval for square width
            uint256 widthInterval = (_width - ((_width)/10))/_shapeData.numIterations;
            // temporary rotation
            uint256 tempRotation;
            // store square strings here to avoid multiple string.concat
            string[5] memory tempSquares;

            // double square, same direction, 15° apart
            if(_shapeData.randSeed == 0)
            {
                // loop through and add squares
                for(uint256 i = 0; i<_shapeData.numIterations; ++i)
                {
                    // temporary rotation
                    tempRotation = (rotationInterval)*i;
                    // update dimensions
                    _squareData.width = (widthInterval)*(_shapeData.numIterations-i);
                    _squareData.strWidth = GBUtils.toString(_squareData.width);
                    _squareData.height = _squareData.width;
                    _squareData.strHeight = _squareData.strWidth;
                    _squareData.startX = GBUtils.toString(2000 - _squareData.width/2);
                    _squareData.startY = _squareData.startX;
                    // update rotation
                    _squareData.rotation = addDecimalFromTheRight(tempRotation, 2);
                    // add first square
                    tempSquares[0] = drawSquare(_squareData);
                    // update rotation
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+1500, 2);
                    // add to svg
                    svg = string.concat(
                        svg,
                        tempSquares[0],
                        drawSquare(_squareData)
                    );
                }

            // double square, same direction, 45° apart
            } else if(_shapeData.randSeed == 1)
            {
                // loop through and add squares
                for(uint256 i = 0; i<_shapeData.numIterations; ++i)
                {
                    // temporary rotation
                    tempRotation = (rotationInterval)*i;
                    // update dimensions
                    _squareData.width = (widthInterval)*(_shapeData.numIterations-i);
                    _squareData.strWidth = GBUtils.toString(_squareData.width);
                    _squareData.height = _squareData.width;
                    _squareData.strHeight = _squareData.strWidth;
                    _squareData.startX = GBUtils.toString(2000 - _squareData.width/2);
                    _squareData.startY = _squareData.startX;
                    // update rotation
                    _squareData.rotation = addDecimalFromTheRight(tempRotation, 2);
                    // add first square
                    tempSquares[0] = drawSquare(_squareData);
                    // update rotation
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+4500, 2);
                    // add to svg
                    svg = string.concat(
                        svg,
                        tempSquares[0],
                        drawSquare(_squareData)
                    );
                }
            
            // 3 squares, same direction, 0° 30° 60°
            } else if(_shapeData.randSeed == 2)
            {
                // loop through and add squares
                for(uint256 i = 0; i<_shapeData.numIterations; ++i)
                {
                    // temporary rotation
                    tempRotation = (rotationInterval)*i;
                    // update dimensions
                    _squareData.width = (widthInterval)*(_shapeData.numIterations-i);
                    _squareData.strWidth = GBUtils.toString(_squareData.width);
                    _squareData.height = _squareData.width;
                    _squareData.strHeight = _squareData.strWidth;
                    _squareData.startX = GBUtils.toString(2000 - _squareData.width/2);
                    _squareData.startY = _squareData.startX;
                    // update rotation
                    _squareData.rotation = addDecimalFromTheRight(tempRotation, 2);
                    // add first square
                    tempSquares[0] = drawSquare(_squareData);
                    // update rotation
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+3000, 2);
                    // add second square
                    tempSquares[1] = drawSquare(_squareData);
                    // update rotation
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+6000, 2);
                    // add to svg
                    svg = string.concat(
                        svg,
                        tempSquares[0],
                        tempSquares[1],
                        drawSquare(_squareData)
                    );
                }
                
            // 4 squares, same direction, 0° 22° 45° 68°
            } else if(_shapeData.randSeed == 3)
            {
                // loop through and add squares
                for(uint256 i = 0; i<_shapeData.numIterations; ++i)
                {
                    // temporary rotation
                    tempRotation = (rotationInterval)*i;
                    // update dimensions
                    _squareData.width = (widthInterval)*(_shapeData.numIterations-i);
                    _squareData.strWidth = GBUtils.toString(_squareData.width);
                    _squareData.height = _squareData.width;
                    _squareData.strHeight = _squareData.strWidth;
                    _squareData.startX = GBUtils.toString(2000 - _squareData.width/2);
                    _squareData.startY = _squareData.startX;
                    // update rotation
                    _squareData.rotation = addDecimalFromTheRight(tempRotation, 2);
                    // add first square
                    tempSquares[0] = drawSquare(_squareData);
                    // update rotation                            
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+2200, 2);
                    // add second square
                    tempSquares[1] = drawSquare(_squareData);
                    // update rotation        
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+4500, 2);
                    // add third square
                    tempSquares[2] = drawSquare(_squareData);
                    // update rotation        
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+6800, 2);
                    // add to svg
                    svg = string.concat(
                        svg,
                        tempSquares[0],
                        tempSquares[1],
                        tempSquares[2],
                        drawSquare(_squareData)
                    );
                }

            // 6 squares, same direction, 0° 15° 30° 45° 60° 75°
            } else if(_shapeData.randSeed == 4)
            {
                // loop through and add squares
                for(uint256 i = 0; i<_shapeData.numIterations; ++i)
                {
                    // temporary rotation
                    tempRotation = (rotationInterval)*i;
                    // update dimensions
                    _squareData.width = (widthInterval)*(_shapeData.numIterations-i);
                    _squareData.strWidth = GBUtils.toString(_squareData.width);
                    _squareData.height = _squareData.width;
                    _squareData.strHeight = _squareData.strWidth;
                    _squareData.startX = GBUtils.toString(2000 - _squareData.width/2);
                    _squareData.startY = _squareData.startX;
                    // update rotation
                    _squareData.rotation = addDecimalFromTheRight(tempRotation, 2);
                    // add first square
                    tempSquares[0] = drawSquare(_squareData);
                    // update rotation    
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+1500, 2);
                    // add second square
                    tempSquares[1] = drawSquare(_squareData);
                    // update rotation                        
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+3000, 2);
                    // add third square
                    tempSquares[2] = drawSquare(_squareData);
                    // update rotation    
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+4500, 2);
                    // add fourth square
                    tempSquares[3] = drawSquare(_squareData);
                    // update rotation    
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+6000, 2);
                    // add fifth square
                    tempSquares[4] = drawSquare(_squareData);
                    // update rotation                        
                    _squareData.rotation = addDecimalFromTheRight(tempRotation+7500, 2);
                    // add to svg
                    svg = string.concat(
                        svg,
                        tempSquares[0],
                        tempSquares[1],
                        tempSquares[2],
                        tempSquares[3],
                        tempSquares[4],
                        drawSquare(_squareData)
                    );
                }
            }
            return svg;
        }   
    }
    // get repeated circles
    function getRepeatedCircle(Gen1Shape memory _shapeData, circleData memory _circleData, uint256 _width) private view returns(string memory)
    {
        // start svg
        string memory svg;
        // loop through and add circles
        for(uint256 i = 0; i<_shapeData.numIterations; ++i)
        {   
            // get radius                 
            _circleData.radius = ((_width/_shapeData.numIterations)*(_shapeData.numIterations-i))/2;
            // draw circle
            svg = string.concat(svg, drawCircle(_circleData));
        }
        return svg;
    }
    // create token data string for token js
    function getTokenDataString(IGBContract.TokenData memory _tokenData, Gen1Block memory _gen1Block) private view returns(string memory)
    {        
        // start token data string for token
        string memory tokenDataString = string.concat(
            GBUtils.toString(_gen1Block.index),
            '|',
            _gen1Block.name,
            '|',
            GBUtils.toHexString(_tokenData.tokenOwner),
            '|',
            GBUtils.toString(_tokenData.ownedSince),
            '|',
            GBUtils.toString(_tokenData.timesTransferred),
            '|',
            GBUtils.toString(_tokenData.highestGenLevel + 1),
            '|',
            GBUtils.toString(_tokenData.activeGen),
            '|',
            ColorGroupNames[_gen1Block.colorGroupIndex],
            '|',
            GBUtils.toString(_gen1Block.paletteIndex),
            '|'
        );
        // continue data string
        return string.concat(
            tokenDataString,
            GBUtils.toString(_gen1Block.numLevels),
            '|',
            GBUtils.toString(_gen1Block.circleCount),
            '|',
            GBUtils.toString(_gen1Block.squareCount),
            '|',
            GBUtils.toString(_gen1Block.noneCount),
            '|',
            GBUtils.toString(_gen1Block.complexityLevel),
            '|',
            _gen1Block.glitchy ? 'true' : 'false',
            '|',
            _gen1Block.isSpecial ? 'do good' : 'none',
            '|',
            _gen1Block.palette[0],
            '|',
            _gen1Block.palette[1],
            '|',
            _gen1Block.palette[2],
            '|',
            _gen1Block.palette[3]
        );
    }
    // get metadata for gen-1 block
    function blockToMetadata(IGBContract.TokenData memory _tokenData, Gen1Block memory _gen1Block, string memory _tokenAttributes) private view returns(string memory)
    {
        // get attribute substring
        string[2] memory ogAttributes = cleanAttributes(_tokenAttributes);
        // start metadata
        string memory metadata = string.concat(
            MetadataPieces[6],      // {"trait_type": "Generations Unlocked", "value":,
            GBUtils.toString(_tokenData.highestGenLevel+1),
            MetadataPieces[7],      // },{"trait_type": "Active Generation", "value":",
            GBUtils.toString(_tokenData.activeGen),
            MetadataPieces[8],      // "},{"trait_type": "Times Transferred", "value":",
            ogAttributes[0],
            MetadataPieces[9],      // "},{"trait_type": "Owned Since", "value":",
            ogAttributes[1]
        );
        metadata = string.concat(
            metadata,
            MetadataPieces[10],      // "},{"trait_type": "Color Group", "value":",
            ColorGroupNames[_gen1Block.colorGroupIndex],
            MetadataPieces[11],      // "},{"trait_type": "Palette Index", "value":",
            GBUtils.toString(_gen1Block.paletteIndex),
            MetadataPieces[12],      // "},{"trait_type": "Shape Groups", "value":",
            GBUtils.toString(_gen1Block.numLevels),
            MetadataPieces[13],      // "},{"trait_type": "Circles", "value":",
            GBUtils.toString(_gen1Block.circleCount)
        );
        metadata = string.concat(
            metadata,
            MetadataPieces[14],      // "},{"trait_type": "Squares", "value":",
            GBUtils.toString(_gen1Block.squareCount),
            MetadataPieces[15],      // "},{"trait_type": "Blanks", "value":",
            GBUtils.toString(_gen1Block.noneCount),
            MetadataPieces[16],      // "},{"trait_type": "Complexity", "value":",
            GBUtils.toString(_gen1Block.complexityLevel),
            MetadataPieces[17],      // "},{"trait_type": "Glitchy", "value":",
            _gen1Block.glitchy ? MetadataPieces[18] : MetadataPieces[19], // true false
            MetadataPieces[20],      // "},{"trait_type": "Special Trait", "value":",
            _gen1Block.isSpecial ? MetadataPieces[21] : MetadataPieces[22] // Do Good"} : None"}
        );
        // return metadata string
        return metadata;
    }
    // function to add decimals to a number
    function addDecimalFromTheRight(uint256 _number, uint256 _sigFigs) private pure returns(string memory)
    {
        string memory numString = GBUtils.toString(_number);
        uint256 length = bytes(numString).length;
        bytes memory decimal = new bytes(_sigFigs);   
        // check if sig fig greater thant length (0 padded)
        if(_sigFigs > length)
        {
            for(uint256 i=_sigFigs-1; i>0; --i)
            {
                if(i < _sigFigs-length)
                {
                    decimal[i] = bytes('0')[0];
                } else
                {
                    decimal[i] = bytes(numString)[i-(_sigFigs-length)];
                }
            }
            decimal[0] = '0';
            return string.concat('0', '.', string(decimal));
        // sig figs is = length
        } else if(_sigFigs == length)
        {
            return string.concat('0', '.', numString);
        // sig figs < length
        } else
        {
            uint256 wholeIndex;
            uint256 decimalIndex;
            bytes memory whole = new bytes(length-_sigFigs);
            for(uint256 i=0; i<length; ++i)
            {
                if(i < length-_sigFigs)
                {
                    whole[wholeIndex] = bytes(numString)[i];
                    wholeIndex++;
                } else
                {
                    decimal[decimalIndex] = bytes(numString)[i];
                    decimalIndex++;
                }
            }
            return string.concat(string(whole), '.', string(decimal));
        }
    }
    // attribute data struct to help clean original contract metadata
    struct AttData
    {
        uint256 ownedStart;
        uint256 ownedEnd;
        uint256 ownedLength;
        uint256 transferStart;
        uint256 transferEnd;
        uint256 transferLength;
    }
    // function to clean original attributes
    function cleanAttributes(string memory _attributes) public pure returns(string[2] memory)
    {
        uint256 i;
        bytes memory attBytes = bytes(_attributes);
        AttData memory attData;
        // get time owned attribute
        attData.ownedEnd = attBytes.length-3;
        for(i=attData.ownedEnd; i>0; --i)
        {
            if(attBytes[i] == bytes1('"'))
            {
                attData.ownedStart = i+1;
                attData.ownedLength = (attData.ownedEnd-attData.ownedStart+1);
                break;
            }
        }
        // get times transfrerred attribute
        attData.transferEnd = attData.ownedStart-43;
        for(i=attData.transferEnd; i>0; --i)
        {
            if(attBytes[i] == bytes1('"'))
            {
                attData.transferStart = i+1;
                attData.transferLength = (attData.transferEnd-attData.transferStart+1);
                break;
            }            
        }

        bytes memory timesTransferredBytes = new bytes(attData.transferLength);
        bytes memory ownedSinceBytes = new bytes(attData.ownedLength);
        
        for(i=0; i<attData.transferLength; ++i)
        {
            timesTransferredBytes[i] = attBytes[attData.transferStart + i];
        }
        
        for(i=0; i<attData.ownedLength; ++i)
        {
            ownedSinceBytes[i] = attBytes[attData.ownedStart + i];
        }

        // return attributes
        return [string(timesTransferredBytes), string(ownedSinceBytes)];
    }
    


    /*

        ███████ ██   ██  █████  ██████  ███████          
        ██      ██   ██ ██   ██ ██   ██ ██               
        ███████ ███████ ███████ ██████  █████            
             ██ ██   ██ ██   ██ ██   ██ ██               
        ███████ ██   ██ ██   ██ ██   ██ ███████          
                                                        
                                                        
        ██████   █████                                   
        ██   ██ ██   ██                                  
        ██   ██ ███████                                  
        ██   ██ ██   ██                                  
        ██████  ██   ██                                  
                                                        
                                                        
        ██████  ██       ██████   ██████ ██   ██ ███████ 
        ██   ██ ██      ██    ██ ██      ██  ██  ██      
        ██████  ██      ██    ██ ██      █████   ███████ 
        ██   ██ ██      ██    ██ ██      ██  ██       ██ 
        ██████  ███████  ██████   ██████ ██   ██ ███████

    */    




    // token uri for gen-1
    function tokenGenURI(uint256 _tokenId, string memory _tokenMetadata, string memory _tokenAttributes) public view returns(string memory)
    {
        // check if valid token ID
        if(_tokenId > 8280) revert YooooThatTokenIdIsWayTooHigh();
        // get token data from original contract
        IGBContract.TokenData memory tokenData = GBTokenContract.getTokenData(_tokenId);
        // check if gen-1 has been unlocked
        //if(tokenData.highestGenLevel < 1) revert GottaUnlockGen1Please();        
        // get gen 1 block
        Gen1Block memory blockData = getBlockData(_tokenId);
        string memory svg = getTokenSvg(_tokenId, tokenData, blockData);
        // return token uri
        return string.concat(
            // name
            MetadataPieces[0],
            blockData.name,
            // description
            MetadataPieces[1],
            Gen1Description,
            // metadata
            MetadataPieces[2],
            _tokenMetadata,
            // attributes
            MetadataPieces[3],
            blockToMetadata(tokenData, blockData, _tokenAttributes),
            // image
            MetadataPieces[4],
            GBUtils.encode(bytes(svg)),
            // close
            MetadataPieces[5]
        );
    }
    // get token svg
    function getTokenSvg(uint256 _tokenId, IGBContract.TokenData memory _tokenData, Gen1Block memory _blockData) private view returns(string memory)
    {
        /*
            same color group as gen0
            chaos gets a little funky
            specials are still special
            lets go....
        */

        // declare temporary square and circle variables
        SquareData memory tempSquareData;
        circleData memory tempCircleData;
        // declare shape data for loop
        Gen1Shape memory shapeData;
        // use memory array to minimize data going into string.concat for each loop
        string[9] memory shapes;

        // oooh.... risky
        unchecked
        {
            // loop through dem shapes
            for(uint256 i=0; i<_blockData.numLevels; ++i)
            {
                // get shape width
                shapeData.width = _blockData.widthInterval*(_blockData.numLevels-i);
                // get weighted shape design
                /*
                    0 - none
                    1 - basic circle
                    2 - basic square (possibly rotated to 45 degrees)
                    3 - repeated circle
                    4 - repeated square
                    5 - rotated square (same direction)
                    6 - double rotated square (opposite directions)
                */
                // check if complexity limit is reached or recently used or too small
                if(_blockData.complexityLevel < 3 && _blockData.shapeDesign < 3 && i<6)
                {
                    // get possible complex shape
                    _blockData.shapeDesign = getShapeDesign((_tokenId+i), 280);
                } else
                {
                    // get simple shapes
                    _blockData.shapeDesign = getShapeDesign((_tokenId+i), 140);
                }

                // none
                if(_blockData.shapeDesign == 0)
                {
                    // nothing to see here folks!
                    ++_blockData.noneCount;

                // basic circle
                } else if(_blockData.shapeDesign == 1)
                {
                    // update shape
                    shapeData = getShapeData(_tokenId, i, false, false);
                    // get radius
                    tempCircleData.radius = (_blockData.widthInterval*(_blockData.numLevels-i))/2;
                    // get fill
                    tempCircleData.fill = _blockData.palette[shapeData.fillColorIndex];
                    // get stroke color
                    tempCircleData.strokeFill = _blockData.palette[shapeData.strokeColorIndex];
                    // set stroke width
                    tempCircleData.strokeWidth = shapeData.strokeWidth;
                    // add to shapes
                    shapes[i] = string.concat(        
                        SvgPieces[0],
                        GBUtils.toString(i),
                        SvgPieces[1],
                        drawCircle(tempCircleData),
                        SvgPieces[2]
                    );
                    // update circle count
                    ++_blockData.circleCount;


                // basic square
                } else if(_blockData.shapeDesign == 2)
                {
                    // update shape
                    shapeData = getShapeData(_tokenId, i, false, false);
                    // get dimensions
                    tempSquareData.width = (_blockData.widthInterval*(_blockData.numLevels-i))-150;
                    tempSquareData.height = tempSquareData.width;
                    tempSquareData.strWidth = GBUtils.toString(tempSquareData.width);
                    tempSquareData.strHeight  = GBUtils.toString(tempSquareData.width);
                    tempSquareData.startX = GBUtils.toString(2000 - tempSquareData.width/2);
                    tempSquareData.startY = tempSquareData.startX;
                    // get fill
                    tempSquareData.fill = _blockData.palette[shapeData.fillColorIndex];
                    // get stroke color
                    tempSquareData.strokeFill = _blockData.palette[shapeData.strokeColorIndex];
                    // set stroke width
                    tempSquareData.strokeWidth = GBUtils.toString(shapeData.strokeWidth);
                    // set rotation
                    tempSquareData.rotation = (i*shapeData.strokeColorIndex*3)%2==0 ? "0" : "45";
                    // add to shapes
                    shapes[i] = string.concat(
                        SvgPieces[0],
                        GBUtils.toString(i),
                        SvgPieces[1],
                        drawSquare(tempSquareData),
                        SvgPieces[2]
                    );
                    // update square count
                    ++_blockData.squareCount;


                // repeated circle
                } else if(_blockData.shapeDesign == 3)
                {
                    // update shape
                    shapeData = getShapeData(_tokenId, i, true, false);
                    // get fill
                    tempCircleData.fill = _blockData.palette[shapeData.fillColorIndex];
                    // get stroke color
                    tempCircleData.strokeFill = _blockData.palette[shapeData.strokeColorIndex];
                    // set stroke width
                    tempCircleData.strokeWidth = shapeData.strokeWidth;
                    // add to shapes
                    shapes[i] = string.concat(
                        SvgPieces[0],
                        GBUtils.toString(i),
                        SvgPieces[1],
                        getRepeatedCircle(shapeData, tempCircleData, _blockData.widthInterval*(_blockData.numLevels-i)),
                        SvgPieces[2]
                    );
                    // update circle count
                    ++_blockData.circleCount;
                    // update complexity count
                    ++_blockData.complexityLevel;


                // repeated square
                } else if(_blockData.shapeDesign == 4)
                {
                    // update shape
                    shapeData = getShapeData(_tokenId, i, true, false);
                    // get fill
                    tempSquareData.fill = _blockData.palette[shapeData.fillColorIndex];
                    // get stroke color
                    tempSquareData.strokeFill = _blockData.palette[shapeData.strokeColorIndex];
                    // get stroke width
                    tempSquareData.strokeWidth = GBUtils.toString(i==0 ? 20 : 20/i);
                    // set rotation
                    tempSquareData.rotation = '0';
                    // add to shapes                    
                    shapes[i] = string.concat(
                        SvgPieces[0],
                        GBUtils.toString(i),
                        SvgPieces[1],
                        simpleRepeatedSquare(shapeData, tempSquareData, _blockData.widthInterval*(_blockData.numLevels-i)),
                        SvgPieces[2]
                    );
                    // update square count
                    ++_blockData.squareCount;
                    // update complexity count
                    ++_blockData.complexityLevel;


                // rotated square, same direction
                } else if(_blockData.shapeDesign == 5)
                {
                    // update shape
                    shapeData = getShapeData(_tokenId, i, true, true);
                    // get fill
                    tempSquareData.fill = _blockData.palette[shapeData.fillColorIndex];
                    // get stroke color
                    tempSquareData.strokeFill = _blockData.palette[shapeData.strokeColorIndex];
                    // get stroke width
                    tempSquareData.strokeWidth = GBUtils.toString(i==0 ? 20 : 20/i);
                    // add to shapes
                    shapes[i] = string.concat(
                        SvgPieces[0],
                        GBUtils.toString(i),
                        SvgPieces[1],
                        getRepeatedSquare(shapeData, tempSquareData, _blockData.widthInterval*(_blockData.numLevels-i)),
                        SvgPieces[2]
                    );
                    // update square count
                    ++_blockData.squareCount;
                    // update complexity count
                    ++_blockData.complexityLevel;


                // rotated square, 2 directions
                } else if(_blockData.shapeDesign == 6)
                {
                    // update shape
                    shapeData = getShapeData(_tokenId, i, true, true);
                    // get fill
                    tempSquareData.fill = _blockData.palette[shapeData.fillColorIndex];
                    // get stroke color
                    tempSquareData.strokeFill = _blockData.palette[shapeData.strokeColorIndex];
                    // get stroke width
                    tempSquareData.strokeWidth = '5';
                    // add to shapes
                    shapes[i] = string.concat(
                        SvgPieces[0],
                        GBUtils.toString(i),
                        SvgPieces[1],
                        doubleRepeatedSquare(shapeData, tempSquareData, _blockData.widthInterval*(_blockData.numLevels-i)),
                        SvgPieces[2]
                    );
                    // update square count
                    ++_blockData.squareCount;
                    // update complexity count
                    ++_blockData.complexityLevel;
                }
            }

            // combine everything
            string memory svg = string.concat(
                // svg intro
                SvgPieces[3],
                // check for special and add background
                !_blockData.isSpecial ? _blockData.palette[0] : '#000',
                // check for glitchy friends
                !_blockData.glitchy ? SvgPieces[4] : SvgPieces[5],
                // shapes 0-5
                shapes[0],
                shapes[1],
                shapes[2],
                shapes[3],
                shapes[4],
                shapes[5],
                shapes[6],
                shapes[7],
                shapes[8]
            );
            // combine continued....
            return string.concat(
                svg,
                // add name text intro
                SvgPieces[6],
                // add name text color
                _blockData.labelColor,
                // close name text intro
                SvgPieces[7],
                // add name
                _blockData.name,
                // add special js
                _blockData.isSpecial ? SvgPieces[8] : SvgPieces[9],
                // add glitchy js
                _blockData.glitchy ? SvgPieces[10] : SvgPieces[11],
                // token data for js to run token specific thangs
                getTokenDataString(_tokenData, _blockData),
                // the rest of the js, token info, and background intro
                SvgPieces[12]
            );
        }
    }



    /*
  
         ██████  ██     ██ ███    ██ ███████ ██████      ███████ ██   ██ ██ ███████ 
        ██    ██ ██     ██ ████   ██ ██      ██   ██     ██      ██   ██ ██    ███  
        ██    ██ ██  █  ██ ██ ██  ██ █████   ██████      ███████ ███████ ██   ███   
        ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██          ██ ██   ██ ██  ███    
         ██████   ███ ███  ██   ████ ███████ ██   ██     ███████ ██   ██ ██ ███████
  
    */

    // transfer contract ownership
    function transferOwnership(address _newOwner) external onlyOwner()
    {
        if(_newOwner == address(0)) revert SorryYouCantAbandonOwnershipToTheZeroAddress();
        ContractOwner = _newOwner;
    }
    // only owner homes!
    modifier onlyOwner
    {
        checkOwner();
        _;
    }
    // check owner function
    function checkOwner() private view
    {
        if(msg.sender != ContractOwner) revert YoureNotTheOwnerHomie();
    }
    // da constructor of course
    constructor()
    {
        ContractOwner = msg.sender;
    }



    /*
         ██████  ████████ ██   ██ ███████ ██████      ███████ ██   ██ ██ ███████ 
        ██    ██    ██    ██   ██ ██      ██   ██     ██      ██   ██ ██    ███  
        ██    ██    ██    ███████ █████   ██████      ███████ ███████ ██   ███   
        ██    ██    ██    ██   ██ ██      ██   ██          ██ ██   ██ ██  ███    
         ██████     ██    ██   ██ ███████ ██   ██     ███████ ██   ██ ██ ███████ 
    */

    // what is this? might get some eth if you find out what this is for...
    uint256[16] private dg = 
    [
        // 68 > x > 22
        // 2093 < x < 6187
        // 2132 < x < 6121
        102021282553914774613608089359761799178262015729299970412947439616,
        778360615187948414715637888792127984453292966684722682785855,
        57896044618658097713354588343023422346919739148282798015233532827003470742527,
        113078184538831209931075937543155121694344228625149498392006825716502298099712,
        877218653273216194192172123140375024722217319512236697439018639782890700800,
        6807227843502851840086740716877481124486385200992461467676556649824256,
        13162529905113298226147989406167177160117143377373115831914856448,
        8935141660703064064,
        417879173340834916817338734017584329434161216427212678811432712667136,
        3188165079992327097213657786451849572789873861404668167890927616,
        28946476292872224935800687286985591109930951143206526035726254058726678798208,
        428329420568494648490658216432943684042380553829661223197682737300246431,
        3505424579788208648752016578713469198590704525103534625737963099627387355039,
        115707279715488546053996121108542739027840001942120880079093165837435296288641,
        113984590913297954738950134280881736553353928201922026541891808982545480024079,
        115565932813024562229384323676698964891999997982351658710285968647177438756864
    ];
}



// interface with the token contract
interface IGBContract
{
    struct TokenData
    {
        uint8 activeGen;
        uint8 highestGenLevel;
        uint64 timesTransferred;
        uint64 ownedSince;
        address tokenOwner;
    }
    function getTokenData(uint256 _tokenId) external view returns (TokenData memory);
}



// extra shizzles that help enable all of this mess
library GBUtils
{
    // get weighted item
    function getWeightedItem(uint256[] memory weightArray, uint256 i) internal pure returns (uint256)
    {
        uint256 index = 0;
        uint256 j = weightArray[0];
        while (j <= i)
        {
            index++;
            j += weightArray[index];
        }
        return index;
    }
    // get pseudo-random number
    function random(string memory _input) internal pure returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_input)));
    }
    // read bit, return bool
    function readBitBool(uint256 _data, uint256 _bitIndex) internal pure returns(bool)
    {
        return ((1 << _bitIndex) & _data) != 0;
    }
    // trimmed down version of open zeppelin libraries Strings.sol, Math.sol, and Base64.sol
    function toString(uint256 value) internal pure returns (string memory)
    {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true)
            {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), "0123456789abcdef"))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
    function toHexString(address addr) internal pure returns (string memory)
    {
        uint256 value = uint256(uint160(addr));
        uint256 length = 20;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i)
        {
            buffer[i] = bytes16("0123456789abcdef")[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
    function log10(uint256 value) internal pure returns (uint256)
    {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64)
            {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32)
            {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16)
            {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8)
            {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4)
            {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2)
            {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1)
            {
                result += 1;
            }
        }
        return result;
    }
    function log256(uint256 value) internal pure returns (uint256)
    {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0)
            {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0)
            {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0)
            {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0)
            {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0)
            {
                result += 1;
            }
        }
        return result;
    }
    function encode(bytes memory data) internal pure returns (string memory)
    {
        if (data.length == 0) return "";
        // Loads the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));
        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }
            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }
}



////////////////////////////////////////////
// be the reason someone smiles today 🫂 //
///////////////////////////////////////////