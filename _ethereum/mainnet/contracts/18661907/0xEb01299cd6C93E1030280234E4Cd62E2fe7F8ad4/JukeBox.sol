// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract JukeBox is ERC20 {
    address public player;
    address public nftContract;
    uint256 public tokenId;
    uint256 public startBlock;

    event NFTPlayed(
        address indexed player,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 startBlock
    );

    constructor() ERC20("JUKEBOX", "JUKE") {}

    function playJukeBox(address _nftContract, uint256 _tokenId) public {
        // Reward distribution for the last played NFT
        if (nftContract != address(0)) {
            uint256 blocksPlayed = block.number - startBlock;
            uint256 reward = blocksPlayed * 120 * (10 ** uint256(decimals()));
            _mint(player, reward);
        }

        // Update the current playing NFT details
        player = msg.sender;
        nftContract = _nftContract;
        tokenId = _tokenId;
        startBlock = block.number;

        emit NFTPlayed(msg.sender, nftContract, tokenId, startBlock);
    }

    // Function to return the URI of the currently played NFT
    function nowPlaying() public view returns (string memory) {
        try IERC721(nftContract).tokenURI(tokenId) returns (string memory uri) {
            return uri;
        } catch {
            try IERC1155(nftContract).uri(tokenId) returns (string memory uri) {
                return uri;
            } catch {
                return ""; // If both calls fail, return an empty string
            }
        }
    }
}

interface IERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}
