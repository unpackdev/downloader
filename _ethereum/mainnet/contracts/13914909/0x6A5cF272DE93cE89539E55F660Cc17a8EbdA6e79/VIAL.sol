pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

import "./ERC20Burnable.sol";
import "./Ownable.sol";

interface IFarFetched {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract VIALToken is ERC20Burnable, Ownable {
    uint256 public immutable VIAL_PER_DAY = 1 ether; // 1 VIAL per day
    uint256 public START;
    uint256 public END = 1956349200; // Monday, 29. December 2031 22:20:00
    IFarFetched public farFetchedContract;

    mapping(uint256 => uint256) public last;
    mapping(address => bool) private admins;

    constructor(address _address) ERC20("VIAL", "VIAL") {
        START = block.timestamp;
        farFetchedContract = IFarFetched(_address);
    }

    function mintForIds(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            address owner = farFetchedContract.ownerOf(id);
            uint256 claimed = lastClaim(id);
            uint256 base = getCorrectTimeStamp();
            uint256 owed = (base - claimed) * (VIAL_PER_DAY / 24 / 60 / 60);
            last[id] = base;
            _mint(owner, owed);
        }
    }

    function mint(address to, uint256 amount) external {
        require(admins[msg.sender], "Only admins can mint");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(admins[msg.sender], "Only admins can burn");
        _burn(from, amount);
    }

    function getCorrectTimeStamp() internal view returns (uint256) {
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
        uint256 owed = (base - claimed) * (VIAL_PER_DAY / 24 / 60 / 60);
        return owed;
    }

    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }
}
