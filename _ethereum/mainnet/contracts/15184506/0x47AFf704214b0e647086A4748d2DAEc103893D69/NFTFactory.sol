// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./AccessControl.sol";
import "./ERC721.sol";
import "./NFTArt.sol";

contract NFTFactory is AccessControl {
    uint256 public factoryFee = 0.001 ether;
    bytes32 public constant WORKER_ROLE = keccak256("WORKER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address[] private createdContracts;

    event NewToken(
        uint256 indexed id,
        address indexed tokenAddress,
        address indexed owner
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WORKER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function updateFee(uint256 _newFee) public onlyRole(ADMIN_ROLE) {
        factoryFee = _newFee;
    }

    function publicFactory(
        string memory _name,
        string memory _symbol,
        string memory _contracturi
    ) public payable returns (address) {
        require(msg.value == factoryFee, "Invalid Fee");
        address _newToken = _factory(_name, _symbol, _contracturi, msg.sender);
        createdContracts.push(_newToken);
        emit NewToken(createdContracts.length, _newToken, msg.sender);
        return _newToken;
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        string memory _contracturi,
        address owner
    ) public onlyRole(WORKER_ROLE) returns (address) {
        address _newToken = _factory(_name, _symbol, _contracturi, owner);
        createdContracts.push(_newToken);
        emit NewToken(createdContracts.length, _newToken, owner);
        return _newToken;
    }

    function _factory(
        string memory _name,
        string memory _symbol,
        string memory _contracturi,
        address owner
    ) private returns (address) {
        NFTArt newtoken = new NFTArt(_name, _symbol, _contracturi, owner);
        address tokenAddress = address(newtoken);
        return tokenAddress;
    }

    function allTokens() public view returns (address[] memory tokens) {
        return createdContracts;
    }

    function withdraw() public onlyRole(ADMIN_ROLE) {
        require(payable(msg.sender).send(address(this).balance));
    }
}
