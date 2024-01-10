
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
import "./EGovernanceBase.sol";

contract EKotketNFTPurchaseBase is EGovernanceBase{
    bool public allowedWeiPurchase = false;
    bool public allowedKotketTokenPurchase = true;

    constructor(address _governanceAdress) EGovernanceBase(_governanceAdress) {
    }

    function allowWeiPurchase(bool _allow) public onlyAdminPermission{
        allowedWeiPurchase = _allow;
    }

     function allowKotketTokenPurchase(bool _allow) public onlyAdminPermission{
        allowedKotketTokenPurchase = _allow;
    }    
}
