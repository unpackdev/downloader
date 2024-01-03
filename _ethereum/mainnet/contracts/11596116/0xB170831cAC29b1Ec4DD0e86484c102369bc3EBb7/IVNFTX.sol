pragma solidity ^0.6.0;

interface IVNFTx {
    function getHp(uint256 _tokenId) external view returns (uint256 _hp);

    function getChallenges(uint256 _tokenId)
        external
        view
        returns (uint256 _challenges);
}
