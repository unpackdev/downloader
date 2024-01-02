// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Strings.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";

contract ChamberOfGlory is
    UUPSUpgradeable,
    ERC1155BurnableUpgradeable,
    OwnableUpgradeable
{
    string public baseURI;
    address public minter;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyOwner {}

    function contractURI() public pure returns (string memory) {
        string
            memory json = '{"name": "Chamber Of Glory","description":"The Chamber of Glory is the sacred reliquary of Forgotten Runes Trophies"}';
        return string.concat("data:application/json;utf8,", json);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(
            msg.sender == owner() || msg.sender == minter,
            "Not authorized to mint"
        );
        _mint(account, id, amount, data);
    }
}
