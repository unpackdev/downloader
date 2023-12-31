// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ERC1155 {
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
}

contract BalanceOfBatchDataToString {

    function simpleBatchBalances(address erc1155ContractAddress, address account, uint256 idRangeStart, uint256 idRangeEnd) external view returns (string memory) {
        require(idRangeStart <= idRangeEnd, "Invalid range");
        
        address[] memory accountsArray = new address[](idRangeEnd - idRangeStart + 1);
        uint256[] memory idsArray = new uint256[](idRangeEnd - idRangeStart + 1);

        for (uint256 i = 0; i <= idRangeEnd - idRangeStart; i++) {
            accountsArray[i] = account;
            idsArray[i] = (idRangeStart + i);
        }

        return getBalanceOfBatchAsSingleString(erc1155ContractAddress, accountsArray, idsArray);
    }

    function getBalanceOfBatchAsSingleString(address erc1155ContractAddress, address[] memory accounts, uint256[] memory ids) internal view returns (string memory) {
        ERC1155 erc1155Contract = ERC1155(erc1155ContractAddress);
        uint256[] memory balances = erc1155Contract.balanceOfBatch(accounts, ids);

        string memory concatenatedBalances;

        for (uint256 i = 0; i < balances.length; i++) {
            if(i == balances.length - 1){
                concatenatedBalances = string(abi.encodePacked(concatenatedBalances, uintToString(balances[i])));
            } else{
                concatenatedBalances = string(abi.encodePacked(concatenatedBalances, uintToString(balances[i]), ","));
            }
        }

        return concatenatedBalances;
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
