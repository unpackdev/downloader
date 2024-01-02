// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./HackataoContract.sol";

contract HackataoContractFactory is Ownable {
    mapping(address => bool) public allowedDeployer;

    modifier onlyDeployer() {
        require(allowedDeployer[msg.sender], "ProtectedMintBurn: caller is not a minter");

        _;
    }

    function addDeployer(address _deployer) external onlyOwner {
        allowedDeployer[_deployer] = true;
    }

    function removeDeployer(address _deployer) external onlyOwner {
        allowedDeployer[_deployer] = false;
    }

    function createContract(
        uint96 _royalty,
        string memory _name,
        string memory _symbol
    ) public onlyDeployer returns (address) {
        HackataoContract newContract = new HackataoContract(_royalty, _name, _symbol);
        newContract.setDefaultRoyalty(msg.sender, _royalty);
        newContract.addMinter(msg.sender);
        newContract.transferOwnership(msg.sender);

        return address(newContract);
    }
}
