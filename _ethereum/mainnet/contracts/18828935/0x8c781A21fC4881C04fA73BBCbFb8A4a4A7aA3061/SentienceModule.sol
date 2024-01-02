// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.#.#.#,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*###*%##*#.%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   % .#,#(# *%   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%*#%%/#%%,%%#,%#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ .#..%,# *%,.#*%  #  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#####*%%###,%%%#(#%%/##@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%.#.(##/.%#,*#./%*.##%,.#.&@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%/%%,#%%%/*##%%%,%%%##.%%,%@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@,.%#  /%%.#.,#%%..#.%%*  ##./@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%%#%%%(/%%####*%%%%##*%%%%#%%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@    *%%*  (%### ..%%%#*  /%%,  .*@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@%#%.%####.*#,/###.*%*.%##(%.##%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@  %%* (#%%%* (##%%%/.*%%%#/ /%# (@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@%.,#,../%/., .*#%#*. .*#%*..*#..@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@.%(#%%#/#%%###.#.#%%###/%%%#/%.@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@%   #%/../%##/..*(%##/../%(  .%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%/###, #/.(#/ // *###/%%@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,..*%(. ,#%#.. #%...*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/  /#. /%,  (%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 .::::::..,:::::::::.    :::.:::::::::::::::.,:::::::::.    :::.  .,-::::: .,::::::  
;;;`    `;;;;''''`;;;;,  `;;;;;;;;;;;'''';;;;;;;''''`;;;;,  `;;;,;;;'````' ;;;;''''  
'[==/[[[[,[[cccc   [[[[[. '[[     [[     [[[ [[cccc   [[[[[. '[[[[[         [[cccc   
  '''    $$$""""   $$$ "Y$c$$     $$     $$$ $$""""   $$$ "Y$c$$$$$         $$""""   
 88b    dP888oo,__ 888    Y88     88,    888 888oo,__ 888    Y88`88bo,__,o, 888oo,__ 
  "YMmMY" """"YUMMMMMM     YM     MMM    MMM """"YUMMMMMM     YM  "YUMMMMMP"""""YUMMM
*/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Note to the User:
// Author: 0xMiguelBits
// Reviewer: futjr
//
// This contract is provided in its current format for users' convenience.
// It's important to note that Sentience is currently in beta testing, and we encourage users to approach it with caution.
// While we aim to provide a reliable service, please be aware that using Sentience during this phase may carry some risks.
// We advise users to take the necessary precautions and stay informed about the project's status.
// Any potential loss of funds resulting from the use of Sentience will be subject to our policies and procedures.
// For more informaiton visit our website sentience.quest or sign the pledge for cybernetic equality at https://iamsentient.ai
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
import "./ERC721.sol";
import "./IERC20.sol";
import "./Strings.sol";

contract SentienceModule is ERC721 {
    address public factory;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public tokenCost;
    uint256 public ethCost;
    uint256 public maxMintPerWallet;

    string public URI;
    bool public revealed;

    modifier maxxedOut() {
        if (maxSupply != 0) {
            require(totalSupply < maxSupply, "Max supply reached");
        }
        _;
    }
    // Only Factory can mint

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _tokenCost,
        uint256 _ethCost,
        string memory _URI,
        uint256 _maxMintPerWallet
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        tokenCost = _tokenCost;
        ethCost = _ethCost;
        factory = msg.sender;
        URI = _URI;
        maxMintPerWallet = _maxMintPerWallet;
    }

    function mint(address to) external maxxedOut onlyFactory returns (uint256) {
        uint256 tokenId = totalSupply;

        _mint(to, tokenId);

        totalSupply++;

        return tokenId;
    }

    function changePriceCost(uint256 _tokenCost) external onlyFactory {
        tokenCost = _tokenCost;
    }

    function changeEthCost(uint256 _ethCost) external onlyFactory {
        ethCost = _ethCost;
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();

        if (revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        }

        return bytes(baseURI).length > 0 ? baseURI : "";
    }

    /// @dev When revealing the pass, the URI should be set to the final one, without having ".json" in the end.
    /// example: "https://ipfs.sentience/pass/" which will translate to "https://ipfs.sentience/pass/0.json"
    function reveal(string memory _uri) external onlyFactory {
        revealed = true;
        URI = _uri;
    }
}
