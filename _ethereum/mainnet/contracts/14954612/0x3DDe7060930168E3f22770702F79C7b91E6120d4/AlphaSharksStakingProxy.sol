// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721.sol";
import "./Ownable.sol";

/*
░█████╗░██╗░░░░░██████╗░██╗░░██╗░█████╗░  ░██████╗██╗░░██╗░█████╗░██████╗░██╗░░██╗░██████╗
██╔══██╗██║░░░░░██╔══██╗██║░░██║██╔══██╗  ██╔════╝██║░░██║██╔══██╗██╔══██╗██║░██╔╝██╔════╝
███████║██║░░░░░██████╔╝███████║███████║  ╚█████╗░███████║███████║██████╔╝█████═╝░╚█████╗░
██╔══██║██║░░░░░██╔═══╝░██╔══██║██╔══██║  ░╚═══██╗██╔══██║██╔══██║██╔══██╗██╔═██╗░░╚═══██╗
██║░░██║███████╗██║░░░░░██║░░██║██║░░██║  ██████╔╝██║░░██║██║░░██║██║░░██║██║░╚██╗██████╔╝
╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░

░██████╗████████╗░█████╗░██╗░░██╗██╗███╗░░██╗░██████╗░  ███████╗██████╗░░█████╗░███████╗██████╗░░░███╗░░
██╔════╝╚══██╔══╝██╔══██╗██║░██╔╝██║████╗░██║██╔════╝░  ██╔════╝██╔══██╗██╔══██╗╚════██║╚════██╗░████║░░
╚█████╗░░░░██║░░░███████║█████═╝░██║██╔██╗██║██║░░██╗░  █████╗░░██████╔╝██║░░╚═╝░░░░██╔╝░░███╔═╝██╔██║░░
░╚═══██╗░░░██║░░░██╔══██║██╔═██╗░██║██║╚████║██║░░╚██╗  ██╔══╝░░██╔══██╗██║░░██╗░░░██╔╝░██╔══╝░░╚═╝██║░░
██████╔╝░░░██║░░░██║░░██║██║░╚██╗██║██║░╚███║╚██████╔╝  ███████╗██║░░██║╚█████╔╝░░██╔╝░░███████╗███████╗
╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░  ╚══════╝╚═╝░░╚═╝░╚════╝░░░╚═╝░░░╚══════╝╚══════╝
*/

struct Locker {
    bool locked;  // 0 -> Unlocked, 1 -> Locked
    uint256 tokenNumber;
    address lockerOwner;
}

interface IAlphaLocker {
    function nftLocked(address owner) external view returns (uint256);
    function nftLocker(uint256 tokenId) external view returns (Locker memory);
}

contract AlphaSharksStakingProxy is ERC721, Ownable {
    constructor() ERC721("AlphaSharksStakingProxy", "ASTP") {}

    address public alphaLocker;

    function setAlphaLockerAddress(address _alphaLocker) external onlyOwner {
        alphaLocker = _alphaLocker;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint256 balance = IAlphaLocker(alphaLocker).nftLocked(owner);
        return balance;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
       Locker memory _locker = IAlphaLocker(alphaLocker).nftLocker(tokenId);
       return address(_locker.lockerOwner);
    }
}