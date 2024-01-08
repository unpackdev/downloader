// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./SafeMath.sol";

interface IStake {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IBancorInsurance {
    function protectedLiquidity(uint256 id) external view returns 
            (address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256);
    function protectedLiquidityIds(address provider) external view returns (uint256[] memory);
    function protectedLiquidityCount(address provider) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


contract ICHIBancorInsurance {
    using SafeMath for uint256;

    string public DESCRIPTION = "ICHIPowah Interperter for ichi LP tokens in Bancor Insurance";

    address public ICHIaddress = 0x903bEF1736CDdf2A537176cf3C64579C3867A881; //mainnet

    address public BancorLiquidityProtectionStore = 0xf5FAB5DBD2f3bf675dE4cB76517d4767013cfB55;
    address public BancorToken = 0x563f6e19197A8567778180F66474E30122FD702A;
     

    function getSupply(address instance) public view returns (uint256 ichi) {
        IStake stake = IStake(instance);
        IERC20 ichiToken = IERC20(ICHIaddress);

        ichi = ichiToken.balanceOf(address(stake));
    }

    function getPowah(address /*instance*/, address user, bytes32 /*params*/) public view returns (uint256 ichi) {
        // get amount staked in Bancor Insurance
        IBancorInsurance bancor = IBancorInsurance(BancorLiquidityProtectionStore);
        uint256 count = bancor.protectedLiquidityCount(user);
    
        if (count > 0) {
            uint256[] memory ids = bancor.protectedLiquidityIds(user);
            
            for(uint256 i=0; i<count; i++) {
                uint256 id = ids[i];
                (
                    ,
                    address poolToken,
                    address reserveToken,
                    ,
                    uint256 reserveTokenAmount,
                    ,
                    ,
                    
                ) = bancor.protectedLiquidity(id);
                if (poolToken == BancorToken && reserveToken == ICHIaddress) {
                    ichi = ichi.add(reserveTokenAmount);
                }
            }
        }
    }
}

