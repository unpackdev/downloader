// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Pausable.sol";

import "./SafeDecimalMath.sol";
import "./EthReward.sol";
import "./IPriceFeed.sol";
import "./IEthVault.sol";
import "./AddressBook.sol";
import "./AddressBookLib.sol";


contract LiquidationManager is VaultAccess, ILiquidationManager {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    function liquidate(  
            uint256 vauldId,
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward ) payable external virtual override  onlyVault {

    }
}



contract TestLiquidationManager is LiquidationManager {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    function liquidate(  
            uint256 vauldId,
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward ) payable external override  onlyVault {
        
                
    }
}

