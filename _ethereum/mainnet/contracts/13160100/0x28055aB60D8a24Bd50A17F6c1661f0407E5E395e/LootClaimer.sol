//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";

interface ILoot {
    function claim(uint256 tokenId) external;
    function totalSupply() external returns (uint256);
}

contract LootClaimer is Ownable, IERC721Receiver {
    function freeClaim(address lootAddress) external returns(uint){
        return claimManyWithTip(lootAddress, 3);
    }

    function claimManyWithTip(address lootAddress, uint number) public payable returns(uint){
        ILoot loot = ILoot(lootAddress);
        uint supply = loot.totalSupply();

        uint[] memory tokenIds = new uint[](number);
        for(uint i = 0; i < number; i++){
            tokenIds[i] = supply + i + 1;
        }

        return claimSelectedTokensWithTip(lootAddress, tokenIds);
    }

    function claimSelectedTokensWithTip(address lootAddress, uint[] memory tokenIds) public payable returns(uint){
        uint cnt = 0;
        for(uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            (bool success, bytes memory returnData) = lootAddress.call(abi.encodeWithSignature("claim(uint256)", tokenId));
            if(success) {
                cnt += 1;

                //send back NFT
                IERC721(lootAddress).transferFrom(address(this), msg.sender, tokenId);
            }
        }

        require(msg.value >= 0.01 ether * (cnt/4), "0.01 for each 4 mint");

        return cnt;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4){
        return LootClaimer.onERC721Received.selector;
    }

    // TOKEN WITHDRAW

    function withdrawEther() public {
        uint256 balance = address(this).balance;
        payable(owner()).call{value: balance}("");
    }

    function withdrawERC20(address _token) public onlyOwner {
        IERC20 erc20 = IERC20(_token);
        erc20.transfer(owner(), erc20.balanceOf(address(this)));
    }

    function withdrawNFTs(address contractAdx, uint256[] calldata tokenIds) public onlyOwner {
        uint256 i = 0;
        for (; i < tokenIds.length; i++) {
            IERC721(contractAdx).transferFrom(address(this), owner(), tokenIds[i]);
        }
    }

}