// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";

import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract NeonsColorChangingNoun is ERC721Delegated {
    uint256 public currentTokenId;
    uint256 public numberOfColors;
    string public baseURI;

    using StringsUpgradeable for uint256;
    
    constructor(
        address baseFactory,
        string memory _baseURI,
        uint256 _numberOfColors
    )
        ERC721Delegated(
            baseFactory,
            "NEONs Color Changing Noun",
            "NCCN",
            ConfigSettings({
                royaltyBps: 1000,
                uriBase: "",
                uriExtension: "",
                hasTransferHook: false
            })
        )
    {
        baseURI = _baseURI;
        numberOfColors = _numberOfColors;
    }

    function mint() public {
        _mint(msg.sender, currentTokenId++);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        uint256 number = unsafeGetRandBetweenOneAndThisInclusive(numberOfColors);
        return string(abi.encodePacked(baseURI, number.toString()));
    }

    function updateBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function updateNumberOfColors(uint256 newNumberOfColors) public onlyOwner {
        numberOfColors = newNumberOfColors;
    }

    function unsafeGetRandBetweenOneAndThisInclusive(uint256 number) private view returns (uint256) {
        return block.timestamp % number + 1;
    }
}
