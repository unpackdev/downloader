// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface ILSDVault {
    function darknetAddress() external view returns (address);
    function stakedETHperunshETH() external view returns (uint256);
}

interface IDarknet {
    function checkPrice(address lsd) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
}

contract ZkLensRelayer {

    address public constant lsdVaultAddress = 0x51A80238B5738725128d3a3e06Ab41c1d4C05C74;

    uint public constant lsdsLength = 7;

    //Unsheth LSDs
    address public constant sfrxETHAddress = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    address public constant rETHAddress = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address public constant wstETHAddress = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant cbETHAddress = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
    address public constant ankrETHAddress = 0xE95A203B1a91a908F9B9CE46459d101078c2c3cb;
    address public constant swETHAddress = 0xf951E335afb289353dc249e82926178EaC7DEd78;

    //META LSDs
    address public constant unshETHAddress = 0x0Ae38f7E10A43B5b2fB064B42a2f4514cbA909ef;

    address[lsdsLength] public lsds = [sfrxETHAddress, rETHAddress, wstETHAddress, cbETHAddress, ankrETHAddress, swETHAddress, unshETHAddress];


    constructor() {}

    function darknet() public view returns (IDarknet) {
        return IDarknet(ILSDVault(lsdVaultAddress).darknetAddress());
    }

    function getPrice(address lsd) public view returns (uint256) {
        if(lsd == unshETHAddress) {
            return ILSDVault(lsdVaultAddress).stakedETHperunshETH();
        } else {
            return darknet().checkPrice(lsd);
        }
    }

    function getCirculatingSupplies() public view returns (uint256[] memory) {

        uint256[] memory circSupplyArray = new uint256[](lsdsLength);

        for (uint i = 0; i < lsdsLength; ) {
            circSupplyArray[i] = IERC20(lsds[i]).totalSupply();
            unchecked {i++;}
        }

        return circSupplyArray;
    }

    function getContractRates() external view returns (uint256[] memory) {
        uint256[] memory contractRateArray = new uint256[](lsdsLength);

        for (uint i = 0; i < lsdsLength; ) {
            contractRateArray[i] = getPrice(lsds[i]);
            unchecked {i++;}
        }

        return contractRateArray;
    }
}