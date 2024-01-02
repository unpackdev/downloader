// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./LeafNFTContractUpgradeable.sol";

contract LeafNFTContractUpgradeableV2 is LeafNFTContractUpgradeable{
    function setFee_nolimit(uint256 _fee) external onlyAdmin(){
        fee = _fee;
        emit FeeEvent(fee);
    }

}