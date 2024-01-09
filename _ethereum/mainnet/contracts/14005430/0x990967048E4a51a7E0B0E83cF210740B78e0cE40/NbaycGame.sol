// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC20.sol";
import "./ERC721.sol";
import "./StakeApe.sol";
import "./IAgency.sol";

import "./console.sol";

interface ITokenBall {
    function mintReward(address recipient, uint amount) external;
    function burnMoney(address recipient, uint amount) external;
}

/**
 * Headquarter of the New Basketball Ape Young Crew Agency
 * Organize matches, stakes the Apes for available for rent, sends rewards, etc
 */
contract NbaycGame is ERC721 {

    bool closed = false;

    uint constant baseTrainingRewardRatePerMinute = 100;
    mapping(address => bool) admins;
    address _agencyAddress;
    address _ballAddress;

    constructor(address adminAddr, address _agency, address _ball) ERC721("NBAYCAgency", "NBAYCA") {
        admins[adminAddr] = true;
        _agencyAddress = _agency;
        _ballAddress = _ball;
    }

    //
    //// Utility functions
    //

    function putApesToAgency(uint[] memory ids) external {
        require(!closed, "This contract is closed.");
        IAgency(_agencyAddress).putApesToAgency(ids, msg.sender);
    }
    function getApesFromAgency(uint[] memory ids) external {
        require(!closed, "This contract is closed.");
        IAgency(_agencyAddress).getApesFromAgency(ids, msg.sender);
    }

    function startTraining(uint[] memory ids) external {
        require(!closed, "This contract is closed.");
        IAgency(_agencyAddress).setStateForApes(ids, msg.sender, 'T');
    }

    function stopTraining(uint[] memory ids) external {
        require(!closed, "This contract is closed.");
        uint totalReward = 0;
        for (uint i=0; i<ids.length; i++) {
            uint duration = IAgency(_agencyAddress).stopStateForApe(ids[i], msg.sender);
            totalReward += duration * baseTrainingRewardRatePerMinute; // Could change for lengedaries ? Rares ? Skills ?
        }
        console.log("Total reward : %s", totalReward);
        ITokenBall(_ballAddress).mintReward(msg.sender, totalReward);
    }

    //
    // Admin functions :
    //
    
    function setClosed (bool c) public onlyAdmin {
        closed = c;
    }

    function getApe(uint id) public view returns(uint256,address,bytes1,uint256) {
        return IAgency(_agencyAddress).getApe(id);
    }

    function getOwnerApes(address a) external view returns(uint[] memory) {
        return IAgency(_agencyAddress).getOwnerApes(a);
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can call this");
        _;
    }

    function setAdmin(address addr) public {
        admins[addr] = true;
    }

    function unsetAdmin(address addr) public {
        delete admins[addr];
    }

    function setContracts(address _agency, address _ball) external onlyAdmin() {
        _agencyAddress = _agency;
        _ballAddress = _ball;
    }
}

