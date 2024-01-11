pragma solidity >=0.8.0 <0.9.0;

import "./base64.sol";
import "./Utils.sol";
import "./PlexSansLatin.sol";
import "./PlexSubset.sol";
import "./Strings.sol";

library NFTImage {
    // For the UGC aspect we have available all the Latin characters. For the other two fonts
    // I extracted only the characters I needed with a tool called subfont. The declarations
    // should use unique font names because you can't be sure that what you say in SVGs "stays
    // in SVGs"
    function fontDeclarations() public pure returns (string memory) {
        string memory plexSans = PlexSansLatin.getIBMPlexSansLatin();
        string memory plexMono = PlexSubset.getIBMPlexMonoSubset();
        string memory plexSansCondensed = PlexSubset.getIBMPlexSansCondensedSubset();
        
        string memory plexSansUnicodeRange = PlexSansLatin.getIBMPlexSansLatinUnicodeRange();
        string memory plexMonoUnicodeRange = PlexSubset.getIBMPlexMonoSubsetUnicodeRange();
        string memory plexSansCondensedUnicodeRange = PlexSubset.getIBMPlexSansCondensedSubsetUnicodeRange();
        
        bytes memory plexSansDeclaration = abi.encodePacked(
            "@font-face{font-family:'IBM Plex Sans_ww4az6WSyhEj3oM7';src:url(",
            plexSans,
            ") format('woff2');unicode-range:",
            plexSansUnicodeRange,
            ";}"
        );
        
        bytes memory plexMonoDeclaration = abi.encodePacked(
            "@font-face{font-family:'IBM Plex Mono_ww4az6WSyhEj3oM7';src:url(",
            plexMono,
            ") format('woff2');unicode-range:",
            plexMonoUnicodeRange,
            ";}"
        );
        
        bytes memory plexSansCondensedDeclaration = abi.encodePacked(
            "@font-face{font-family:'IBM Plex Sans Condensed_ww4az6WSyhEj3oM7';src:url(",
            plexSansCondensed,
            ") format('woff2');unicode-range:",
            plexSansCondensedUnicodeRange,
            ";}"
        );
        
        return string(abi.encodePacked(plexSansDeclaration, plexMonoDeclaration, plexSansCondensedDeclaration));
    }
    
    function sansFontStack() public pure returns (string memory) {
        return 'font-family:"IBM Plex Sans_ww4az6WSyhEj3oM7","Helvetica Neue",Arial,sans-serif;';
    }
    
    function monoFontStack() public pure returns (string memory) {
        return 'font-family:"IBM Plex Mono_ww4az6WSyhEj3oM7","Menlo","DejaVu Sans Mono","Bitstream Vera Sans Mono",Courier,monospace;';
    }
    
    function sansCondensedFontStack() public pure returns (string memory) {
        return 'font-family:"IBM Plex Sans Condensed_ww4az6WSyhEj3oM7","Helvetica Neue",Arial,sans-serif;';
    }
    
    function normalizedFontSize(uint8 fs) internal pure returns (uint8) {
        if (
               fs == 14
            || fs == 20
            || fs == 24
            || fs == 28
            || fs == 32
            || fs == 42
            || fs == 60
            || fs == 76
            || fs == 92
         ) {
            return fs;
        } else {
            return 16;
        }
    }
    
    // If you want to you can play around with line heights for a very long time, it turns out
    function buildLineHeight(uint8 fontSize) internal pure returns (string memory) {
        uint8 fs = normalizedFontSize(fontSize);
        
        if (fs == 14) {
            return "1.429";
        } else if (fs == 16) {
            return "1.5";
        } else if (fs == 20) {
            return "1.4";
        } else if (fs == 24) {
            return "1.3";
        } else if (fs == 28) {
            return "1.275";
        } else if (fs == 32) {
            return "1.25";
        } else if (fs == 42) {
            return "1.2";
        } else if (fs == 60) {
            return "1.15";
        } else if (fs == 76) {
            return "1.13";
        } else if (fs == 92) {
            return "1.1";
        } else {
            return "1.5";
        }
    }
    
    function buildFontMetrics(uint8 fontSize) internal pure returns (bytes memory) {
        string memory nfs = Strings.toString(normalizedFontSize(fontSize));
        string memory lineHeight = buildLineHeight(fontSize);
        
        bytes memory output = abi.encodePacked(
            "font-size:", nfs,
            "px;line-height:", lineHeight,
            ";"
        );
        
        if (fontSize == 14) {
            output = abi.encodePacked(output, "letter-spacing:.16px;");
        }
        
        return output;
    }
    
    // You can't get 11.111111% from 100 / 9 in Solidity so we do the calculation in CSS
    // Probably could have just hard coded the string...
    function buildGradientColorStepBytes(uint24[10] memory gradientColors) internal pure returns (bytes memory) {
        bytes memory colorSteps;
        
        for (uint8 i = 0; i < gradientColors.length; i++) {
            if (i > 0) {
                colorSteps = abi.encodePacked(colorSteps, ", ");
            }
            
            colorSteps = abi.encodePacked(
                colorSteps,
                "#",
                Utils.toHexColor(gradientColors[i]),
                " ",
                abi.encodePacked("calc(", Strings.toString(i), "*100%/", Strings.toString(gradientColors.length - 1), ")")
            );
        }
        
        return colorSteps;
    }
    
    function buildGradientString(
      bool isRadialGradient,
      uint16 linearGradientAngleDeg,
      uint24[10] memory gradientColors
    ) internal pure returns (bytes memory) {
        bytes memory colorStepString = buildGradientColorStepBytes(gradientColors);
        
        if (isRadialGradient) {
            return abi.encodePacked(
                "radial-gradient(at 50% 100%, ", colorStepString, ")"
            );
        } else {
            return abi.encodePacked(
                "linear-gradient(",
                Strings.toString(linearGradientAngleDeg),
                "deg, ",
                colorStepString,
                ")"
            );
        }
    }
    
    // Ok finally! The image! There are a few key points here.
    // First, the foundation of this approach is the <foreignObject> tag. This element gives you the
    // ability to use arbitrary HTML in an SVG which is essential for a project like this because
    // HTML has built-in line wrapping and you need line wrapping if you're going to put user input
    // into a box and have it look reasonable.
    //
    // foreignObject is not without quirks, however. The biggest issue is that when you use an SVG
    // with a foreignObject as an <img> src you cannot resize the image correctly in Safari (it will crop).
    // This almost sunk the project until, after a very long time of trying random things, I stumbled on
    // a random thing that worked!
    //
    // You take the SVG containing the foreignObject, you base64 it, you create *another* SVG with an <image>
    // element. You put the first SVG as the href of the <image> element. Then you base64 *that* SVG
    // (the second one) and use that base64 value as the src on your HTML <img> tag! This is
    // wasteful as each base64 increases the file size by a factor of 4/3, but I promise I couldn't
    // find another way to do it!
    function tokenImage(
      string[2] memory messageIdandText,
      uint24 textColor,
      bool isRadialGradient,
      uint8 fontSize,
      uint16 linearGradientAngleDeg,
      uint24[10] memory gradientColors,
      uint mintedAt,
      string memory minter,
      string[2] memory widthAndHeight
    ) internal pure returns (string memory) {
        string[14] memory parts;
        
        parts[0] = string(buildGradientString(
            isRadialGradient,
            linearGradientAngleDeg,
            gradientColors
        ));
        
        // I use 390 as the native size of the image because it corresponds to the iPhone 13 pro
        parts[1] = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 487.5' class='x3fvufWE1e3H1xpo'><foreignObject x='0' y='0' width='390' height='487.5'><div style='background:";
        
        parts[2] = ";color:#";
        
        parts[3] = string(abi.encodePacked(";position:absolute;top:0;left:0;width:100%;height:100%;display:flex;flex-direction:column' xmlns='http://www.w3.org/1999/xhtml'><style>",
        
        fontDeclarations(),
        
        // That's right, I'm pro -webkit-font-smoothing:antialiased! Sorry haters! Also note that I'm
        // using white-space: pre-wrap here in order to preserve the user's formatting. This is what
        // textareas do for whitespace so the message will look like the input. This is important because
        // converting user-input to actual HTML with <p> tags and everything is not feasible in Solidity
        "svg.x3fvufWE1e3H1xpo,svg.x3fvufWE1e3H1xpo *{", monoFontStack(), "box-sizing:border-box;margin:0;padding:0;border:0;-webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility;overflow-wrap:break-word}</style><div style='", buildFontMetrics(fontSize), sansFontStack(), "flex:1;padding:16px;white-space:pre-wrap;overflow:hidden'>"));
        
        parts[4] = string(abi.encodePacked("</div><div style='white-space:pre;background:rgba(0,0,0,.5);color:#fff;padding:16px;font-size:12px;line-height:calc(4/3);display:flex;flex-direction:column'><div style='", sansCondensedFontStack(), "letter-spacing:1.25px;font-weight:500;margin-bottom:8px'>FOREVER MSG #"));
        
        parts[5] = "</div><div>from   ";
        
        parts[6] = "\ndate   ";
        
        parts[7] = "</div></div></div></foreignObject></svg>";
        
        parts[8] = Base64.encode(abi.encodePacked(
            abi.encodePacked(parts[1], parts[0]),
            abi.encodePacked(parts[2], Utils.toHexColor(textColor)),
            abi.encodePacked(parts[3], Utils.escapeHTML(messageIdandText[1])),
            abi.encodePacked(parts[4], messageIdandText[0]),
            abi.encodePacked(parts[5], minter),
            abi.encodePacked(parts[6], Utils.timestampToString(mintedAt)),
            parts[7]
        ));
        
        // What is happening!!
        parts[9] = string(abi.encodePacked("<svg viewBox='0 0 390 487.5' width='", widthAndHeight[0], "' height='", widthAndHeight[1], "' xmlns='http://www.w3.org/2000/svg'><image width='100%' height='100%' href='data:image/svg+xml;base64,"));
        parts[10] = "' /></svg>";
        
        parts[11] = Base64.encode(abi.encodePacked(
            parts[9],
            parts[8],
            parts[10]
        ));
        
        return string(abi.encodePacked("data:image/svg+xml;base64,", parts[11]));
    }
}
