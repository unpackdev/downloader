// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract BlueCheckClub is
    ERC1155,
    Ownable,
    ERC1155Burnable,
    ERC1155Supply,
    ReentrancyGuard,
    Pausable
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    string public name;
    string public symbol;

    uint256 constant MAX_TOTAL_SUPPLY = 100000;
    uint256 constant BLUE = 1;
    uint256 constant GOLD = 2;

    Counters.Counter public currentMint;

    mapping(address => bool) public hasClaimed;
    mapping(uint => string) public tokenURI;

    event URIUpdated(string newURI, uint256 TokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _blueURI,
        string memory _goldURI
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        tokenURI[1] = _blueURI;
        tokenURI[2] = _goldURI;
        _pause();
    }

    function mint() external nonReentrant whenNotPaused {
        require(
            hasClaimed[msg.sender] != true,
            "BCC: account has already claimed"
        );
        uint256 thisMint = currentMint.current();
        require(thisMint + 1 <= MAX_TOTAL_SUPPLY, "BCC: all tokens claimed");

        uint256 idToMint = 1;
        if (thisMint % 100 == 0) {
            idToMint = 2;
        }

        currentMint.increment();
        hasClaimed[msg.sender] = true;
        _mint(msg.sender, idToMint, 1, "");
    }

    function uri(uint _id) public view override returns (string memory) {
        return tokenURI[_id];
    }

    function setURI(uint _id, string memory newuri) external onlyOwner {
        tokenURI[_id] = newuri;
        emit URIUpdated(newuri, _id);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
