pragma solidity ^0.6.0;

interface IVNFT {
    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 id);

    function vnftScore(uint256 _tokenId) external view returns (uint256 _score);

    function timeVnftBorn(uint256 _tokenId)
        external
        view
        returns (uint256 _born);
}

interface IVNFTx {
    function getHp(uint256 _tokenId) external view returns (uint256 _hp);
}

import "./SafeMath.sol";

contract VNFTGov {
    using SafeMath for uint256;

    IVNFT vnft = IVNFT(0x57f0B53926dd62f2E26bc40B30140AbEA474DA94);
    IVNFTx vnftx = IVNFTx(0x14d4D06B8e8df9B85A37D622aA95784a4FCcB130);

    constructor() public {}

    function getVotes(address voter) public view returns (uint256) {
        uint256 balance = vnft.balanceOf(voter);
        uint256 votes = 0;
        for (uint256 index = 0; index < balance; index++) {
            uint256 pet = vnft.tokenOfOwnerByIndex(voter, index);
            uint256 hp = vnftx.getHp(pet);
            if (hp >= 90) {
                uint256 age = (now.sub(vnft.timeVnftBorn(pet))).div(1 weeks);
                uint256 score = vnft.vnftScore(pet);
                votes = votes.add((age.mul(score)));
            }
        }
        return (votes);
    }
}
