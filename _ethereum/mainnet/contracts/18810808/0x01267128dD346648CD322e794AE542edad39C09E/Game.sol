// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IGame.sol";
import "./ILand.sol";
import "./SafeToken.sol";
import "./ISignatureVerifier.sol";

contract Game is
    ERC721HolderUpgradeable, 
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable, 
    IGame
{
    using SafeToken for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    IERC20Upgradeable public token;
    ISignatureVerifier public verifier;
    ILand public land;
    address public treasury;
    
    mapping (address => EnumerableSetUpgradeable.UintSet) private lands;
    mapping (uint256 => address) public ownerOfLandByIds;
    address public manager;

    function initialize(
        address token_,
        address verifier_,
        address land_,
        address treasury_
    ) external initializer {
        __Pausable_init();
        __Ownable_init();
        __ERC721Holder_init();
        token = IERC20Upgradeable(token_);
        verifier = ISignatureVerifier(verifier_);
        land = ILand(land_);
        treasury = treasury_;
    }

    function depositLand(uint256[] calldata landIds) external nonReentrant whenNotPaused {
        address account = msg.sender;
        for (uint8 i = 0; i < landIds.length; i++) {
            require(land.ownerOf(landIds[i]) == msg.sender, "o");
            lands[account].add(landIds[i]);
            ownerOfLandByIds[landIds[i]] = account;
            land.safeTransferFrom(account, address(this), landIds[i]);
        }       
        emit LandDeposited(account, landIds);
    }

    function directDeposit(address account, uint256[] memory landIds) external override {
        require(msg.sender == manager, "caller is not manager");
        for (uint8 i = 0; i < landIds.length; i++) {
            lands[account].add(landIds[i]);
            ownerOfLandByIds[landIds[i]] = account;
        }
        emit LandDeposited(account, landIds);
    }

    function getLand(address account) external override view returns (uint256[] memory) {
        return lands[account].values(); 
    }
 
    function withdrawTokenFromLand(
        bytes32 nonce,
        uint256 landId,
        uint256 amount,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        require(amount > 0, "i");
        address account = msg.sender;
        verifier.verifyWithdrawTokenFromLand(nonce, account, landId, amount, signature);
        SafeToken.safeTransfer(address(token), account, amount);
        emit TokenWithdrewFromLand(account, landId, amount, nonce);
    }

    function withdrawLand(uint256[] memory landIds) external nonReentrant whenNotPaused {
        address account = msg.sender;
        for (uint8 i = 0; i < landIds.length; i++) {
            require(ownerOfLand(msg.sender, landIds[i]), "o");       
            lands[account].remove(landIds[i]);
            land.safeTransferFrom(address(this), account, landIds[i]);
            delete ownerOfLandByIds[landIds[i]];
        }       
        emit LandWithdrew(account, landIds);
    }

    function depositToken(uint256 amount) external nonReentrant whenNotPaused {
        address account = msg.sender;
        require(amount > 0 && token.balanceOf(account) >= amount);
        token.transferFrom(account, treasury, amount);
        emit TokenDeposited(account, amount);
    }

    function withdrawToken(
        bytes32 nonce,
        uint256 amount,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        require(amount > 0, "i");
        address account = msg.sender;
        verifier.verifyWithdrawToken(nonce, account, amount, signature);
        SafeToken.safeTransfer(address(token), account, amount);
        emit TokenWithdrew(account, amount, nonce);
    }

    function ownerOfLand(address account, uint256 landId) public override view returns (bool) {
        return landId != 0 && lands[account].contains(landId);
    }

    function setManager(address manager_) external onlyOwner {
        manager = manager_;
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

    function withdrawEmergency(address token_, address to, uint256 value) external onlyOwner {
        SafeToken.safeTransfer(token_, to, value);
    }

    uint256[46] private __gap;
}