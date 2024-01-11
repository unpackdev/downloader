// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC1155SupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract PawFellowship is ERC1155SupplyUpgradeable, OwnableUpgradeable {
    uint256 public constant Paw_Fellowship = 1;
    string internal baseURI;
    mapping(address => bool) public allowList;
    mapping(address => bool) public mintList;
    address private operation;
    bool public freeMint;

    function initialize() external initializer {
        __Ownable_init();
    }

    modifier onlyManager() {
        require(msg.sender == operation || msg.sender == owner());
        _;
    }

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
        baseURI = newURI;
    }

    /**
     * @dev Mints some amount of tokens to an address
     */
    function mint() public {
        require(allowList[msg.sender] || freeMint);
        require(!mintList[msg.sender]);
        _mint(msg.sender, 1, 1, "");
        mintList[msg.sender] = true;
    }

    function allow(address[] memory _addresses) public onlyManager {
        for (uint8 i = 0; i < _addresses.length; i++) {
            allowList[_addresses[i]] = true;
        }
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_id)));
    }

    function setOps(address _a) public onlyOwner {
        operation = _a;
    }

    function toggleFreeMint() public onlyOwner {
        freeMint = !freeMint;
    }
}
