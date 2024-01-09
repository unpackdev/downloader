pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC20.sol";

//                           ⢀⢀⣀⠤⠤⠤⣀     
//                          ⠞        ⠈⠑⠢⢔⡶⣭⡿⠟⠋⠉⠢⡀ 
//                       ⢀⠞              ⠈⠛⠃       ⣵⡀ 
//                     ⢠⠎         ⢀⠠⢤⣤⣤⠄⣀    ⣀⢤⣤⣭⣕⣢⡀ 
//                  ⢀⡠⠊       ⢀⡠⣪⠗⣨⣶⠟⠓⠪⡔⠵⣄⠼⣪⣷⡾⠛⠲⣌⠛⡆
//                ⢠⠊        ⠠⣔⡽⠊ ⢸⡿⢧  ⢀⣿⡀⠐⢠⣿⠿⡀   ⣸⡇⢸ 
//              ⢰⠃        ⠒⠛⠛⠤⣀  ⠘⣧⣾⣿⣿⣿⣿⡠⣊⢿⣤⣟⣿⣿⣿⡣⠎
//             ⢠⠇               ⠐⠻⠭⠭⠭⠿⠟⠋⠁ ⠈⠙⠛⠛⢛⡿⠋⠁
//             ⢸        ⢠⣶⣦⣄⡀             ⠙ ⠃    ⢈⣆
//             ⢸       ⠈⠻⢿⣿⣿⣷⣶⣶⣤⣤⣤⣤⣀⣀⣀⣤⣤⣤⣶⣶⣾⣿⣿⠆
//             ⢸           ⠈⠉⠛⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⡻
//             ⠘⡆                               ⢟⡕⠁
//            ⣀⣤⣷⣤                            ⢟⡕
//          ⣠⣾⣿⣿⣿⣿⣷                        ⣟⣯
//      ⢀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣷⣤⣈⠻⣿⣯⣶⣦⠴⢤⣀⣀⣀⣩⣭⡍⠊⣿⣧⣾⣿⣦⣄
//     ⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷     ⢧⣿⣿⣿⣿⣿⣾   ⣿⣿⣿⣿⣿⣷⣶⣄ 
//    ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿   ⠈⢻⣿⣿⣿⣿⡏  ⣡⣿⣿⣿⣿⣿⣿⣿⣿⡇
//   ⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⣹⣿⣿⣿⣯⢳⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀
//  ⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
//  ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧

// The Golden Frog DAO - Genesis Frogs
// Created by Mr F - https://twitter.com/MrFwashere
// Artwork by Fenoir - https://twitter.com/EscuerFlorian
// Special thanks and love to the entire Golden Frog DAO community
// Extra special thanks to the GFD admins Kronos, Oscom, SkYwArD and GayFrog

contract GoldenFrogs is ERC721, ERC721Enumerable, ERC721URIStorage {
    uint maxFrogs = 500;
    uint offsetBlock;
    uint offset;
    address public mrF = 0x38857Ed3a8fC5951289E58e20fB56A00e88f0BBD;
    string public baseURI;
    bool public locked;
    uint public withdrawnEth;
    mapping(uint => uint) public claimedEth;

    struct rewardToken {
        uint withdrawn;
        mapping(uint => uint) claimedTokens;
    }

    mapping(address => rewardToken) rewardTokens;

    constructor() ERC721("GoldenFrogs", "GF")  {
    }
    
    fallback() external payable {
    }

    receive() external payable {
    }

    function setBaseURI(string memory uri) public {
        require(msg.sender == mrF);
        require(!locked);
        baseURI = uri;
    }

    function lockBaseURI() public {
        require(msg.sender == mrF);
        locked = true;
    }

    function changeMrF(address newMrF) public {
        require(msg.sender == mrF);
        mrF = newMrF;
    }

    function mint(address og) public {
        require(msg.sender == mrF);
        require(totalSupply() < maxFrogs);
        require(offset != 0);
        _mint(og, ((totalSupply() + offset) % maxFrogs) + 1);
    }

    function mintMany(address[] memory addrs, uint32[] memory nums) public {
        for (uint i = 0; i < addrs.length; i++) {
            address addr = addrs[i];
            uint num = nums[i];
            for (uint j = 0; j < num; j++) {
                mint(addr);
            }
        }
    }

    // Offset functions (provenance)

    function initOffset() public {
        require(msg.sender == mrF);
        offsetBlock = block.number + 1;
    }

    function finalizeOffset() public {
        require(offset == 0);
        require(offsetBlock != 0);
        require(block.number - offsetBlock < 255);
        
        offset = uint(blockhash(offsetBlock)) % maxFrogs;

        // Prevent default sequence
        if (offset == 0) {
            offset = 1;
        }
        delete offsetBlock;
    }

    // Withdrawing functions

    function getUserFrogs(address user) public view returns (uint[] memory) {
        uint count = balanceOf(user);
        uint[] memory ids = new uint[](count);
        for (uint i = 0; i<count; i++) {
            uint token = tokenOfOwnerByIndex(user, i);
            ids[i] = token;
        }
        return ids;
    }

    function withdrawEth(uint32[] memory ids) public {
        uint totalRewards;
        uint receivedEth = withdrawnEth + address(this).balance;
        uint receivedEthPerFrog = receivedEth / totalSupply();
        for (uint i = 0; i < ids.length; i++) {
            require(ownerOf(ids[i]) == msg.sender, "Must own the token");
            totalRewards += receivedEthPerFrog - claimedEth[ids[i]];
            claimedEth[ids[i]] = receivedEthPerFrog;
        }
        withdrawnEth += totalRewards;
        (bool success,) = address(msg.sender).call{value: totalRewards}('');
        require(success, "Transfer failed");
    }

    function checkEth(uint32[] memory ids) public view returns (uint balance) {
        uint totalRewards;
        uint receivedEth = withdrawnEth + address(this).balance;
        uint receivedEthPerToken = receivedEth / totalSupply();
        for (uint i = 0; i < ids.length; i++) {
            totalRewards += receivedEthPerToken - claimedEth[ids[i]];
        }
        return totalRewards;
    }

    function withdrawTokens(address token, uint32[] memory ids) public {
        uint totalRewards;
        uint receivedTokens = rewardTokens[token].withdrawn + ERC20(token).balanceOf(address(this));
        uint receivedTokenPerFrog = receivedTokens / totalSupply();
        for (uint i = 0; i < ids.length; i++) {
            require(ownerOf(ids[i]) == msg.sender, "Must own the token");
            totalRewards += receivedTokenPerFrog - rewardTokens[token].claimedTokens[ids[i]];
            rewardTokens[token].claimedTokens[ids[i]] = receivedTokenPerFrog;
        }
        rewardTokens[token].withdrawn += totalRewards;
        ERC20(token).transfer(msg.sender, totalRewards);
    }

    function checkTokens(address token, uint32[] memory ids) public view returns (uint balance) {
        uint totalRewards;
        uint receivedTokens = rewardTokens[token].withdrawn + ERC20(token).balanceOf(address(this));
        uint receivedTokenPerFrog = receivedTokens / totalSupply();
        for (uint i = 0; i < ids.length; i++) {
            totalRewards += receivedTokenPerFrog - rewardTokens[token].claimedTokens[ids[i]];
        }
        return totalRewards;
    }

    // copy pasted ERC721 junk

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}