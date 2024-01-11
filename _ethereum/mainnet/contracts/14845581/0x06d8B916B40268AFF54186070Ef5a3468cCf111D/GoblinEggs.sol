// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

//   ▄████  ▒█████   ▄▄▄▄    ██▓     ██▓ ███▄    █ 
//  ██▒ ▀█▒▒██▒  ██▒▓█████▄ ▓██▒    ▓██▒ ██ ▀█   █ 
// ▒██░▄▄▄░▒██░  ██▒▒██▒ ▄██▒██░    ▒██▒▓██  ▀█ ██▒
// ░▓█  ██▓▒██   ██░▒██░█▀  ▒██░    ░██░▓██▒  ▐▌██▒
// ░▒▓███▀▒░ ████▓▒░░▓█  ▀█▓░██████▒░██░▒██░   ▓██░
//  ░▒   ▒ ░ ▒░▒░▒░ ░▒▓███▀▒░ ▒░▓  ░░▓  ░ ▒░   ▒ ▒ 
//   ░   ░   ░ ▒ ▒░ ▒░▒   ░ ░ ░ ▒  ░ ▒ ░░ ░░   ░ ▒░
// ░ ░   ░ ░ ░ ░ ▒   ░    ░   ░ ░    ▒ ░   ░   ░ ░ 
//       ░     ░ ░   ░          ░  ░ ░           ░ 
//                        ░                        
//          ▓█████   ▄████   ▄████   ██████        
//          ▓█   ▀  ██▒ ▀█▒ ██▒ ▀█▒▒██    ▒        
//          ▒███   ▒██░▄▄▄░▒██░▄▄▄░░ ▓██▄          
//          ▒▓█  ▄ ░▓█  ██▓░▓█  ██▓  ▒   ██▒       
//          ░▒████▒░▒▓███▀▒░▒▓███▀▒▒██████▒▒       
//          ░░ ▒░ ░ ░▒   ▒  ░▒   ▒ ▒ ▒▓▒ ▒ ░       
//           ░ ░  ░  ░   ░   ░   ░ ░ ░▒  ░ ░       
//             ░   ░ ░   ░ ░ ░   ░ ░  ░  ░         
//             ░  ░      ░       ░       ░         

contract GoblinEggs is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint16  public maxTotalSupply = 10000;
    uint16  public minted = 0;
    bool    public holdersOnly = true;
    bool    public preReveal = true;

    string  public baseURI;
    string  public goblinHolderTokenUri;
    string  public publicHolderTokenUri;
    IERC721 public goblinAddress;

    mapping (uint256 => bool) public goblinHolderToken;

    constructor() ERC721("GOBLIN EGGS", "GE") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata value) external onlyOwner {
        baseURI = value;
    }

    function setGoblinHolderTokenUri(string calldata value) external onlyOwner {
        goblinHolderTokenUri = value;
    }

    function setPublicHolderTokenUri(string calldata value) external onlyOwner {
        publicHolderTokenUri = value;
    }

    function setGoblinAddress(IERC721 value) external onlyOwner {
        goblinAddress = value;
    }

    function setHoldersOnly(bool value) external onlyOwner {
        holdersOnly = value;
    }

    function setPreReveal(bool value) external onlyOwner {
        preReveal = value;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (preReveal) {
            if (goblinHolderToken[tokenId]) {
                return string(abi.encodePacked(goblinHolderTokenUri));
            } else {
                return string(abi.encodePacked(publicHolderTokenUri));
            }
        }

        return super.tokenURI(tokenId);
    }

    function mint() external nonReentrant {
        require(minted < maxTotalSupply, "MAX TOKENS MINTED");
        require(balanceOf(msg.sender) == 0, "ONE EGG PER ADDRESS");

        bool isGoblinHolder = goblinAddress.balanceOf(msg.sender) >= 1;

        if (holdersOnly) {
            require(isGoblinHolder, "GOBLIN HOLDERS ONLY");
        }

        _safeMint(msg.sender, ++minted);

        if (isGoblinHolder) {
            goblinHolderToken[minted] = true;
        }
    }

    function ownerMint(uint16 count) external onlyOwner {
        require(minted < maxTotalSupply, "MAX TOKENS MINTED");
        require(minted + count <= maxTotalSupply, "NOT ENOUGH TOKENS AVAILABLE");

        for (uint16 i = 0; i < count; i++) {
            _safeMint(owner(), ++minted);
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

}
