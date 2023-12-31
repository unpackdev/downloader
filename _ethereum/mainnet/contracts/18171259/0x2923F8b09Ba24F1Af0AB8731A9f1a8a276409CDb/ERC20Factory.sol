// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ERC20Contract.sol";

contract ERC20Factory is Ownable {

    mapping(address => bool) public allowlist;
    mapping(uint256 => address) public deployments;
    ERC20Contract[] private tokens;
    address public devAddress;
    uint16 public devShare;
    uint256 public nextId = 1;

    constructor(address _devAddress, uint16 _devShare) {
        devShare = _devShare;
        devAddress = _devAddress;
    }

    function updateConfig(address _devAddress, uint16 _devShare) external onlyOwner {
        devShare = _devShare;
        devAddress = _devAddress;
    }

    function updateAllowlist(address _address, bool _add) external onlyOwner {
        allowlist[_address] = _add;
    }

    function getDeployedTokens() external view returns (ERC20Contract[] memory) {
        return tokens;
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        ERC20Contract.Fees memory _fees,
        uint256 _maxSupply,
        address[] memory _payees,
        uint16[] memory _shares
    ) external {
        require(allowlist[msg.sender],  "Not allowlisted");
        require(_maxSupply > 0,  "Bad supply");
        ERC20Contract token = new ERC20Contract(
            _name,
            _symbol,
            _fees,
            _maxSupply,
            devShare,
            devAddress,
            _payees,
            _shares,
            msg.sender
        );
        deployments[nextId++] = address(token);
        tokens.push(token);
    }
}