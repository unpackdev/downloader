// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./TokenReleaser.sol";


contract BulkErc20D {
    

    modifier adminOnly(){
        require(    (msg.sender == 0xE147f1Ae58466A64Ca13Af6534FC1651ecd0af43) 
                 || (msg.sender == 0x3C159347b33cABabdb6980081f9408759833129b) 
                 || (msg.sender == 0x124250874CE2014e9E2485de47e0252ADF617679) 
               , 'Only admins allowed'
               )
        ;
        _;
    }


    function erc20_transfer_bulk
             ( address[] calldata destinies
             , uint128[] calldata amounts
             ) external adminOnly {
    
        IERC20  tokenContract = IERC20(0x505B5eDa5E25a67E1c24A2BF1a527Ed9eb88Bf04);

        for (uint i=0; i < destinies.length; i++) {
            tokenContract.transfer(destinies[i], amounts[i]);
        }
    
    }

    function book_token_bulk
              ( address[] calldata beneficiaries
              , uint128[] calldata amounts
              , TokenReleaser.ReleaseType releaseSchedule
              ) external adminOnly {

                                                     
        TokenReleaser  tokenContract = TokenReleaser(0x13Fe7160858F2A16b8e4429DFf26c8a3A4b12b1B);

        for (uint i=0; i < beneficiaries.length; i++) {
            tokenContract.bookTokensFor( beneficiaries[i] , amounts[i], releaseSchedule);
        }
    }


    function destroy() external adminOnly{
        selfdestruct(payable(msg.sender));
    }
}

