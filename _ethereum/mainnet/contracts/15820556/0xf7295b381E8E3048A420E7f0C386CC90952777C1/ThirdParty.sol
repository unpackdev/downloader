//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IThirdParty {
    function isAllowed(address user) external view returns (bool);
}

contract ThirdParty is IThirdParty{

    function isAllowed(address user) external pure override returns (bool) {
        return user != address(0);
    }

}