// contracts/HodlersNamingContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./INCT.sol";

/**
 * @title HodlersNamingContract
 * @dev In this implementation, the contract defining NFTs has already been implemented.
 * This contract then defines an external database that contains the names of the various tokens.
 *
 * Authors: s.imo
 * Created: 02.07.2021
 * Last revision: 26.07.2021: set name change price already ready for a real example
 */
contract HodlersNamingContract is Ownable {

    // The name change price, you can set your own
    uint256 public constant NAME_CHANGE_PRICE = 200 * (10 ** 18);

    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nameReserved;

    // your NFT contract pointer
    IERC721 private _nft;
    // the NCT contract pointer
    INCT    private _nct;

    // Events
    event NameChange (uint256 indexed maskIndex, string newName);


    /**
     * @dev Constructor that stores the NFT and NCT pointer
     * The parameters are:
     * nftAddress - address of your NFT contract
     * nctAddress - address of the NCT contract
     */
    constructor(address nftAddress, address nctAddress) {
        //NOTE: here you can check if the required functions are implemented by IERC165
        _nft = IERC721(nftAddress);
        _nct = INCT(nctAddress);
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    /**
     * @dev Changes the name for Hashmask tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        // NOTE: the ownership shall be enforced in this name database contract
        address owner = _nft.ownerOf(tokenId);

        require(_msgSender() == owner, "Caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        _nct.transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        _nct.burn(NAME_CHANGE_PRICE);
        emit NameChange(tokenId, newName);
    }


    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(!(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x20) //space
            ) return false;


            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

}