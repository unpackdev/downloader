
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ILore.sol";

import "./MimicMeta.sol";
import "./Combo721Base.sol";

abstract contract CoreShield is Combo721Base {
    address aGuild;
    address aMimic;
    MimicMeta cMeta;

    mapping(uint256 => bool) ACTIVE;
    mapping(address => uint256) ACTIVE_BALANCES;

    string internal constant NOT_SHIELD_OWNER = "you do not own this this shield";

    event Activation(uint256 indexed _shieldId, bool _active);

    function init(address _guild, address _mimic, address _meta) external {
        require(aMimic == address(0x0), "already initialized");
        aGuild = _guild;
        aMimic = _mimic;
        cMeta = MimicMeta(_meta);
    }

    function cMimic_Mint(address _recipient, uint256 _mimicId) external {
        require(msg.sender == aMimic, "can't touch this");
        _mint(_recipient, _mimicId);
    }

    function tokenURI(uint256 _shieldId) public view override returns (string memory) {
        require(msg.sender.code.length == 0, "nope");
        require(_exists(_shieldId));
        return cMeta.shieldNative(_shieldId, ACTIVE[_shieldId]);
    }

    ////
    // ACTIVATIONS

    function activeCount(address _owner) external view returns (uint256) {
        return ACTIVE_BALANCES[_owner];
    }

    function shield_Activate(uint256 _shieldId) external {
        require(_isApprovedOrOwner(msg.sender, _shieldId), NOT_SHIELD_OWNER);
        require(!ACTIVE[_shieldId], "Mimic Shield: aura is already active");
        ACTIVE[_shieldId] = true;
        ACTIVE_BALANCES[msg.sender] += 1;
        emit Activation(_shieldId, true);
    }

    function shield_Deactivate(uint256 _shieldId) external {
        require(_isApprovedOrOwner(msg.sender, _shieldId), NOT_SHIELD_OWNER);
        require(ACTIVE[_shieldId], "Mimic Shield: aura is already inactive");
        delete ACTIVE[_shieldId];
        ACTIVE_BALANCES[msg.sender] -= 1;
        emit Activation(_shieldId, false);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        if (ACTIVE[_tokenId]) {
            ACTIVE_BALANCES[_from] -= 1;
            ACTIVE_BALANCES[_to] += 1;
        }
    }

    ////
    // Lore

    function lore() external view returns (string memory) {
        return ILore(aGuild).lore();
    }
}