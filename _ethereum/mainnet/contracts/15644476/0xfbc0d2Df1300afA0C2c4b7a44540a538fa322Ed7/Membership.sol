// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./draft-ERC721VotesUpgradeable.sol";

import "./Counters.sol";
import "./Strings.sol";

import "./Base64.sol";
import "./ToString.sol";
import "./Concat.sol";

contract Membership is Initializable, UUPSUpgradeable, ERC721VotesUpgradeable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ToString for address;
    using Concat for string;
    using Base64 for bytes;

    address payable public dao;
    uint256 public totalSupply;
    uint256 public maxMemberLimit;

    Counters.Counter private _tokenIds;
    mapping(address => bool) public isMember;

    event CreateMember(address to);

    modifier onlyDao() {
        require(msg.sender == dao, "not dao");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(address _dao, string memory _name, uint256 _maxMemberLimit) external initializer
    {
        __EIP712_init(_name.concat(" Membership"), "1");
        __ERC721_init(_name.concat(" Membership"), "MS");
        dao = payable(_dao);
        maxMemberLimit = _maxMemberLimit;
    }

    function createMember(address to) external onlyDao {
        uint256 _totalSupply = totalSupply;
        require(!isMember[to], "Member already created");
        require(_totalSupply < maxMemberLimit, "member count exceed limit");

        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _safeMint(to, newId, "");
        totalSupply = _totalSupply + 1;
        isMember[to] = true;

        emit CreateMember(to);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        string memory metadata = string(abi.encodePacked(
            "{\"name\": \"",
            name(),
            " #",
            tokenId.toString(),
            "\"}"
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            bytes(metadata).base64()
        ));
    }

    function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
    ) internal override {
        if (from != address(0) && to != address(0)) {
		    revert("Membership: Transfer of membership is aboundand");
		}
        super._beforeTokenTransfer(from, to, tokenId); 
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._afterTokenTransfer(from, to, tokenId);
        // check if it is mint and delegatee is not yet delegated

        if (from == address(0) && to != address(0) && delegates(to) == address(0)) {
            _delegate(to, to);
        }
    }

    function _authorizeUpgrade(address) internal view override onlyDao {}

    uint256[50] private __gap;
}
