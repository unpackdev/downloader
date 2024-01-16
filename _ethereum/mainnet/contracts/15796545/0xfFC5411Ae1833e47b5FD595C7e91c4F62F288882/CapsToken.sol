// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract capsToken is ERC20 {
    address private creator;
    address private fixlineBettingContractAddress;
    address private capsStackingContractAddress;

    constructor(uint _initialSupply) ERC20("CapsToken", "CAPS") {
        address msgSender = msg.sender;
        creator = msgSender;
        _mint(msgSender, _initialSupply * 10 ** decimals());
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Only Creator Can Access This Method");
        _;
    }

    modifier onlyFixlineBettingContractOrCreator() {
        require(
            msg.sender == fixlineBettingContractAddress ||
                msg.sender == capsStackingContractAddress ||
                msg.sender == creator,
            "Only FixlineBetting Or Creator Contract Can Access This Method"
        );
        _;
    }

    function mintTokens(address receiver, uint256 amount)
        external
        onlyFixlineBettingContractOrCreator
    {
        _mint(receiver, amount);
    }

    function burnTokens(uint256 amount)
        external
        onlyFixlineBettingContractOrCreator
    {
        _burn(msg.sender, amount);
    }

    /********** Setter Functions **********/

    function setCreatorAddress(address newCreatorAddress)external onlyCreator {
        creator = newCreatorAddress;
    }

    function setfixlineBettingContractAddress(address newContractAddress)
        external
        onlyCreator
    {
        fixlineBettingContractAddress = newContractAddress;
    }

    function setCapsStackingContractAddress(address newContractAddress)
        external
        onlyCreator
    {
        capsStackingContractAddress = newContractAddress;
    }

    /********** View Functions **********/

    function getCreatorAddress() external view returns (address) {
        return creator;
    }

    function getFixlineBettingContractAddress() external view returns (address) {
        return fixlineBettingContractAddress;
    }

    function getCapsStackingContractAddress() external view returns (address) {
        return capsStackingContractAddress;
    }
}
