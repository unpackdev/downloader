// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./IERC721G.sol";

contract TheKoreans1945Minter is Ownable {
    event SetNFTWhitelist(address nft, bool status);
    event SetUserWhitelist(address user, bool status);
    event Mint(address user, uint256 tokenId);
    event Airdrop(address[] users, uint256 initialId, uint256 lastId);

    uint256 public constant preMintTime = 1660564800; //15Aug22 12:00PM UTC
    uint256 public constant wlMintTime = 1660568400; //15Aug22 13:00PM UTC
    uint256 public constant publicMintTime = 1660654800; //16Aug22 13:00PM UTC

    IERC721G public immutable KOREANS;
    mapping(address => bool) public nftForPreMint;
    mapping(address => bool) public isListedNFT;
    mapping(address => bool) public isListedUser;
    mapping(address => mapping(address => uint256)) public mintedAmount;

    constructor(IERC721G _KOREANS, address[] memory wlNFTs, address[] memory nftsForPreMint) {
        KOREANS = _KOREANS;

        uint256 amount = wlNFTs.length;
        for (uint256 i = 0; i < amount; i++) {
            isListedNFT[wlNFTs[i]] = true;
            emit SetNFTWhitelist(wlNFTs[i], true);
        }

        amount = nftsForPreMint.length;
        require(amount == 4, "INVALID_NFTS_FOR_PREMINT");
        for (uint256 i = 0; i < amount; i++) {
            nftForPreMint[nftsForPreMint[i]] = true;
        }
    }

    function setNFTForPreMint(address[] calldata nfts, bool status) external onlyOwner {
        for (uint256 i = 0; i < nfts.length; i++) {
            nftForPreMint[nfts[i]] = status;
        }
    }

    function setNFTWhitelist(address[] calldata nfts, bool status) external onlyOwner {
        for (uint256 i = 0; i < nfts.length; i++) {
            isListedNFT[nfts[i]] = status;
            emit SetNFTWhitelist(nfts[i], status);
        }
    }

    function setUserWhitelist(address[] calldata users, bool status) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            isListedUser[users[i]] = status;
            emit SetUserWhitelist(users[i], status);
        }
    }

    function airdrop(address[] calldata users) external onlyOwner {
        uint256 startId = KOREANS.totalSupply();
        for (uint256 i = 0; i < users.length; i++) {
            KOREANS.mint(users[i], startId + i);
            emit Mint(users[i], startId + i);
        }
        emit Airdrop(users, startId, startId + users.length - 1);
    }

    function mint(address nft) external {
        if (block.timestamp < preMintTime) {
            revert("NOT_STARTED_YET");
        } else if (block.timestamp < wlMintTime) {
            if (nft == address(0)) {
                require(isListedUser[msg.sender], "UNAUTHORIZED");
                delete isListedUser[msg.sender];
            } else {
                require(KOREANS.totalSupply() < 945);
                require(nftForPreMint[nft], "NOT_YET_WITH_THIS_NFT");
                uint256 _mintedAmount = mintedAmount[msg.sender][nft]++;
                require(_mintedAmount == 0, "ONLY_1_NFT_IN_PREMINT_TIME");
                require(_mintedAmount < IERC721(nft).balanceOf(msg.sender), "OUT_OF_RANGE");
            }
        } else if (block.timestamp < publicMintTime) {
            if (nft == address(0)) {
                require(isListedUser[msg.sender], "UNAUTHORIZED");
                delete isListedUser[msg.sender];
            } else {
                require(isListedNFT[nft], "INVALID_NFT_ADDRESS");
                require(mintedAmount[msg.sender][nft]++ < IERC721(nft).balanceOf(msg.sender), "OUT_OF_RANGE");
            }
        }

        uint256 tokenId = KOREANS.totalSupply();
        KOREANS.mint(msg.sender, tokenId);
        emit Mint(msg.sender, tokenId);
    }
}
