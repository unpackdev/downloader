//SPDX-License-Identifier: MIT
/**
███    ███  █████  ████████ ██████  ██ ██   ██     ██████   █████   ██████  
████  ████ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██ ████ ██ ███████    ██    ██████  ██   ███       ██   ██ ███████ ██    ██ 
██  ██  ██ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██      ██ ██   ██    ██    ██   ██ ██ ██   ██     ██████  ██   ██  ██████  

Website: https://matrixdaoresearch.xyz/
Twitter: https://twitter.com/MatrixDAO_
 */
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./INFTMatrixDao.sol";

contract MatrixVotingPower is IERC20, IERC20Metadata, Ownable {
    string constant NOT_IMPLEMENTED_MSG = "MatrixVotingPower: not implemented";
    uint256 constant ENDTOKEN_ID_LAST_TOKEN = 0;

    address public immutable nft;
    address public immutable mtx;

    mapping(uint256 => bool) public blackList;
    uint256 public numBlackList;

    constructor(address _nft, address _mtx){
        nft = _nft;
        mtx = _mtx;
    }

    function addToBlackList(uint256 tokenId) external onlyOwner {
        require(!blackList[tokenId], "MatrixVotingPower: already in the blacklist");
        blackList[tokenId] = true;
        numBlackList++;
    }

    function removeFromBlackList(uint256 tokenId) external onlyOwner {
        require(blackList[tokenId], "MatrixVotingPower: not in the blacklist");
        blackList[tokenId] = false;
        numBlackList--;
    }

    function name() external override pure returns (string memory) {
        return "Matrix DAO Voting Power";
    }

    function symbol() external override pure returns (string memory) {
        return "MTX";
    }

    function decimals() external override view returns (uint8) {
        return IERC20Metadata(mtx).decimals();
    }

    function totalSupply() external override view returns (uint256) {
        return INFTMatrixDao(nft).totalSupply() - numBlackList;
    }

    function balanceOf(address account) external override view returns (uint256 power) {
        if(INFTMatrixDao(nft).balanceOf(account) != 0) {
            uint256[] memory tokenIds; 
            uint256 endTokenId;
            (tokenIds, endTokenId) = INFTMatrixDao(nft).ownedTokens(account, 1, ENDTOKEN_ID_LAST_TOKEN); 

            for(uint256 i=0;i<tokenIds.length;i++) {
                uint256 tokenId = tokenIds[i];
                if(!blackList[tokenId]){
                    power++;
                }
            }

            if(power > 0) {
                return IERC20(mtx).balanceOf(account);
            } else {
                return 0;
            }
        }
    }


    // Unused interfaces

    function transfer(address to, uint256 amount) external override returns (bool) {
        revert(NOT_IMPLEMENTED_MSG);
    }
    function allowance(address owner, address spender) external override view returns (uint256) {
        revert(NOT_IMPLEMENTED_MSG);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        revert(NOT_IMPLEMENTED_MSG);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        revert(NOT_IMPLEMENTED_MSG);
    }

}


