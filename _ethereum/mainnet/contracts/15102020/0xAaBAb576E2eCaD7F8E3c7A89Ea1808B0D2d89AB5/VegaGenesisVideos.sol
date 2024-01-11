// SPDX-License-Identifier: UNLICENSED

/**
::::::'##:'##::::'##:'##::: ##:'####::'#######::'########:::::::::::'##:'########::
:::::: ##: ##:::: ##: ###:: ##:. ##::'##.... ##: ##.... ##:::::::::: ##: ##.... ##:
:::::: ##: ##:::: ##: ####: ##:: ##:: ##:::: ##: ##:::: ##:::::::::: ##: ##:::: ##:
:::::: ##: ##:::: ##: ## ## ##:: ##:: ##:::: ##: ########::::::::::: ##: ########::
'##::: ##: ##:::: ##: ##. ####:: ##:: ##:::: ##: ##.. ##::::::'##::: ##: ##.. ##:::
 ##::: ##: ##:::: ##: ##:. ###:: ##:: ##:::: ##: ##::. ##::::: ##::: ##: ##::. ##::
. ######::. #######:: ##::. ##:'####:. #######:: ##:::. ##::::. ######:: ##:::. ##:
:......::::.......:::..::::..::....:::.......:::..:::::..::::::......:::..:::::..::
'##::::'##:'##::::'##::'######::'####::'######::                                   
 ###::'###: ##:::: ##:'##... ##:. ##::'##... ##:                                   
 ####'####: ##:::: ##: ##:::..::: ##:: ##:::..::                                   
 ## ### ##: ##:::: ##:. ######::: ##:: ##:::::::                                   
 ##. #: ##: ##:::: ##::..... ##:: ##:: ##:::::::                                   
 ##:.:: ##: ##:::: ##:'##::: ##:: ##:: ##::: ##:                                   
 ##:::: ##:. #######::. ######::'####:. ######::                                   
..:::::..:::.......::::......:::....:::......:::                                   
'##::::'##:'####:'########::'########::'#######:::'######::                        
 ##:::: ##:. ##:: ##.... ##: ##.....::'##.... ##:'##... ##:                        
 ##:::: ##:: ##:: ##:::: ##: ##::::::: ##:::: ##: ##:::..::                        
 ##:::: ##:: ##:: ##:::: ##: ######::: ##:::: ##:. ######::                        
. ##:: ##::: ##:: ##:::: ##: ##...:::: ##:::: ##::..... ##:                        
:. ## ##:::: ##:: ##:::: ##: ##::::::: ##:::: ##:'##::: ##:                        
::. ###::::'####: ########:: ########:. #######::. ######::                        
:::...:::::....::........:::........:::.......::::......:::                                
**/

/// @notice This contrtact shows info 
/// of Junior Jr music videos 
/// a project made by @VegaGenesisTM (Vegagenesis.eth)
/// @author dev.aurelianoa.eth

pragma solidity ^0.8.9;

import "./Ownable.sol";

/// @dev i think Vegagenesis will be big, so his videos releases
/// will be logged on-chain
/// LFG 🔥

contract VegaGenesisVideos is Ownable {

    struct VideoData {
        string fullName;
        string linkURL;
    }
    mapping(string => VideoData) private videos;
    string private wenNextRelease = "soon";

    function registerVideo(string memory codeName, string memory fullName, string memory linkURL) external onlyOwner {
        VideoData memory data = VideoData(fullName, linkURL);
        videos[codeName] = data;
    }

    function registerNextVideorelease(string memory humaDate) external onlyOwner {
        wenNextRelease = humaDate;
    }

    function showMeTheVideoLink(string memory codeName) external view returns (string memory) {
        return videos[codeName].linkURL;
    }

    function showMeTheVideoName(string memory codeName) external view returns (string memory) {
        return videos[codeName].fullName;
    }

    function wenNextVideo() external view returns (string memory) {
        return wenNextRelease;
    }
}