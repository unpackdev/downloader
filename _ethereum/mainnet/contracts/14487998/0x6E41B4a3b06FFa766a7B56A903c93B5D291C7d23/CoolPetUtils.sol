// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface ICoolPets {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract CoolPetUtils is Ownable {

    // Addresses
    address public _coolPetContractAddress;

    constructor(address coolPetContractAddress) {
        _coolPetContractAddress = coolPetContractAddress;
    }

    /// @notice Helper function to convert uint to string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /// @notice Helper function to check if an account owns any pets from a selection
    /// @param account Address of account to check against
    /// @param start TokenId to start checking from
    /// @param count Total number of tokens to check from the `start`
    /// @return string String of ids the `account` owns
    function getWalletOfOwnerForSelection(address account, uint256 start, uint256 count) external view returns(string memory) {

        string memory output;

        ICoolPets iface = ICoolPets(_coolPetContractAddress);

        for(uint256 i = start; i < (start + count); i++) {
            try iface.ownerOf(i) returns (address owner) {
                if(owner == account){
                    output = string(abi.encodePacked(output, uint2str(i), ","));
                }
            } catch {
                // do nothing
            }
        }
        return output;
    }

    /// @notice Helper function to check if submitted cat ids have claimed pets
    /// @dev This function only supports cat ids up to 9998. There are no cats beyond that point
    /// @param catIds Array of cat ids
    /// @return string String of cats ids that have claimed pets
    function getClaimedPetsFromCatIds(uint256[] memory catIds) external view returns(string memory) {

        string memory output;

        for(uint256 i; i < catIds.length; i++) {
            if(catIds[i] < 9999){
                try ICoolPets(_coolPetContractAddress).ownerOf(catIds[i]) {
                    output = string(abi.encodePacked(output, uint2str(catIds[i]), ","));
                } catch {
                    // do nothing
                }
            }
        }
        return output;
    }

    function setCoolPetsContractAddress(address coolPetsContractAddress) external onlyOwner {
        require(coolPetsContractAddress != address(0), "PU 100 - Invalid address");
        _coolPetContractAddress = coolPetsContractAddress;
    }
}
