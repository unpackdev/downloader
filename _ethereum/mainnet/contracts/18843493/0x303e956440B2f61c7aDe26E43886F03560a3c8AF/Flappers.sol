// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

// this is all we need from rlBTRFLY
interface IERC20Decimals {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}

contract Flappers is ERC1155, Ownable {
    IERC20Decimals public rlBTRFLY;
    uint public mintCost;
    uint[] public levels;
    mapping(uint => bool) public validLevels;
    mapping(address => mapping(uint => bool)) public hasMinted;

    constructor(address _owner, address _rlBTRFLY, uint _mintCost, uint[] memory _levels)
        ERC1155("https://flappers.sirsean.me/metadata/{id}.json")
        Ownable(_owner)
        {
        rlBTRFLY = IERC20Decimals(_rlBTRFLY);
        mintCost = _mintCost;
        for (uint i = 0; i < _levels.length; i++) {
            addLevel(_levels[i]);
        }
    }

    function addLevel(uint _level) public onlyOwner {
        if (!validLevels[_level]) {
            validLevels[_level] = true;
            levels.push(_level);
        }
    }

    function getLevels() public view returns (uint[] memory) {
        return levels;
    }

    function setMintCost(uint _newCost) public onlyOwner {
        mintCost = _newCost;
    }

    function hasAddressMinted(address addr, uint level) public view returns (bool) {
        return hasMinted[addr][level];
    }

    function hasLockedEnough(address addr, uint level) public view returns (bool) {
        uint8 decimals = rlBTRFLY.decimals();
        uint256 adjustedLevel = level * (10 ** uint256(decimals));
        return rlBTRFLY.balanceOf(addr) >= adjustedLevel;
    }

    function addrCanMint(address addr, uint level) public view returns (bool) {
        // cannot mint if this level has already been minted
        if (hasAddressMinted(addr, level)) {
            return false;
        }
        // can mint if the rlBTRFLY balance is greater than or equal to the level
        if (!hasLockedEnough(addr, level)) {
            return false;
        }
        // can mint if this level is valid
        if (!validLevels[level]) {
            return false;
        }
        return true;
    }

    function canMint(uint level) public view returns (bool) {
        return addrCanMint(msg.sender, level);
    }

    function mint(uint level) public payable {
        require(!hasAddressMinted(msg.sender, level), "Already minted this level");
        require(hasLockedEnough(msg.sender, level), "Insufficient rlBTRFLY balance");
        require(canMint(level), "Cannot mint this level");
        require(msg.value >= mintCost, "Insufficient ETH sent");

        hasMinted[msg.sender][level] = true;
        _mint(msg.sender, level, 1, "");

        payable(owner()).transfer(msg.value);
    }

    function uri(uint256 _tokenId) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://flappers.sirsean.me/metadata/",
                Strings.toString(_tokenId),".json"
            )
        );
    }
}
