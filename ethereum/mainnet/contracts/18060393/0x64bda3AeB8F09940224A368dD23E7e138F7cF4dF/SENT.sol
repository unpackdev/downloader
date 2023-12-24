// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract Sentience is ERC20, Ownable {
    mapping(address => bool) public whitelist;
    event WhiteListUpdated(address indexed _address, bool _isWhitelisted);

    bool public mintingEnabled = true;
    event MintingDisabled();

    bool public transferEnabled = true;
    event TransferEnabled();

    constructor() ERC20("Sentience Points", "SENT") {
        _mint(msg.sender, 42690143500000000000000000);
        whitelist[msg.sender] = true;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender] || transferEnabled, "Sender is not whitelisted and trasfers are disabled");
        _;
    }

    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
        emit WhiteListUpdated(_address, true);
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
        emit WhiteListUpdated(_address, false);
    }

    function disableMinting() external onlyOwner {
        mintingEnabled = false;
        emit MintingDisabled();
    }

    function enableTransfers() external onlyOwner {
        transferEnabled = true;
        emit TransferEnabled();
    }

    function mint(uint256 amount) external onlyOwner {
        require(mintingEnabled, "Minting is disabled");
        _mint(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount) public override onlyWhitelisted returns (bool) {
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override onlyWhitelisted returns (bool) {
        super.transferFrom(sender, recipient, amount);
        return true;
    }
}