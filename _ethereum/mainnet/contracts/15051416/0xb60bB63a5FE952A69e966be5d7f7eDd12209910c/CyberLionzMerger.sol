/*
CyberLionz Adults (https://www.cyberlionz.io)

Code crafted by Fueled on Bacon (https://fueledonbacon.com)
*/

// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./ERC721.sol";
import "./Context.sol";
import "./Ownable.sol";

import "./CyberLionzAdults.sol";

pragma solidity ^0.8.12;

contract CyberLionzMerger is Context, Ownable {

    address private immutable _cyberLionz;
    address private immutable _heatToken;
    address private _cyberLionzAdult;

    uint8 public cubMaxTimesAllowedToUse = 2**8-1;

    uint256 public mergePrice;

    mapping(uint256 => uint8) public cubTimesUsed;

    uint256[] private _lockedLionz;

    constructor(
        address cyberLionz, 
        address heatToken, 
        address cyberLionzAdults,
        uint256 mergePrice_) 
    {
        _cyberLionz = cyberLionz;
        _heatToken = heatToken;
        _cyberLionzAdult = cyberLionzAdults;
        mergePrice = mergePrice_;
    }   

    /// @notice cub1 will be the one that will be locked forever
    /// @param cub1 the one that will be locked
    /// @param cub2 the keep slot
    function mergeCubz(uint256 cub1, uint256 cub2) external {
        require(cubTimesUsed[cub2] + 1 <= cubMaxTimesAllowedToUse, "Cub reached max");
        cubTimesUsed[cub2] += 1;
        address sender = _msgSender();
        ERC721(_cyberLionz).transferFrom(sender, address(this), cub1);
        ERC20(_heatToken).transferFrom(sender, address(this), mergePrice);
        _lockedLionz.push(cub1);
        CyberLionzAdults(_cyberLionzAdult).mintFromMerger(sender);
    }

    function withdrawFunds(address to) external onlyOwner {
        ERC20 token = ERC20(_heatToken);
        token.transfer(to, token.balanceOf(address(this)));
    }

    function setMergePrice(uint256 mergePrice_) external onlyOwner {
        require(mergePrice_ > 0, "Merge price canno be 0");
        mergePrice = mergePrice_;
    }

    function setCubMaxTimesAllowedToUse(uint8 cubMaxTimesAllowedToUse_) external onlyOwner {
        require(cubMaxTimesAllowedToUse_ >= 1, "cubMaxTimesAllowedToUse value must be more than 0");
        cubMaxTimesAllowedToUse = cubMaxTimesAllowedToUse_;
    }

    function getLockedLionz() external view returns(uint256[] memory) {
        return _lockedLionz;
    }  

    
}