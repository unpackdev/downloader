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
    uint256 public END = 1950048000; // Saturday, 18. October 2031 00:00:00
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
            uint256 base = getCorrectTimeStamp();
            owed += (base - claimed) * SHIT_PER_DAY_PER_SECOND;
            last[id] = base;
        }
        _mint(user, owed);
    }

    function mintForIds(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            address owner = buttsContract.ownerOf(id);
            uint256 claimed = lastClaim(id);
            uint256 base = getCorrectTimeStamp();
            uint256 owed = (base - claimed) * SHIT_PER_DAY_PER_SECOND;
            last[id] = base;
            _mint(owner, owed);
        }
    }

    function getCorrectTimeStamp() public view returns (uint256) {
        return min(block.timestamp, END);
    }

    function lastClaim(uint256 id) public view returns (uint256) {
        return max(last[id], START);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function claimablePerId(uint256 id) public view returns (uint256) {
        uint256 claimed = lastClaim(id);
        uint256 base = getCorrectTimeStamp();
        uint256 owed = (base - claimed) * SHIT_PER_DAY_PER_SECOND;
        return owed;
    }

    function totalClaimablePerAddress(address user)
        public
        view
        returns (uint256)
    {
        uint256 total = buttsContract.balanceOf(user);
        uint256 owed = 0;

        for (uint256 i = 0; i < total; i++) {
            uint256 id = buttsContract.tokenOfOwnerByIndex(user, i);
            uint256 claimed = lastClaim(id);
            uint256 base = getCorrectTimeStamp();
            owed += ((base - claimed) * SHIT_PER_DAY_PER_SECOND);
        }

        return owed;
    }
}
