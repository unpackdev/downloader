//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./base64.sol";
import "./web0.sol";
import "./Esc.sol";
import "./Rando.sol";


//////////////////////
//
// web0template
//
//////////////////////

contract web0template_1 is web0template {


    struct HTML {
        bytes head;
        bytes body;
    }


    string public constant LOGO = 'data:@file/gif;base64,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';

    constructor(){

    }

    //////////////////////////
    // HTML
    //////////////////////////


    function previewHtml(uint page_id_, web0plugins.PluginInput[] memory preview_, bool encode_, address web0_) public view override returns(string memory html_) {

        web0plugins.Plugin[] memory preview_plugins_ = new web0plugins.Plugin[](preview_.length);
        for (uint i = 0; i < preview_.length; i++){
            preview_plugins_[i] = web0plugins.Plugin(web0plugin(preview_[i].location).info().name, preview_[i].location, preview_[i].slot, preview_[i].params);
        }

        return _html(page_id_, encode_, preview_plugins_, web0(web0_));

    }

    function html(uint page_id_, bool encode_, address web0_) public view override returns(string memory html_){
        return _html(page_id_, encode_, new web0plugins.Plugin[](0), web0(web0_));
    }

    function _html(uint page_id_, bool encode_, web0plugins.Plugin[] memory preview_, web0 web0_) private view returns(string memory html_){

        web0plugins.Plugin[] memory plugins_ = web0_.plugins().list(page_id_);

        uint max_slots_ = web0_.MAX_SLOTS();

        bytes[] memory body_parts_ = new bytes[](max_slots_);
        bytes[] memory head_parts_ = new bytes[](max_slots_);

        uint i = 0;
        while(i < plugins_.length){
            head_parts_[plugins_[i].slot-1] = bytes(web0plugin(plugins_[i].location).head(page_id_, plugins_[i].params, false, address(web0_)));
            body_parts_[plugins_[i].slot-1] = bytes(web0plugin(plugins_[i].location).body(page_id_, plugins_[i].params, false, address(web0_)));
            ++i;
        }
        
        i = 0;
        while(i < preview_.length){
            if(preview_[i].location != address(0)){
                head_parts_[preview_[i].slot-1] = bytes(web0plugin(preview_[i].location).head(page_id_, preview_[i].params, true, address(web0_)));
                body_parts_[preview_[i].slot-1] = bytes(web0plugin(preview_[i].location).body(page_id_, preview_[i].params, true, address(web0_)));
            }
            ++i;
        }

        HTML memory HTML_ = HTML(
            '',
            ''
        );

        
        i = 0;
        while(i < body_parts_.length) {
            HTML_.body = abi.encodePacked(HTML_.body, body_parts_[i]);
            HTML_.head = abi.encodePacked(HTML_.head, head_parts_[i]);
            ++i;
        }

        html_ = string(abi.encodePacked(
            '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>',
            web0_.getPageTitle(page_id_),
            '</title>',
            HTML_.head,
            '</head><body><main>',
            '<h1 id="page-title">',
            Esc.html(web0_.getPageTitle(page_id_)),
            '</h1>',
            HTML_.body,
            '</main></body></html>'
        ));

        if(encode_)
            html_ = string(abi.encodePacked('data:text/html;charset=UTF-8;base64,',Base64.encode(bytes(html_))));
        
        return html_;

    }


    

    /// @notice outputs the json of page_id_
    function json(uint page_id_, bool encode_, address web0_address_) public view override returns(string memory){

        web0 web0_ = web0(web0_address_);

        bytes memory image_ = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 1000" preserveAspectRatio="xMinYMin meet">',
                '<defs><style>.txt {font-family: Times New Roman, serif; font-size:20px; font-weight: normal; letter-spacing: 0.01em; fill: black; text-align:center; font-style: italic;}</style><rect ry="35" rx="35" id="bg" height="1000" width="600" fill="white"/><filter id="invert"><feComponentTransfer><feFuncR type="table" tableValues="1 0"/><feFuncG type="table" tableValues="1 0"/><feFuncB type="table" tableValues="1 0"/></feComponentTransfer></filter></defs>',
                '<g',page_id_ == 0 ? ' filter="url(#invert)"' : '','>',
                    '<use href="#bg"/>',
                    '<image href="',LOGO,'" width="450" x="65" y="250"/>',
                    '<text class="txt" x="50%" y="60%" dominant-baseline="middle" text-anchor="middle">web0 page #',Strings.toString(page_id_),'</text>',
                '</g>'
            '</svg>'
        );


        bytes memory json_ = abi.encodePacked(
            '{',
                '"name": "web0 page #',Strings.toString(page_id_),'",',
                '"description": "",',
                '"image": "',abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(image_)),'",',
                '"plugins":' ,web0_.plugins().json(page_id_), ',',
                '"attributes": [',
                    '{"trait_type": "id", "value": ',Strings.toString(page_id_),'},'
                    '{"trait_type": "plugins", "value": "',Strings.toString(web0_.plugins().count(page_id_)),'"}'
                ']',
            '}'
        );

        if(encode_)
            json_ = abi.encodePacked('data:application/json;base64,', Base64.encode(json_));

        return string(json_);
    }



}
