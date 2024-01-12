//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Renderer.sol";

/*
.__   __.  _______ .______    __    __   __          ___       _______ .___________. __    __  
|  \ |  | |   ____||   _  \  |  |  |  | |  |        /   \     |   ____||           ||  |  |  | 
|   \|  | |  |__   |  |_)  | |  |  |  | |  |       /  ^  \    |  |__   `---|  |----`|  |__|  | 
|  . `  | |   __|  |   _  <  |  |  |  | |  |      /  /_\  \   |   __|      |  |     |   __   | 
|  |\   | |  |____ |  |_)  | |  `--'  | |  `----./  _____  \  |  |____     |  |     |  |  |  | 
|__| \__| |_______||______/   \______/  |_______/__/     \__\ |_______|    |__|     |__|  |__| 
*/

contract Nebulaeth is ERC721, Ownable {

    //// ============ define variables ============
    mapping(uint256 => string) public tokenMetadata;

    uint256 public cost = 0.01 ether;
    uint256 public tokenId;

    constructor() ERC721("Nebulaeth", "NBLTH") {}

    /// ============ token functions ============

    event Mint(uint256 _tokenId);

    function mint() public payable {
        require(msg.value >= cost, "Not enough ETH");
        string memory _address = Strings.toHexString(uint256(uint160(msg.sender)));
        tokenMetadata[tokenId] = renderer.render(tokenId, _address);
        _mint(msg.sender, tokenId);
        emit Mint(tokenId);
        tokenId++;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenMetadata[_tokenId];
    }

    /* ADMIN */
    function withdrawAll() external {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAllERC20(IERC20 _erc20Token) external {
        _erc20Token.transfer(owner(), _erc20Token.balanceOf(address(this)));
    }

    event MetadataUpdated(uint256 indexed tokenId);

    // Store renderer as separate contract so we can update it if needed
    Renderer public renderer;

    function setRenderer(Renderer _renderer) external onlyOwner {
        renderer = _renderer;
        emit MetadataUpdated(type(uint256).max);
    }
}
