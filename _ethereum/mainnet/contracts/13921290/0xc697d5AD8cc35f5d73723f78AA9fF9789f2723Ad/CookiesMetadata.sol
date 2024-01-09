// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";

import "./Base64.sol";

import "./IRenderingFortunes.sol";
import "./I_TokenData.sol";

import "./Controllable.sol";

contract CookiesMetadata is Ownable, Controllable, I_TokenData {

    using Strings for uint256;

    uint256 constant MAX_SUPPLY = 20000;
    string constant HEADER = '<svg class="svgBody" width="640" height="640" viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg" version="1.1">';
    uint256 indexOffset; //set this for reveal

    IRenderingFortunes public renderer;

    mapping (uint256 => uint32) revealTimestamps;

    string unrevealed_uri = "data:image/svg+xml;base64,PHN2ZyBpZD0iQ3J5cHRvQ29va2llcyIgdmlld0JveD0iMCAwIDIwMCAyMDAiIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHZlcnNpb249IjEuMSIgPjxpbWFnZSB4PSIwIiB5PSIwIiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgaW1hZ2UtcmVuZGVyaW5nPSJwaXhlbGF0ZWQiIHByZXNlcnZlQXNwZWN0UmF0aW89InhNaWRZTWlkIiB4bGluazpocmVmPSJkYXRhOmltYWdlL3BuZztiYXNlNjQsaVZCT1J3MEtHZ29BQUFBTlNVaEVVZ0FBQU1nQUFBRElCQU1BQUFCZmRyT3RBQUFBRlZCTVZFWC94SHYvdDFYLzU4ci8vZjc0a2loVkxRQ2NkVHFVNGxMTUFBQUQ4RWxFUVZSNEFlM2JSN0xjUmhBRVVJQm1qNExBQTNUTjM5TzBxRDJnUGdEZDZBQXk5NytDeG1Xb1lrQ2dma1JXdDl6a2l2YS95T3p4cHRNRytYOGdEK1NCSEhMbUVkL0lIM2pFTlhqRU4wN2hFZDhncXZnSWpLcEl6Z2lQdUFaUnhVT3lUU1hrMEFMSndZaGZKSCtvZ3VTNzFHL0NJL1JlQktMeGlGK0ZRQnlsUHFMK1hnSElJUnJ4cTlSQ0RzMlJENVVRWFNOSmJobWpIMGdBa2J2RUl6bkpLbU1Fb3NibzVYdUpSV1FqTEdMMmVpZWJHYU9ROXlLZVFpRHE5WURDSTRKMGlOaE1FWWdSVEhwQkZnTEJvZlRXc0VHUkFPVDlsb0VxaFVmZWJSbG9NZ1VnbXdhYWxLSWNnbHZkWWE4SWoyd2FRQXFMb0VoSElGeVJIc1pDSWdsR1RXUm5yQTRHaTZSbklTT0g3Qms5aktJVWtuWU1GS0VSMlVWZ0xBU0NpNWF6Rm92QTJDOVNsRVk2cHdpTEpBK1pMc2JzSS94YUM0c01lMFVLaVdDdHppOVNsRURjWXk5QnlPQVhLUXVESks5SUVESXdhd0ZoMXBwdXhzd2kvRnBBbkxVY280d3RFQ1VRck9XY1NGa294Qy9DSTFqTE1ZcVNpSE5sUnhFVzhZdU1CSUlqOFlvVXBSRy95TUlpenlreThvaHJGS1dRSk1QT293ZGtvUkdpQ0lXSVc0UkgrbFVSRGhIeGk4dzFFSEdMOElqNFJYaWtoK0ZjRWZtNUpsdUVSd1pIMFFqRXViNHZQSkpFL0VmWlBPTGNySXdWRVF5MmFDMEVpblBKWWhFODV0SW94Sno4NitNblcwVkdqVzl5UE1kV2tmZ21yeS9JSjZ1TUZaQmY4aDkzZzRVangrUFgvQkY3MmNGNDVIWW9PWCs4SXM3Wjg4aHBMb09nQ28zb0RYbVpjejVlQThSVzRSRlpJMWFwak5qQmVBUm5ZaEU3R0kvZ1VMb2IwdDBqRW9hY3NrWlFoVVVTOXJJM0t6WmhpSzNTclJFSlJIQlR2N2NYZ1VpM0UxUWhFSFVSVktHUmdhL2lJMjZWRU1Tck1uSklrcUNqSjVFK0Noa2NaS1FRbFpBcVBvSXFyKzBWSHI5RkZRcEpmMVU1ZGpibWxpd01FWXZnUnZrVEVCRUtVU0RER2Zsa2l2ejJFNnBnTHg2UkUvTDZhSXJrakNxQmlPQVVLaUJKa0RmWEh3cmtOSmRCaEVKVVRCZHpKTmZBY0t1UWlFZ0FrZ3dpM2FjN3BCZUVRZTZPL29hOHZocWZZTkRJYkk5ZVpMQ0kyWEtra0NkWlpianQxWWNoQ1ZWc3JvaUVJVHJKT20vT3htZXg0WkJVMXNnUE9hTUhpNkRLL0Qza2ZleG43cDVLQXlTVnVTcUNLck9QQ0lta3Nob3Nad2xHZElMQ2ZnN1NxVEpYUi9USlYzaEVpNi93eUpPdkNJM281Q3M4a3NvNU5PSVA1cFFaU1FTRG5jSWovbUFvUXlHK3NsR25sTUlqVmpHTm5BL0lPSWl2SUw0QmhGWmdNQWlVcVp5U1RWNWRqVkdqRUZ5U1h4cmtSK0pqUHR1UlVuNitRMllOUkZER0loazF3aERFSXFyL0ZlVERBM0VSbXdjUytaMjlCM0w0anlMNVg0emtGb2cyUWJRSmNtaUJRT0VSWCtFUlg2bVBhQk5FbXlEYUJORW15S0UrQW9WSGZJVkhmS1VGb2swUWJZSWNXaUQ2UUI3SWZ4NzVFeEkxbExleFduM2JBQUFBQUVsRlRrU3VRbUNDIi8+PC9zdmc+";

    bool revealStarted;

    constructor (address rendererAddress) {
        renderer = IRenderingFortunes(rendererAddress);
        SetProvenance();
        controllers[owner()] = true;
    }

    function SetRenderers(address newRenderer) external onlyOwner {
        renderer = IRenderingFortunes(newRenderer);
    }

    function SetProvenance() internal {
        require(indexOffset == 0,"Index already set");

        unchecked {
            uint256 n = uint256(blockhash(block.number - 1));
            if (n == 0)
            {
                n = 7; //if block hash is unavailable for some inexplicable reason
            }

            indexOffset = n % MAX_SUPPLY;
        }

    }

    function setRevealStarted(bool isRevealed) external onlyOwner() {
        revealStarted = isRevealed;
    }

    //offset by amount set using blockhash. This is a bit of fun.
    function getTokenGene(uint256 tokenID) internal view returns (uint256) {
        return (tokenID + indexOffset) % MAX_SUPPLY;
    }

    function setRevealTimestamp(uint256 tokenID, uint32 newTimestamp) external {
        require(controllers[msg.sender] || msg.sender == owner(),"Not Authorized to set timestamp");
        revealTimestamps[tokenID] = newTimestamp;
    }

    function getRevealTimestamp(uint256 tokenID) external view returns (uint32) {
        return revealTimestamps[tokenID];
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory)
    {
        uint256 tokenGene = getTokenGene(tokenID);
        uint32 revealTime = revealTimestamps[tokenID];

        if (block.timestamp < revealTime || revealTime == 0 || !revealStarted) //unrevealed
        {
            string memory json = Base64.encode(
                            bytes(
                                string(
                                    abi.encodePacked(
                                        '{"name":"Cookie #',Strings.toString(tokenID), '",',
                                        '"description": "Your cookie will open and reveal itself after 24 hours.",',
                                        '"image": "',unrevealed_uri,'",',
                                        '"RevealTime":"',Strings.toString(revealTime),'",',
                                        '"attributes": [ ',
                                            '{"trait_type":"Status","value":"Hidden"}', //',',
                                        ']}'
                                    )
                                )
                            )
                        );

            return string(abi.encodePacked("data:application/json;base64,", json));
        }
        else
        {
            //text is based on simple PRNG of tokenID. Tokens don't have rarity traits. 
            string memory imageURI = getFullEncodedSVG(getImageURI(tokenGene));
            string memory luckynumber1 = Strings.toString(1+(((tokenGene + 888) * 193939) % 1000));
            string memory json = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"name":"Cookie #',Strings.toString(tokenID), '",',
                            '"description": "\\\"',renderer.getFullLine(tokenGene), '\\\"",',
                            '"image": "data:image/svg+xml;base64,',imageURI, '",',
                            '"attributes": [ ',
                                '{"trait_type": "Lucky Number", "value": "',luckynumber1, '", "display_type": "number"}', //',',
                            ']}'
                        )
                    )
                )
            );
            
            return string(abi.encodePacked("data:application/json;base64,", json));

        }

    }

    //string constant bg1 = '<defs><pattern id="bg1" width="24" height="24" x="32" y="16" patternUnits="userSpaceOnUse"><polygon opacity="0.15" fill-rule="evenodd" points="8 4 12 6 8 8 6 12 4 8 0 6 4 4 6 0 8 4"/></pattern></defs><rect x="0" y="0" width="640" height="640" rx="32" style="fill: url(#bg1);"/>';

    function getImageURI(uint256 genes) internal view returns (string memory)
    {
        string memory txt = "";

        if (genes % 2 == 0){
            txt = renderer.renderText([renderer.getLine1_A(genes),renderer.getLine2_A(genes),renderer.getLine3_A(genes)]);
        } else{
            txt = renderer.renderText([renderer.getLine1_B(genes),renderer.getLine2_B(genes),renderer.getLine3_B(genes)]);
        }

        uint256 k = uint256(keccak256(abi.encodePacked(genes)));
        uint256 r = k % 256;
        uint256 g = k / 10000000 % 256;
        uint256 b = k / 100000 % 256;

        return string(abi.encodePacked('<rect x="0" y="0" width="640" height="640" style="fill:rgb(',r.toString(),',',g.toString(),',',b.toString(),');" />',
                        // bg1,
                        txt,
                        "</svg>"));
    }

    function getFullEncodedSVG(string memory toWrap) internal pure returns (string memory) {
        toWrap = string(abi.encodePacked(HEADER,toWrap));
        return Base64.encode(
            bytes(
                toWrap
            )
        );
    }
}