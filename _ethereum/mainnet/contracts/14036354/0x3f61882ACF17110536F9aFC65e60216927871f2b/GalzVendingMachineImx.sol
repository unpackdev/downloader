// SPDX-License-Identifier: MIT

/*

╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋╋╋┏┓
╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋╋╋╋┃┃
┏━━┳┓╋┏┫┗━┳━━┳━┳━━┳━━┫┃┏━━━┓
┃┏━┫┃╋┃┃┏┓┃┃━┫┏┫┏┓┃┏┓┃┃┣━━┃┃
┃┗━┫┗━┛┃┗┛┃┃━┫┃┃┗┛┃┏┓┃┗┫┃━━┫
┗━━┻━┓┏┻━━┻━━┻┛┗━┓┣┛┗┻━┻━━━┛
╋╋╋┏━┛┃╋╋╋╋╋╋╋╋┏━┛┃
╋╋╋┗━━┛╋╋╋╋╋╋╋╋┗━━┛

*/

pragma solidity ^0.8.4;

library Bytes {
    /**
     * @dev Converts a `uint256` to a `string`.
     * via OraclizeAPI - MIT licence
     * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     */
    function fromUint(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }

    bytes constant alphabet = "0123456789abcdef";

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(
        bytes memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _base.length; i++) {
            if (_base[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    function substring(
        bytes memory strBytes,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function toUint(bytes memory b) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 val = uint256(uint8(b[i]));
            if (val >= 48 && val <= 57) {
                result = result * 10 + (val - 48);
            }
        }
        return result;
    }
}

/*

╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋╋╋┏┓
╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋╋╋╋┃┃
┏━━┳┓╋┏┫┗━┳━━┳━┳━━┳━━┫┃┏━━━┓
┃┏━┫┃╋┃┃┏┓┃┃━┫┏┫┏┓┃┏┓┃┃┣━━┃┃
┃┗━┫┗━┛┃┗┛┃┃━┫┃┃┗┛┃┏┓┃┗┫┃━━┫
┗━━┻━┓┏┻━━┻━━┻┛┗━┓┣┛┗┻━┻━━━┛
╋╋╋┏━┛┃╋╋╋╋╋╋╋╋┏━┛┃
╋╋╋┗━━┛╋╋╋╋╋╋╋╋┗━━┛

*/
// File: contracts/galz/utils/Minting.sol

pragma solidity ^0.8.4;


library Minting {
    // Split the minting blob into token_id and blueprint portions
    // {token_id}:{blueprint}

    function split(bytes calldata blob)
        internal
        pure
        returns (uint256, bytes memory)
    {
        int256 index = Bytes.indexOf(blob, ":", 0);
        require(index >= 0, "Separator must exist");
        // Trim the { and } from the parameters
        uint256 tokenID = Bytes.toUint(blob[1:uint256(index) - 1]);
        uint256 blueprintLength = blob.length - uint256(index) - 3;
        if (blueprintLength == 0) {
            return (tokenID, bytes(""));
        }
        bytes calldata blueprint = blob[uint256(index) + 2:blob.length - 1];
        return (tokenID, blueprint);
    }
}

/*
╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋╋╋┏┓
╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋╋╋╋┃┃
┏━━┳┓╋┏┫┗━┳━━┳━┳━━┳━━┫┃┏━━━┓
┃┏━┫┃╋┃┃┏┓┃┃━┫┏┫┏┓┃┏┓┃┃┣━━┃┃
┃┗━┫┗━┛┃┗┛┃┃━┫┃┃┗┛┃┏┓┃┗┫┃━━┫
┗━━┻━┓┏┻━━┻━━┻┛┗━┓┣┛┗┻━┻━━━┛
╋╋╋┏━┛┃╋╋╋╋╋╋╋╋┏━┛┃
╋╋╋┗━━┛╋╋╋╋╋╋╋╋┗━━┛
*/

// CyberGalz Legal Overview [https://cybergalznft.com/legaloverview]

pragma solidity >=0.8.4;

import "./Strings.sol";
import "./Context.sol";
import "./Address.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

abstract contract GalzInterface {
    function mintTransfer(address to) public virtual returns(uint256);
}

contract GalzVendingMachineImx is ERC721, Ownable { 
    using SafeMath for uint256;

    string private _baseURIextended;
    string private _salt;

    address galzVendingMachineEthAddress;
    address public imx;

    mapping(uint256 => bytes) public blueprints;

    event MigrationComplete(address indexed to, uint16 quantity, string salt);

    event AssetMinted(address to, uint256 id, bytes blueprint);
    event Minted(address indexed to, uint256 id);
    event Withdraw(uint amount);

    constructor(
        string memory _name,
        string memory _ticker,
        string memory baseURI_,
        address _imx
    ) ERC721(_name, _ticker) {
        _baseURIextended = baseURI_;
        imx = _imx;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setSalt(string memory salt_) public onlyOwner {
        _salt = salt_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function mintTransfer(address to) public {
        require(msg.sender == galzVendingMachineEthAddress, "Not authorized");

        emit MigrationComplete(to, 1, _salt);
    }

    // Set authorized contract address for minting the ERC-721 token
    function setGalzVendingMachineEthContract(address contractAddress) public onlyOwner {
        galzVendingMachineEthAddress = contractAddress;
    }

    modifier onlyOwnerOrIMX() {
        require(msg.sender == imx || msg.sender == owner(), "Function can only be called by owner or IMX");
        _;
    }

    modifier onlyIMX() {
        require(msg.sender == imx, "Function can only be called by IMX");
        _;
    }

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external onlyIMX {
        require(quantity == 1, 'Mintable: invalid quantity');
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        _mintFor(user, id, blueprint);

        emit Minted(user, id);
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal {
        _safeMint(user, id);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}