// SPDX-License-Identifier: MIT

/// @author Tient Technologies (Twitter:https://twitter.com/tient_tech | Github:https://github.com/Tient-Technologies | | LinkedIn:https://www.linkedin.com/company/tient-technologies/)
/// @dev NiceArti (https://github.com/NiceArti)
/// To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
/// @title The CflatsTerritory contract is used as a key for Cryptoflats NFT. Each gen of territory 
/// represents the key for staking NFT for this gen

pragma solidity ^0.8.18;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ICflatsDatabase.sol";
import "./CflatsDappRequirements.sol";
import "./Harvest.sol";
import "./ICflatsTerritory.sol";


contract CflatsTerritory is ICflatsTerritory, CflatsDappRequirements, Harvest
{
    using SafeERC20 for IERC20;


    address private immutable _UTILITY_TOKEN;


    mapping(address owner => 
        mapping(uint256 gen => uint256 amount)
    ) private _balanceOf;

    constructor(address utilityToken, ICflatsDatabase database) CflatsDappRequirements(database) 
    {
        _UTILITY_TOKEN = utilityToken;
    }


    function buy(
        uint256 gen,
        uint256 amount
    ) external onlyNotBlacklisted returns (bool)
    {
        uint256 territoryPrice = _getPriceForGen(gen);
        require(amount >= territoryPrice, "CflatsTerritory: Insufficient funds for buying territory!");
        
        IERC20(_UTILITY_TOKEN).safeTransferFrom(msg.sender, address(this), amount);

        _transfer(address(0), msg.sender, gen);
        return true;
    }

    function balanceOf(address owner, uint256 gen) external view returns (uint256)
    {
        return _balanceOf[owner][gen];
    }

    function hasTerritoryForGen(
        address owner,
        uint256 gen
    ) external view returns (bool)
    {
        return _balanceOf[owner][gen] != 0;
    }

    function transfer(
        address recipient,
        uint256 gen
    ) external onlyNotBlacklisted returns (bool)
    {
        _transfer(msg.sender, recipient, gen);
        return true;
    }

    function utilityToken() external view returns (address)
    {
        return _UTILITY_TOKEN;
    }


    function getPriceForGen(uint256 gen) external view returns (uint256)
    {
        return _getPriceForGen(gen);
    }


    function _transfer(address from, address to, uint256 gen) private
    {
        if(from != address(0))
        {
            require(_balanceOf[from][gen] > 1, "CflatsTerritory: cannot transfer if balace less than two!");

            unchecked
            {
                --_balanceOf[from][gen];
            }
        }

        unchecked 
        {
            ++_balanceOf[to][gen];
        }
        emit TerritoryTransfer(from, to, gen);
    }

    function _getPriceForGen(uint256 gen) private view returns (uint256)
    {
        uint256 price = 100_000;
        if(gen == 3) 
        {
            price = 150_000;
        }
        else if(gen == 4)
        {
            price = 200_000;
        }
        else if(gen == 5)
        {
            price = 250_000;
        }

        return price * 10**IERC20Metadata(_UTILITY_TOKEN).decimals();
    }
}



