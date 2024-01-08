pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

import "./ERC20Burnable.sol";

interface IButts {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

contract ShitCoin is ERC20Burnable {
    uint256 public immutable SHIT_PER_DAY_PER_SECOND = 115740740700000; // 10 shit per day
    uint256 public START;
    IButts public buttsContract;

    mapping(uint256 => uint256) public last;

    constructor(address _buttsAddress) ERC20("ShitCoin", "SHIT") {
        START = block.timestamp;
        buttsContract = IButts(_buttsAddress);
    }

    function mintForUser(address user) external {
        uint256 total = buttsContract.balanceOf(user);
        uint256 owed = 0;
        for (uint256 i = 0; i < total; i++) {
            uint256 id = buttsContract.tokenOfOwnerByIndex(user, i);
            uint256 claimed = lastClaim(id);
            owed += ((block.timestamp - claimed) * SHIT_PER_DAY_PER_SECOND);
            last[id] = block.timestamp;
        }
        _mint(user, owed);
    }

    function mintForIds(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            address owner = buttsContract.ownerOf(id);
            uint256 claimed = lastClaim(id);
            uint256 owed = (block.timestamp - claimed) * SHIT_PER_DAY_PER_SECOND;
            _mint(owner, owed);
            last[id] = block.timestamp;
        }
    }
    
    function lastClaim(uint256 id) public view returns (uint256) {
        return max(last[id], START);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

}
