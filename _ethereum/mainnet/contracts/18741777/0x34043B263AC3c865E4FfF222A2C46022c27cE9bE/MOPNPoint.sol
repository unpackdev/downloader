// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IMOPNGovernance.sol";
import "./IMOPN.sol";
import "./IMOPNBomb.sol";
import "./ERC20.sol";

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/
contract MOPNPoint is ERC20 {
    IMOPNGovernance governance;

    constructor(address governance_) ERC20("MOPN Point", "MP") {
        governance = IMOPNGovernance(governance_);
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return IMOPN(governance.mopnContract()).TotalMOPNPoints();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256 balance) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        IMOPN.AccountDataStruct memory AccountData = mopn.getAccountData(
            account
        );
        if (AccountData.Coordinate > 0) {
            balance += mopn.getAccountOnMapMOPNPoint(account);
            IMOPN.CollectionDataStruct memory CollectionData = mopn
                .getCollectionData(mopn.getAccountCollection(account));
            balance += CollectionData.CollectionMOPNPoint;
        }
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256
    ) internal virtual override {
        require(false, "MOPN Point can't transfer");
    }
}
