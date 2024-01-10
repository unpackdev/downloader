//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Clones.sol";
import "./Flashmint.sol";

contract FlashmintVaultFactory is Ownable, Pausable {
    uint256 public vaultCount;
    mapping (uint256 => address) public vaults;
    address public immutable logic;
    address public immutable settings;

    constructor(address _settings) {
        logic = address(new Flashmint(_settings));
        settings = _settings;
    }

    event Vault(address indexed token, uint256 id, uint256 fee, address vault, uint256 vaultId);

    function makeFlashmint(address _token, uint256 _id, uint256 _fee) external whenNotPaused returns (uint256) {
        Flashmint flashmint = Flashmint(payable(Clones.clone(logic)));
        flashmint.initializeWithNFT(_token, _id, msg.sender, _fee);
        
        IERC721(_token).safeTransferFrom(msg.sender, address(flashmint), _id);
        
        emit Vault(_token, _id, _fee, address(flashmint), vaultCount);
        
        vaults[vaultCount++] = address(flashmint);
        return vaultCount - 1;
    }

    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }
}