//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";

contract AddressContract is Ownable {

    address private Dao;
    address private Treasury;
    address private PirateNFT;
    address private Pirate;
    address private Bounty;

    function setContractAddresses(address _dao, address _treasury, address _piratenft, address _pirate, address _bounty) external onlyOwner {
        Dao = _dao;
        Treasury = _treasury;
        PirateNFT = _piratenft;
        Pirate = _pirate;
        Bounty = _bounty;
    }

    function setDao(address _dao) external onlyOwner {
        Dao = _dao;
    }

    function setTreasury(address _treasury) external onlyOwner {
        Treasury = _treasury;
    }

    function setPirateNFT(address _piratenft) external onlyOwner {
       PirateNFT = _piratenft;
    }

    function setPirate(address _pirate) external onlyOwner {
       Pirate = _pirate;
    }

    function setBounty(address _bounty) external onlyOwner {
       Bounty = _bounty;
    }

    function getDao() external view returns (address) {
        return Dao;
    }

    function getTreasury() external view returns (address) {
        return Treasury;
    }

    function getPirateNFT() external view returns (address) {
        return PirateNFT;
    }

    function getPirate() external view returns (address) {
        return Pirate;
    }
    function getBounty() external view returns (address) {
        return Bounty;
    }
}