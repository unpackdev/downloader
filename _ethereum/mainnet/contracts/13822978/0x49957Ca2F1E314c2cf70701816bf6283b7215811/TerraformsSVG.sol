//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ToString.sol";
import "./Ownable.sol";

/// @notice Interface for retrieving custom fonts
interface ITerraformsCharacters {
    function font(uint) external view returns (string memory);
}

/// @author xaltgeist
/// @title Creates a tokenURI string for tokens of the Terraforms contract
contract TerraformsSVG is Ownable {

    /// @notice Struct for passing token info from TerraformsData to this contract
    struct SVGParams {
        uint[32][32] heightmapIndices; // Heightmap (indices into chars array)
        uint level; // Level placement of token
        uint tile; // Tile placement of token
        uint resourceLvl; // Amount of resource present on token
        uint resourceDirection; // Direction resource is flowing
        uint status; // Terrain status enum, cast as an integer from 0 - 4
        uint font; // Font index
        uint fontSize; // Font size 
        uint charsIndex; // Character set index
        string zoneName; // Name of token zone
        string[9] chars; // Token's character array
        string[10] zoneColors; // Token's zone colors
    }

    /// @notice Struct for passing animation information to <style> generator
    /// @dev Times are in milliseconds
    struct AnimParams {
        Activation activation; // Animation type
        uint classesAnimated; // Number of levels animated
        uint duration; // Base animation duration for first class
        uint durationInc; // Duration increment for each class
        uint delay; // Base delay for first class
        uint delayInc; // Delay increment for each class
        uint bgDuration; // Animation duration for background
        uint bgDelay; // Delay for background
        string easing; // Animation mode, e.g. steps(), linear, ease-in-out
        string[2] altColors; // Alternate colors for Plague tokens
    }

    /// @notice Struct for tracking state of the URI generator
    struct CTX {
        uint val; // Current character being drawn
        string char; // current character
        string class; // CSS class to apply to current character
        string[32] colBuf; // Buffer for compiling columns of SVG elems
        string[32] rowBuf; // Buffer for compiling rows of SVG elems
        string[3] iterBuf; // Reusable buffer for compiling in loops
        AnimParams a; // Animation parameters
    }

    /// @notice the activation of a tile, which affects its movement speed
    enum Activation {Cascade, Plague}

    // Address for storing fonts and character sets
    address terraformsCharactersAddress;
    
    // CSS class selectors to be used to apply styling to individual characters
    string[11] classes = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"];
    
    // JavaScript included in animated SVGs
    string jsString = unicode";function map(e,t,r,i,a){return i+(a-i)*(e-t)/(r-t)}RESOURCE/=1e4;let isDaydream=1==MODE||3==MODE,isTerraformed=2==MODE||4==MODE,isOrigin=3==MODE||4==MODE,classIds=['i','h','g','f','e','d','c','b','a'],charSet=[],uni=[9600,9610,9620,3900,9812,9120,9590,143345,48,143672,143682,143692,143702,820,8210,8680,9573,142080,142085,142990,143010,143030,9580,9540,1470,143762,143790,143810];function makeSet(e){let t=[];for(let r=e;r&lt;e+10;r++)t.push(String.fromCharCode(r));return t}let newSet,originalChars=[];for(let e of classIds){let t=document.querySelector('.'+e);if(t){let e=t.textContent;originalChars.push(e)}}if(charSet.push(originalChars),isOrigin)if(SEED&gt;9e3)for(let e of uni)charSet.push(makeSet(e));else charSet.push(makeSet(uni[Math.floor(SEED)%uni.length]));else if(SEED&gt;9970)for(let e of uni)charSet.push(makeSet(e));else SEED&gt;5e3&amp;&amp;charSet.push(makeSet(uni[Math.floor(SEED)%3]));charSet=charSet.flat();let mainSet=originalChars.reverse();SEED&gt;9950&amp;&amp;(mainSet=charSet);let gridEls=document.querySelectorAll('p'),grid=[],brushSize=2,pointerDown=!1,pointerShift=0,isEraser=!1,loopLength=10,airship=0;function erase(e){e.activeClass='j',e.setAttribute('class','j'),e.h=9,e.textContent}function draw(e){let t=classIds[pointerShift%classIds.length];e.activeClass=t,e.setAttribute('class',t),e.h=pointerShift%classIds.length}for(let e=0;e&lt;32;e++){grid.push([]);for(let t=0;t&lt;32;t++){let r=gridEls[t+32*e];grid[e][t]=r,r.originalClass=r.className,r.activeClass=r.originalClass,r.h=classIds.length-classIds.indexOf(r.originalClass)-1,r.originalH=r.h,isDaydream&amp;&amp;(r.style.webkitUserSelect='none',r.style.userSelect='none'),r.onpointermove=(i=&gt;{if(pointerDown&amp;&amp;isDaydream){for(let r=-brushSize;r&lt;brushSize;r++)for(let i=-brushSize;i&lt;brushSize;i++){let a=grid[Math.min(Math.max(0,e+r),31)][Math.min(Math.max(0,t+i),31)];isEraser?erase(a):draw(a)}isEraser?erase(r):draw(r)}})}}let speedFac=SEED&gt;6500?30:1;setInterval(()=&gt;{for(let e=0;e&lt;32;e++)for(let t=0;t&lt;32;t++){let r=gridEls[t+32*e];0==MODE?r.h&gt;6-RESOURCE&amp;&amp;(r.textContent=mainSet[Math.floor(.25*airship+(r.h+.5*e+.1*DIRECTION*t))%mainSet.length]):(isDaydream||isTerraformed)&amp;&amp;(0==r.h?SEED&lt;8e3?r.textContent=mainSet[Math.floor(airship/1e3+.05*e+.005*t)%mainSet.length]:r.textContent=mainSet[Math.floor(airship/2+.05*e)%mainSet.length]:(r.textContent=charSet[Math.floor(airship/speedFac+e+r.h)%charSet.length],SEED&gt;5e3&amp;&amp;Math.random()&lt;.005&amp;&amp;(r.style.fontSize=`${3+airship%34}px`))),'j'!=r.originalClass&amp;&amp;'j'!=r.activeClass||(r.textContent=' ')}airship+=1},loopLength),document.addEventListener('keyup',e=&gt;{'e'==e.key&amp;&amp;(isEraser=!1)}),document.addEventListener('keydown',e=&gt;{'e'==e.key?isEraser=!0:'q'==e.key?brushSize=(brushSize+1)%4:'a'==e.key&amp;&amp;pointerShift++}),document.querySelector('svg').onpointerdown=(()=&gt;{pointerShift++,pointerDown=!0}),document.querySelector('svg').onpointerup=(()=&gt;{pointerDown=!1;for(let e of gridEls)e.style.animation='none',e.offsetHeight,e.style.animation=null}),document.querySelector('svg').onpointerleave=(()=&gt;{pointerDown=!1});</script>";
    
    /// @notice whether new jsStrings may be uploaded by the contract owner
    bool public isLocked = false;
    
    constructor (address _terraformsCharactersAddress) Ownable() {
        terraformsCharactersAddress = _terraformsCharactersAddress;
    }

    /// @notice Returns the token SVG
    /// @param p is a SVGParams struct passed from TerraformsData
    /// @param a is an AnimParams struct passed from TerraformsData
    /// @return svgMain opening svg tag and css declarations except keyframes
    /// @return animations css animations
    /// @return script closing svg tag and svg elements
    function makeSVG(
        SVGParams memory p, 
        AnimParams memory a
    )
        public 
        view 
        returns (
            string memory svgMain, 
            string memory animations,
            string memory script
        )
    {
        
        CTX memory ctx;

        // Certain fonts are bold
        string memory boldString;
        if (p.charsIndex < 14 || (p.charsIndex > 33 && p.charsIndex < 37)){ 
            boldString = 'font-weight:bold;';
        }

        //Start SVG string and create style elem for inline styling
        string memory svgHeader = string(
            abi.encodePacked(
                "<svg version='2.0' encoding='utf-8' viewBox='0 0 388 560' preserveAspectRatio='xMidYMid' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns='http://www.w3.org/2000/svg'><style>@font-face {font-family:'MathcastlesRemix-Regular';font-display:block;src:url(data:application/font-woff2;charset=utf-8;base64,",
                ITerraformsCharacters(terraformsCharactersAddress).font(p.font),
                ") format('woff');}.meta{width:388px;height:560px;}.r{box-sizing: border-box;width:388px;height:560px;padding:24px;font-size:",
                 ToString.toString(p.fontSize),
                 "px;",
                 boldString,
                 "display:grid;grid-template-columns:repeat(32, 3%);grid-template-rows: repeat(32, 16px);grid-gap: 0px;justify-content: space-between;}p{font-family:'MathcastlesRemix-Regular',monospace;margin:0;text-align: center;display:flex;justify-content:center;align-items:center;}",
                 generateCSSColors(p.zoneColors),
                 "</style><foreignObject x='0' y='0' width='388' height='560'><div class='meta' xmlns='http://www.w3.org/1999/xhtml'><div class='r'>"
            )
        );
        uint col;
        // Assemble rows of SVG       
        for (uint row; row < 32; row++) {          
            // Step through uint[32][32] of indices into char array
            for (col = 0; col < 32; col++) {
                ctx.val = p.heightmapIndices[row][col];
                // Index into base char array and get associated class
                // If index > 8, we're at the background so use a space
                ctx.char = ctx.val < 9 ? p.chars[ctx.val] : "&#160;";
                ctx.class = classes[ctx.val];
                // Encode each char in the row in a <p> tag
                ctx.colBuf[col] = string(
                    abi.encodePacked(
                        "<p class='", 
                        ctx.class, 
                        "'>", 
                        ctx.char,
                        "</p>"
                    )
                );
            }

            // Compile the columns of this row into the row buffer
            for(uint i; i < 3; i++){
                ctx.iterBuf[i] = string(
                    abi.encodePacked(
                        ctx.colBuf[i * 10],
                        ctx.colBuf[i * 10 + 1],
                        ctx.colBuf[i * 10 + 2],
                        ctx.colBuf[i * 10 + 3],
                        ctx.colBuf[i * 10 + 4],
                        ctx.colBuf[i * 10 + 5],
                        ctx.colBuf[i * 10 + 6],
                        ctx.colBuf[i * 10 + 7],
                        ctx.colBuf[i * 10 + 8],
                        ctx.colBuf[i * 10 + 9]
                    )
                );
            }
    	    // Compile the last few columns into the row buffer
            ctx.rowBuf[row] = string(
                abi.encodePacked(
                    ctx.iterBuf[0],
                    ctx.iterBuf[1],
                    ctx.iterBuf[2],
                    ctx.colBuf[30],
                    ctx.colBuf[31]
                )
            );
        }

        // Compile the rows into single string
        for(uint i; i < 3; i++){
            ctx.iterBuf[i] = string(
                abi.encodePacked(
                    ctx.rowBuf[i*10],
                    ctx.rowBuf[i*10 + 1],
                    ctx.rowBuf[i*10 + 2],
                    ctx.rowBuf[i*10 + 3],
                    ctx.rowBuf[i*10 + 4],
                    ctx.rowBuf[i*10 + 5],
                    ctx.rowBuf[i*10 + 6],
                    ctx.rowBuf[i*10 + 7],
                    ctx.rowBuf[i*10 + 8],
                    ctx.rowBuf[i*10 + 9]
                )
            );
        }

        // Compile the main SVG, leaving the <style> tag open for the keyframes
        svgMain = string(
            abi.encodePacked(
                svgHeader,
                ctx.iterBuf[0],
                ctx.iterBuf[1],
                ctx.iterBuf[2], 
                ctx.rowBuf[30], 
                ctx.rowBuf[31],
                '</div></div></foreignObject><style>body, svg{overflow-x:hidden; overflow-y: hidden; margin:0; padding:0}'
            )
        );
        // Generate CSS animation, keyframes and JavaScript
        animations = generateAnimations(a, p.zoneColors);
        script = generateScript(p);
    }

    /// @notice generates CSS for coloring characters at each height value
    /// @param colors the color scheme of the token's zone
    function generateCSSColors(string[10] memory colors) 
        internal 
        view 
        returns (string memory) 
    {
        string[10] memory buf;
        // Generate CSS style declarations and class assignments for each color
        for (uint i; i < 9; i ++){
            buf[i] = setCSSColor(classes[i], colors[i]);
        }
        // Set the background color to the last color in the array
        buf[9] = string(
                abi.encodePacked('.r{background-color:',colors[9],';}')
        );
        return string(
            abi.encodePacked(
                buf[0],
                buf[1],
                buf[2],
                buf[3],
                buf[4],
                buf[5],
                buf[6],
                buf[7],
                buf[8],
                buf[9]
            )
        );
    }

    /// @notice Generates style definitions for all classes in SVG
    /// @param a the animation parameters
    /// @param colors the color scheme of the token's zone
    /// @return a string representing the SVG's style definitions
    function generateAnimations(AnimParams memory a, string[10] memory colors) 
        internal 
        view 
        returns (string memory)
    {
        string[10] memory buf;
        // classesAnimated is a uint with each digit representing an index
        // the digits are in descending order from right to left
        uint animated = a.classesAnimated;
        // Used for varying animation delay and duration
        uint multiplier; 

        // Iterate through classes and check whether they're animated
        for (uint i; i < 9; i ++){
            // If the last digit == i, it is animated
            if (i == animated % 10) {
                buf[i] = setForegroundAnimation(a, i, multiplier);
                multiplier += 1; // Increment the multiplier
                animated = animated / 10; // Move to next digit
            }
        }

        // Plague tokens have background animations
        if (a.activation == Activation.Plague){
            buf[9] = setBackgroundAnimation(a);
        }

        // Generate CSS keyframes
        string memory keyframes = setKeyframes(
            a.activation, 
            colors, 
            a.altColors
        ); 

        return string(
            abi.encodePacked(
                buf[0],
                buf[1],
                buf[2],
                buf[3],
                buf[4],
                buf[5],
                buf[6],
                buf[7],
                buf[8],
                buf[9],
                keyframes
            )
        );
    }

    /// @notice Styles a CSS class for a background with animation
    /// @param a the animation parameters
    /// @return a string representing a style on a class selector
    function setBackgroundAnimation(
        AnimParams memory a
    )
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                '.r{animation: z ',
                ToString.toString(a.bgDuration),
                'ms ',
                a.easing,
                ToString.toString(a.bgDelay),
                'ms infinite;}'
            )
        );
    }

    /// @notice Styles a CSS class with animation
    /// @param a the animation parameters
    /// @param class  index of the character being styled in the char/color arrs
    /// @param multiplier the multiplier for delay and duration increments
    /// @return result A string representing a style on a class selector
    function setForegroundAnimation(
        AnimParams memory a, 
        uint class,
        uint multiplier
    ) 
        internal 
        view 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '.',
                classes[class],
                '{animation:x ',
                ToString.toString(a.duration + a.durationInc*multiplier),
                'ms ',
                ToString.toString(a.delay + a.delayInc*multiplier),
                a.easing,
                ' infinite;}'
            )
        );
    }

    /// @notice Styles a CSS class without animation
    /// @param class the class selector to use
    /// @param color the color to use
    /// @return A string representing a style on a class selector
    function setCSSColor(string memory class, string memory color) 
        internal 
        pure 
        returns (string memory) 
    {
        return string(abi.encodePacked('.', class, '{color:', color,';}'));
    }

    /// @notice Generates CSS animation keyframes
    /// @param activation the token's activation
    /// @param colors the color scheme of the token's zone
    /// @param altColors alt colors of a Plague token
    /// @return a string representing a style on a class selector
    function setKeyframes(
        Activation activation, 
        string[10] memory colors, 
        string[2] memory altColors
    ) 
        internal 
        pure 
        returns (string memory)
    {
        // Plague tokens' backgrounds alternate between two colors
        if (activation == Activation.Plague) {
            return string(
                abi.encodePacked(
                    '@keyframes x{0%{color:',
                    altColors[0],
                    ';}50%{color:',
                    altColors[1],
                    '}}@keyframes z{0%{background-color:',
                    altColors[0],
                    ';}50%{background-color:',
                    altColors[1]
                )
            );
        } else { // Foreground animations cycle through colors
            string[11] memory buf;
            buf[0] = '@keyframes x{';
            for(uint i; i < 10; i++){
                buf[i+1] = string(
                    abi.encodePacked(
                        ToString.toString(i * 10),
                        '%{color:',
                        colors[i % 10],
                        ';}'
                    )
                );
            }

            return string(
                abi.encodePacked(
                    buf[0],
                    buf[1],
                    buf[2],
                    buf[3],
                    buf[4],
                    buf[5],
                    buf[6],
                    buf[7],
                    buf[8],
                    buf[9],
                    buf[10],
                    '}'
                )
            );
        }
    }

    /// @notice generates Javascript for inclusion in animated tokens
    /// @param p is a SVGParams struct passed from TerraformsData
    function generateScript(SVGParams memory p) 
        internal 
        view 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                "<script>let MODE=",
                ToString.toString(p.status),
                ";let RESOURCE=",
                ToString.toString(p.resourceLvl),
                ";let DIRECTION=",
                ToString.toString(p.resourceDirection),
                ";const SEED=",
                ToString.toString(
                    uint(keccak256(abi.encodePacked(p.level, p.tile))) % 10_000
                ),
                jsString
            )
        );
    }

    /// @notice permits owner to modify Javascript included in tokens
    /// @param js the new Javascript string
    function setJS(string memory js) public onlyOwner {
        require(!isLocked);
        jsString = js;
    }

    /// @notice locks the contract, preventing further modifications
    function lock() public onlyOwner {
        isLocked = true;
    }
}