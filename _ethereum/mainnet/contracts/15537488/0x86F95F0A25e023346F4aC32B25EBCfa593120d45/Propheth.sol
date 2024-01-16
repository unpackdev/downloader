// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.16;

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                  The Propheth                                 //
//                                                                               //
//                                        #((%                                   //
//                                     %##*%&&&                                  //
//                                    %%/,*%&&&#*%                               //
//                                 &%%(,..,#%&&&&%&                              //
//                                &%%/. .,*#%&&&&&%%                             //
//                             &(%%(//,..*/###%&&&&&%/%                          //
//                            &%%#/*,,..,*/(%(*(%&%%%#(%                         //
//                           &%%(****.. ,*/#%%#%&&%%%##%&                        //
//                          %%#(/**,,. .*//#%%%%%##%&%%%%#%                      //
//                       &%%##(////,.  .*/*((#%%#%&%%#%%%#%%&                    //
//                      %##/(///*,**, .****##((%%#(#%#%#(%&%#%                   //
//                     %#((#/**//**,,,**,,*((##((#%#(#%%%/#%&%%%%&               //
//                  %##//((/***/*/***,*..*/((#%%##(/######%&&&%##%&              //
//                 ###(*((/*******,**,  .*//**//*(%&%%%%%%%%%%%%%##(             //
//                (/((,.***,***//*.   .***(((//(%%%%&%##%%&%%%%(#%%%             //
//              &#////*//(###/***,*,,.   ./((###%%###/###%%%%%%&%&&#             //
//              &######(##(///**,,,,,,,*/#%%%#(/((##%&&&%%%%%&%%%#((             //
//                ####((///*,,,*/(%&   %%&&#%&&&&   &%%####%%%##%%%#             //
//                %%%%%%%&&     &     &(#&&%%&&&&              &&%&              //
//                  &%%%#(/**(##%%%%%%##%&&%%&&&&&&%%%%%%&&  &&&&&               //
//                     &%%#/*/(((#%##%###%%#(((#&%%&&%%&&  &&&&                  //
//                        %#%(*,*****/(/*/#((((#%&%%%%&  &%%&                    //
//                          &%#(*.,,**,,*/##(#&%&&& %&&&%%&                      //
//                             &#(/**/((/**#((%%%&&%%&&%&                        //
//                               #((/,***,.#(#&&&%%&%%                           //
//                                 #//,*//.#(#%%&&%%                             //
//                                  &/*(#(*/#%%%%#%                              //
//                                     //#(/%%((#                                //
//                                      &(/#(/(#                                 //
//                                         &##%                                  //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////

import "./Ownable.sol";
import "./ERC721.sol";


contract ThePropheth is ERC721, Ownable {
    using Strings for uint256;

    uint256 private _tokenId;

    uint256 public constant COLLECTION_SIZE = 922;
    bool public paused = false;

    string private _baseURL = "ipfs://QmWZ5xg9xPgvGFU2K7criYnjP7zAhnAFgGsS1d4V6KF4oB";
    mapping(address => bool) private _minted;

    constructor() ERC721("The Propheth", "PRETH") {
        _mintTokens(msg.sender, 40);
    }


    /// @notice Set base metadata URL
    function setBaseUrl(string calldata url) external onlyOwner {
        _baseURL = url;
    }

    /// @notice Current number of NFTs in circulation
    function totalSupply() external view returns (uint256) {
        return _tokenId;
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    /// @notice Update current sale stage
    function setPaused(bool status) external onlyOwner {
        require(paused != status, "That's already the current status");
        paused = status;
    }

    /// @notice Get token URI.
    /// @param tokenId token ID
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"))
        : "";
    }

    /// @notice Mints
    function summonPropheth() external {
        require(!paused, "Mint is paused");
        require(_tokenId < COLLECTION_SIZE, "Sold out");
        require(!_minted[msg.sender], "Address already minted");
        _minted[msg.sender] = true;
        _mintTokens(msg.sender, 1);
    }
    /// @dev Perform actual minting of the tokens
    function _mintTokens(address to, uint256 count) internal {
        for(uint256 index = 0; index < count; index++) {

            _tokenId++;
            uint256 newItemId = _tokenId;

            _safeMint(to, newItemId);
        }
    }
}
