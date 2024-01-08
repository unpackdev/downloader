// // SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity ^0.7.0;
pragma abicoder v2;

                                                                   
//                    ,--.                                            
//   .--.--.      ,--/  /|             ,---,.          ,--,     ,--,  
//  /  /    '. ,---,': / '    ,---,  ,'  .' |          |'. \   / .`|  
// |  :  /`. / :   : '/ /    /_ ./|,---.'   |    ,---,.; \ `\ /' / ;  
// ;  |  |--`  |   '   ,---, |  ' :|   |   .'  ,'  .' |`. \  /  / .'  
// |  :  ;_    '   |  /___/ \.  : |:   :  |-,,---.'   , \  \/  / ./   
//  \  \    `. |   ;  ;.  \  \ ,' ':   |  ;/||   |    |  \  \.'  /    
//   `----.   \:   '   \\  ;  `  ,'|   :   .':   :  .'    \  ;  ;     
//   __ \  \  ||   |    '\  \    ' |   |  |-,:   |.'     / \  \  \    
//  /  /`--'  /'   : |.  \'  \   | '   :  ;/|`---'      ;  /\  \  \   
// '--'.     / |   | '_\.' \  ;  ; |   |    \         ./__;  \  ;  \  
//   `--'---'  '   : |      :  \  \|   :   .'         |   : / \  \  ; 
//             ;   |,'       \  ' ;|   | ,'           ;   |/   \  ' | 
//             '---'          `--` `----'             `---'     `--` 


contract SkyeX is ERC721, Ownable {
    using SafeMath for uint256;

    string public SKYEX_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN TOKENS ARE ALL SOLD OUT

    uint256 public constant tokenPrice = 59000000000000000; // 0.059 ETH
    uint256 public constant maxTokenPurchase = 30;
    uint256 public constant MAX_TOKENS = 9999;

    bool public saleIsOn = false;
    bool public presaleIsOn = false;

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _whitelistClaimed;

    uint256 public presaleMaxMint = 3;
    uint256 public devReserve = 40;

    event SkyeMinted(uint256 supply);

    constructor() ERC721("SKYE-X", "SKYE") {}

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function reserveTokens(address _to, uint256 _reserveAmount) external onlyOwner {
        require(
            _reserveAmount > 0 && _reserveAmount <= devReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            uint256 id = totalSupply();
            _safeMint(_to, id);
        }
        devReserve = devReserve.sub(_reserveAmount);
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        SKYEX_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function toggleSale() external onlyOwner {
        saleIsOn = !saleIsOn;
    }

    function togglePresale() external onlyOwner {
        presaleIsOn = !presaleIsOn;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mintToken(uint256 numberOfTokens) external payable {
        require(saleIsOn, "Sale must be active to mint Token");
        require(
            numberOfTokens > 0 && numberOfTokens <= maxTokenPurchase,
            "Can only mint one or more tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 id = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, id);
                emit SkyeMinted(id);
            }
        }
    }

    function presaleMint(uint256 numberOfTokens) external payable {
        require(presaleIsOn, "Presale is not active");
        require(_whitelist[msg.sender], "You are not on the Whitelist");
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of token"
        );
        require(
            numberOfTokens > 0 && numberOfTokens <= presaleMaxMint,
            "Cannot purchase this many tokens"
        );
        require(
            _whitelistClaimed[msg.sender].add(numberOfTokens) <=
                presaleMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 id = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _whitelistClaimed[msg.sender] += 1;
                _safeMint(msg.sender, id);
                emit SkyeMinted(id);
            }
        }
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _whitelist[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata addresses) external onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _whitelist[addresses[i]] = false;
        }
    }

    function setPresaleMaxMint(uint256 maxMint) external onlyOwner {
        presaleMaxMint = maxMint;
    }

    function onWhitelist(address addr) external view returns (bool) {
        return _whitelist[addr];
    }
}
