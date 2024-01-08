// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./iRoyaltyDistributor.sol";

contract RoyaltyDistributor is iRoyaltyDistributor, Ownable, ReentrancyGuard {

    address payable[] private recipients;
    uint256[] private royaltiesWithTwoDecimals;

    constructor(
        address payable[] memory _recipients,
        uint256[] memory _royaltiesWithTwoDecimals
    ) {
        _updateRoyalties(_recipients ,_royaltiesWithTwoDecimals);
    }
        
    function withdrawETH() external override nonReentrant {
        uint256 balance = address(this).balance;
        
        for (uint256 i = 0; i < recipients.length; i++) { 
            Address.sendValue(recipients[i], (balance * royaltiesWithTwoDecimals[i]) / 10000);
        }
    }

    function withdrawableETH()
    external
    view
    override
    returns (uint256[] memory)
    {
        uint256 balance = address(this).balance;
         uint256[] memory amounts = new uint256[](recipients.length);
   
        for (uint256 i = 0; i < recipients.length; i++) {
            amounts[i] = balance * royaltiesWithTwoDecimals[i] / 10000;
        }
        
        return amounts;
    }

    function withdrawERC20(address token) external override nonReentrant {
        uint256 balance = ERC20(token).balanceOf(address(this));
        
        for (uint256 i = 0; i < recipients.length; i++) {
            ERC20(token).transfer(recipients[i], balance * royaltiesWithTwoDecimals[i] / 10000);
        }
    }

    function withdrawableERC20(
        address token
    ) external view override returns (uint256[] memory) {
        uint256 balance = ERC20(token).balanceOf(address(this));
        uint256[] memory amounts = new uint256[](recipients.length);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            amounts[i] = balance * royaltiesWithTwoDecimals[i] / 10000;
        }

        return amounts;
    }

    function updateRoyalties(
        address payable[] memory _recipients,
        uint256[] memory _royaltiesWithTwoDecimals
    ) external override onlyOwner {
        _updateRoyalties(_recipients, _royaltiesWithTwoDecimals);
    }

    function _updateRoyalties(
        address payable[] memory _recipients,
        uint256[] memory _royaltiesWithTwoDecimals
    ) internal {
        require(_recipients.length == _royaltiesWithTwoDecimals.length, "Invalid length");
        uint256 totalRoyalties;
        for (uint256 i = 0; i < _recipients.length; i++) { 
            require(_recipients[i] != address(0), "Invalid address");
            require(_royaltiesWithTwoDecimals[i] != 0, "Invalid value");
            
            totalRoyalties += _royaltiesWithTwoDecimals[i];
        }
        require(totalRoyalties == 10000, "Royalties must be 10000 totally");
        
        recipients = _recipients;
        royaltiesWithTwoDecimals = _royaltiesWithTwoDecimals;
    }
    
    receive() external payable {}
}

