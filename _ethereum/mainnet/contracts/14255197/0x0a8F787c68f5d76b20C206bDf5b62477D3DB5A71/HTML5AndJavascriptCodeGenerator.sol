// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Base64.sol";

/*            _       _           _              
 *  _ __ ___ (_)_ __ (_)_ __ ___ (_)_______ _ __ 
 * | '_ ` _ \| | '_ \| | '_ ` _ \| |_  / _ \ '__|
 * | | | | | | | | | | | | | | | | |/ /  __/ |   
 * |_| |_| |_|_|_| |_|_|_| |_| |_|_/___\___|_|   
 * 
 * @title HTML5AndJavascriptCodeGenerator
 * @author minimizer <me@minimizer.art>; https://minimizer.art/
 * 
 * Utility library to generate a full stand-alone HTML page for a 
 * generative pure JavaScript/HTML5 Canvas artwork. 
 * 
 * Given the token name, token id, hash and rendering code, can produce 
 * results in plain-text or in base64 (useful for transfering, e.g Etherscan)
 */
library HTML5AndJavascriptCodeGenerator {
    
    using Strings for uint;
    using Strings for bytes32;
    
    // Retreive the rendering code in plain text, for a given token, by combining the token id 
    // and hash with the rendering code. This assumes the language is javascript.
    function fullRenderingCode(string memory name_, uint tokenId_, 
                               bytes32 tokenHash_, string memory renderingCode_) 
        public pure 
        returns (string memory) 
    {
        return bytes(renderingCode_).length == 0 ? "" :
            string(abi.encodePacked(bytes("<!DOCTYPE html><html><head><title>"),
                                    bytes(name_),
                                    bytes(" #"),
                                    bytes(tokenId_.toString()),
                                    bytes("</title></head><body style='padding:0;margin:0;border:0;justify-content:center;display:flex;background-color:black'><canvas /><script>"),
                                    bytes("const tokenData={tokenId:"), 
                                    bytes(tokenId_.toString()),
                                    bytes(",hash:'"),
                                    uint(tokenHash_).toHexString(),
                                    bytes("'};"),
                                    bytes(renderingCode_),
                                    bytes("</script></body></html>")));
    }
    
    // Similar to the above plain-text version, this retrieves the rendering code in Base64 encoding. This is 
    // useful in cases where the encoding is required or helpful for transmission.
    function fullRenderingCodeInBase64(string memory name_, uint tokenId_, 
                                       bytes32 tokenHash_, string memory renderingCode_)
       public pure
       returns (string memory) 
    {
        return Base64.encode(bytes(fullRenderingCode(name_, tokenId_, tokenHash_, renderingCode_)));
    }
}