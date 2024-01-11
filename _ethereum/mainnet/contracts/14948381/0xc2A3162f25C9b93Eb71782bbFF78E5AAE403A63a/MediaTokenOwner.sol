// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.2;
import "./WalkersMedia.sol";
import "./Ownable.sol";
import "./IERC721.sol";

contract MediaTokenOwner {
    ETHWalkersSeasonOneMedia private s1media;

    constructor() {
        address S1MediaAddress = 0xEA3670f81b7ccE94477B214185D9DD49298FE932;
        s1media = ETHWalkersSeasonOneMedia(S1MediaAddress);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = s1media.balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            uint256 current_token = 0;
            for (index = 0; index < s1media.totalSupply() && current_token < tokenCount; index++) {
                if (s1media.ownerOf(index) == _owner){
                    result[current_token] = index;
                    current_token++;
                }
            }
            return result;
        }
    }
}
