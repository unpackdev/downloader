// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./AdminManagerUpgradable.sol";
import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./IERC721Upgradeable.sol";

abstract contract SoftStakingUpgradeable is 
    Initializable,
    PausableUpgradeable,
    AdminManagerUpgradable,
    ERC20PresetMinterPauserUpgradeable
{
    IERC721Upgradeable public nft;
    
    mapping(uint256 => uint256) private _timestamps;
    
    uint256 public startTime;
    uint256 public yield;
    uint256 public rate;
    uint256 public cap;

    function __SoftStaking_init(
        IERC721Upgradeable _nft,
        string memory name,
        string memory symbol,
        uint256 _yield,
        uint256 _rate,
        uint256 _startTime,
        uint256 _cap
    ) internal {
        __Pausable_init();
        __AdminManager_init();
        __ERC20PresetMinterPauser_init(name, symbol);

        nft = _nft;
        yield = _yield;
        rate = _rate;
        startTime = _startTime;
        cap = _cap;
    }

    function claim(uint256[] memory ids) external whenNotPaused {
        uint256 amountToMint = _calculateYield(ids);
        require(amountToMint > 0, "No tokens available");
        mint(msg.sender, amountToMint);
    }

    function _valueIfOverflow(uint256 amount) internal view returns (uint256) {
        uint256 supply = totalSupply();
        if(supply == cap) return 0;
        if(supply + amount > cap) return cap - supply;
        return amount;
    }

    function _calculateYield(uint256[] memory ids) internal returns (uint256) {
        uint256 length = ids.length;
        uint256 total;
        for(uint256 i; i < length; i++) {
            uint256 current = ids[i];
            require(nft.ownerOf(current) == msg.sender, "Not Owner");
            total += _getTotal(current);
            _timestamps[current] = block.timestamp;            
        }
        return _valueIfOverflow(total);
    }

    function totalTokens(uint256[] memory ids) public view returns (uint256) {
        uint256 length = ids.length;
        uint256 total;
        for(uint256 i; i < length; i++) {
            uint256 current = ids[i];
            total += _getTotal(current);
        }
        return _valueIfOverflow(total);
    }

    function _getDelta(uint256 id) internal view returns (uint256) {
        uint256 lastTimestamp = _timestamps[id] > 0 ? _timestamps[id] : startTime;
        return block.timestamp - lastTimestamp;
    }

    function _getTotal(uint256 id) virtual internal view returns (uint256) {
        return (_getDelta(id) * yield) / rate;
    }

    function setNFT(IERC721Upgradeable _nft) external onlyAdmin {
        nft = _nft;
    }

    function setRate(uint256 _rate) external onlyAdmin {
        rate = _rate;
    }

    function setYield(uint256 _yield) external onlyAdmin {
        yield = _yield;
    }
}
