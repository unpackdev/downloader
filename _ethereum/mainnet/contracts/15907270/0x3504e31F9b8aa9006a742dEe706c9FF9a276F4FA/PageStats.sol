//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./web0.sol";
import "./Strings.sol";

//////////////////////
//
// PageStats
// A web0 plugin
//
//////////////////////


contract PageStats is web0plugin {

    function info() public override pure returns(Info memory){
        return Info('PageStats', new ParamInfo[](0));
    }

    function body(uint page_id_, Param[] memory, bool, address web0_address_) public override view returns(string memory){

        web0 web0_ = web0(web0_address_);

        bytes memory bhtml_ = abi.encodePacked(
            '<div id="PageStats">',
            'ID: ', Strings.toString(page_id_), '<br/>',
            'Plugins:<br/>'
        );

        web0plugins.Plugin[] memory plugins_ = web0_.plugins().list(page_id_);

        for (uint i = 0; i < plugins_.length; i++) {
            bhtml_ = abi.encodePacked(bhtml_, '- ', plugins_[i].name, ' <small>(slot ', Strings.toString(plugins_[i].slot),')</small><br/>');
        }

        bhtml_ = abi.encodePacked(bhtml_, '</div>');

        return string(bhtml_);

    }


}