// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IResource.sol";
import "./IEnrich.sol";
import "./SafeToken.sol"; 
import "./ISignatureVerifier.sol";

contract Stash is 
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    IERC20Upgradeable public token;
    IEnrich public enrichCapsule;
    IResource public resource;
    ISignatureVerifier public verifier;
    address public treasury;

    mapping (uint256 => uint256) public prices; // enrichId => giá

    event EnrichBought(address account, uint256[] ids, uint256[] amounts, uint256 cost);
    event ImportToLand(address from, uint256 landId, uint256[] resourceIds);
    event EnrichDeposited(address from, uint256 enrichId, uint256 amount);
    event EnrichWithdrew(address from, uint256 enrichId, uint256 amount, bytes32 nonce);
    event ResourceDeposited(address from, uint256 resourceId, uint256 amount);
    event ResourceWithdrew(address from, uint256 resourceId, uint256 amount, bytes32 nonce);
    function initialize(
        address token_,
        address resource_,
        address enrich_,
        address verifier_,
        address treasury_
    ) external initializer {
        __Pausable_init();
        __Ownable_init();
        token = IERC20Upgradeable(token_);
        resource = IResource(resource_); 
        enrichCapsule = IEnrich(enrich_);
        verifier = ISignatureVerifier(verifier_);
        treasury = treasury_;
    }

    function buyEnrich(uint256[] memory ids, uint256[] memory amounts) external nonReentrant whenNotPaused {
        require (ids.length == amounts.length, "invalid");
        uint256 cost;
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] != 0 && ids[i] <= enrichCapsule.maxId() && amounts[i] > 0, "invalid");
            cost += prices[ids[i]] * amounts[i] * 1e18;
        }      
        address account = msg.sender;
        require(token.balanceOf(account) >= cost, "exceed balance");
        token.transferFrom(account, treasury, cost);
        for (uint256 i = 0; i < ids.length; i++) {
            enrichCapsule.mint(account, ids[i], amounts[i], 0);
        }
        emit EnrichBought(account, ids, amounts, cost);
    }

    function depositEnrich(uint256[] memory enrichId, uint256[] memory amount) external nonReentrant whenNotPaused {
        require(enrichId.length == amount.length, "invalid length");
        uint256 maxId = enrichCapsule.maxId();
        address account = msg.sender;
        for (uint256 i = 0; i < enrichId.length; i++) {
            if (
                enrichId[i] != 0 && 
                enrichId[i] <= maxId && 
                amount[i] > 0 &&
                enrichCapsule.balanceOf(account, enrichId[i]) >= amount[i]
            ) {
                enrichCapsule.burn(account, enrichId[i], amount[i]);
                emit EnrichDeposited(account, enrichId[i], amount[i]);
            }
        }
    }

    function withdrawEnrich(
        bytes32 nonce,
        uint256[] memory enrichId, 
        uint256[] memory amount,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        require(enrichId.length == amount.length, "invalid length");
        uint256 maxId = enrichCapsule.maxId();
        address account = msg.sender;
        verifier.verifyWithdrawEnrich(nonce, account, enrichId, amount, signature);
        for (uint256 i = 0; i < enrichId.length; i++) {
            if (
                enrichId[i] != 0 && 
                enrichId[i] <= maxId && 
                amount[i] > 0
            ) {
                enrichCapsule.mint(account, enrichId[i], amount[i], nonce);
                emit EnrichWithdrew(account, enrichId[i], amount[i], nonce);
            }
        }
    }

    function depositResource(uint256[] memory resourceId, uint256[] memory amount) external nonReentrant whenNotPaused {
        require(resourceId.length == amount.length, "invalid length");
        address account = msg.sender;
        for (uint256 i = 0; i < resourceId.length; i++) {
            if (
                resourceId[i] != 0 &&  
                amount[i] > 0 &&
                resource.balanceOf(account, resourceId[i]) >= amount[i]
            ) {
                resource.burn(account, resourceId[i], amount[i]);
                emit ResourceDeposited(account, resourceId[i], amount[i]);
            }
        }
    }

    function withdrawResource(
        bytes32 nonce,
        uint256[] memory resourceId, 
        uint256[] memory amount,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        require(resourceId.length == amount.length, "invalid length");
        address account = msg.sender;
        verifier.verifyWithdrawResource(nonce, account, resourceId, amount, signature);
        for (uint256 i = 0; i < resourceId.length; i++) {
            if (
                resourceId[i] != 0 && 
                amount[i] > 0
            ) {
                resource.mint(account, resourceId[i], amount[i], nonce);
                emit ResourceWithdrew(account, resourceId[i], amount[i], nonce);
            }
        }
    }

    function setPrice(uint256[] memory ids, uint256[] memory prices_) external onlyOwner {
        require(ids.length == prices_.length, "invalid input");
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] != 0 && ids[i] <= enrichCapsule.maxId()) {
                prices[ids[i]] = prices_[i];
            }
        }
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    uint256[47] private __gap;
}