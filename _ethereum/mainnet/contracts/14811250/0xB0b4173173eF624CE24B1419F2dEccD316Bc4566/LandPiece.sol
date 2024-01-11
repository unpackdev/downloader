// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155SupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ILandPiece.sol";

contract LandPiece is
    Initializable,
    ERC1155SupplyUpgradeable,
    OwnableUpgradeable,
    ILandPiece
{
    using SafeMath for uint256;

    string internal baseURI;
    uint256 public constant LANDPIECE = 0;
    address public manager;

    function initialize() external initializer {
        __Ownable_init();
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function.");
        _;
    }

    function mintFor(address to, uint8 id) external override onlyManager {
        _mint(to, id, 1, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(bytes(baseURI).length > 0, "ERC1155#uri: BLANK_URI");
        return string(abi.encodePacked(baseURI, Strings.toString(_id)));
    }

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
        baseURI = newURI;
    }

    function setManagerAddress(address _managerAddress) public onlyOwner {
        manager = _managerAddress;
    }
}
