// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155Upgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

contract AList is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    OwnableUpgradeable
{
    string public name;
    string public symbol;

    uint256 public PASS_ID;

    uint256 private _passesMinted = 0;

    uint256 public cost;
    uint256 public maxSupply;

    uint128 public publicMintStartTime;
    uint128 public allowlistMintStartTime;

    mapping(address => uint256) public allowlist;

    function initialize(
        string memory _uri,
        uint256 _cost,
        uint128 _maxSupply,
        uint128 _publicMintStart,
        uint128 _allowlistMintStart
    ) public initializer {
        __ERC1155_init(_uri);
        __Ownable_init();
        __ERC1155Supply_init();

        cost = _cost;
        maxSupply = _maxSupply;
        publicMintStartTime = _publicMintStart;
        allowlistMintStartTime = _allowlistMintStart;

        PASS_ID = 1;
        name = "A-List Lifetime Access Pass";
        symbol = "A-List";
    }

    /////////////////////////////////////////////////////////////
    // MINTING
    /////////////////////////////////////////////////////////////
    function mintPass() public payable {
        require(block.timestamp > publicMintStartTime, "mint locked");
        require(_passesMinted + 1 <= maxSupply, "sold out!");

        if (msg.sender != owner()) {
            require(msg.value >= cost, "no funds");
        }

        _passesMinted++;
        _mint(msg.sender, PASS_ID, 1, "");
    }

    function mintAllowlist() public payable {
        require(block.timestamp > allowlistMintStartTime, "mint locked");
        require(allowlist[msg.sender] > 0, "not in allowlist");
        require(_passesMinted < maxSupply, "sold out!");

        allowlist[msg.sender]--;
        _passesMinted++;
        _mint(msg.sender, PASS_ID, 1, "");
    }

    function safeMintPass(address _to, uint256 _amount) public onlyOwner {
        uint256[] memory _ids = new uint256[](1);
        _ids[0] = PASS_ID;
        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = _amount;
        _mintBatch(_to, _ids, _amounts, "");
    }

    /////////////////////////////////////////////////////////////
    // ADMIN
    /////////////////////////////////////////////////////////////
    function withdraw() public onlyOwner {
        require(
            payable(owner()).send(address(this).balance),
            "could not withdraw"
        );
    }

    function setPublicMintStartTime(uint128 _time) public onlyOwner {
        publicMintStartTime = _time;
    }

    function setAllowlistMintTime(uint128 _time) public onlyOwner {
        allowlistMintStartTime = _time;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint128 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    function setPassID(uint256 _id) public onlyOwner {
        PASS_ID = _id;
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function setSymbol(string memory _symbol) public onlyOwner {
        symbol = _symbol;
    }

    function updateAllowlist(
        address[] memory addresses,
        uint256[] memory numMints
    ) public onlyOwner {
        require(
            addresses.length == numMints.length,
            "arrays don't match length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numMints[i];
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
