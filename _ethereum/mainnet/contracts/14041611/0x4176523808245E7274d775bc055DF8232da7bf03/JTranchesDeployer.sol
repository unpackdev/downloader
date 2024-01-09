// SPDX-License-Identifier: MIT
/**
 * Created on 2021-02-11
 * @summary: Jibrel Aave Tranche Deployer
 * @author: Jibrel Team
 */
pragma solidity 0.8.8;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IJTranchesDeployer.sol";
import "./IJAdminTools.sol";
import "./JTrancheAToken.sol";
import "./JTrancheBToken.sol";
import "./JTranchesDeployerStorage.sol";

contract JTranchesDeployer is OwnableUpgradeable, JTranchesDeployerStorage, IJTranchesDeployer {
    using SafeMathUpgradeable for uint256;

    function initialize() external initializer() {
        OwnableUpgradeable.__Ownable_init();
    }

    function setJAaveAddresses(address _jAaveAddress, address _jATAddress) external onlyOwner {
        jAaveAddress = _jAaveAddress;
        jAdminToolsAddress = _jATAddress;
    }

    modifier onlyProtocol() {
        require(msg.sender == jAaveAddress, "TrancheDeployer: caller is not JAave");
        _;
    }

    function deployNewTrancheATokens(string memory _nameA, 
            string memory _symbolA, 
            uint256 _trNum) external override onlyProtocol returns (address) {
        JTrancheAToken jTrancheA = new JTrancheAToken(_nameA, _symbolA, _trNum);
        jTrancheA.setJAaveMinter(msg.sender); 
        // add tranche address to admins!
        IJAdminTools(jAdminToolsAddress).addAdmin(address(jTrancheA));
        return address(jTrancheA);
    }

    function deployNewTrancheBTokens(string memory _nameB, 
            string memory _symbolB, 
            uint256 _trNum) external override onlyProtocol returns (address) {
        JTrancheBToken jTrancheB = new JTrancheBToken(_nameB, _symbolB, _trNum);
        jTrancheB.setJAaveMinter(msg.sender);
        // add tranche address to admins!
        IJAdminTools(jAdminToolsAddress).addAdmin(address(jTrancheB));
        return address(jTrancheB);
    }

    function setNewJAaveTokens(address _newJAave, address _trAToken, address _trBToken) external onlyOwner {
        require((_newJAave != address(0)) && (_trAToken != address(0)) && (_trBToken != address(0)), "TrancheDeployer: some address is not allowed");
        JTrancheAToken(_trAToken).setJAaveMinter(_newJAave);
        JTrancheAToken(_trBToken).setJAaveMinter(_newJAave);
    }

}