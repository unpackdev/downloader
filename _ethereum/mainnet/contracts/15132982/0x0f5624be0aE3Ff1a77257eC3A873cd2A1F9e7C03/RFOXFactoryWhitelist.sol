// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./RFOXNFTWhitelist.sol";
import "./ParamStructs.sol";

contract RFOXFactoryWhitelist is Ownable {
    address[] public allNFTs;

    event NewRFOXNFT(address indexed nftAddress, ParamStructs.WhitelistParams params);

    function createNFT(ParamStructs.WhitelistParams calldata _params) external onlyOwner returns (address newNFT) {
        ParamStructs.WhitelistParams memory params = _params;
        bytes memory bytecode = type(RFOXNFTWhitelist).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(allNFTs.length, params.name, params.symbol)
        );

        assembly {
            newNFT := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        RFOXNFTWhitelist(newNFT).initialize(params);

        allNFTs.push(address(newNFT));

        emit NewRFOXNFT(newNFT, params);

        return address(newNFT);
    }
}
