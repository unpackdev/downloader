// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ILandManager.sol";
import "./ILand.sol";
import "./IGame.sol";
import "./SafeToken.sol";
import "./ISignatureVerifier.sol";

contract LandManager is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ILandManager 
{
    using SafeToken for address;
    IERC20Upgradeable public token;
    IERC20Upgradeable public nvs;
    ISignatureVerifier public verifier;
    ILand public land;
    IGame public game;
    address public treasury;
    uint256 public cost;
    uint256 public nvsCost;

    // mapping(address => bool) public isAutoMinted;
    // mapping(address => bool) public operators;
    mapping(uint256 => bool) public isClaimed;
    mapping(address => bool) public isDiscounted;

    // modifier onlyGame() {
    //     require(msg.sender == address(game), "ind");
    //     _;
    // }

    function initialize(
        address token_,
        address nvs_,
        address land_,
        address verifier_,
        address treasury_,
        uint256 cost_,
        uint256 nvsCost_
    ) external initializer {
        __Pausable_init();
        __Ownable_init();
        token = IERC20Upgradeable(token_);
        nvs = IERC20Upgradeable(nvs_);
        verifier = ISignatureVerifier(verifier_);
        land = ILand(land_);
        treasury = treasury_;
        cost = cost_;
        nvsCost = nvsCost_;
    }

    receive() external payable {}

    // function checkAutoMint(address account) public view returns (bool) {
    //     return land.balanceOf(account) == 0 && 
    //         game.getLand(account).length == 0 &&
    //         !isAutoMinted[account];
    // }

    // function autoMint() external nonReentrant whenNotPaused {
    //     require(checkAutoMint(msg.sender), "op");
    //     address account = msg.sender;
    //     land.mintToken(account, false, 0);
    //     isAutoMinted[account] = true;
    //     emit LandMinted(
    //         account,
    //         land.currentId(),
    //         0,
    //         0
    //     );
    // }

    function mintLand(
        uint256 amount
    ) external nonReentrant whenNotPaused {
        address account = msg.sender;
        bool nvsCondition = address(nvs) != address(0) ?
            nvs.balanceOf(account) >= nvsCost * amount : 
            true;
        require(
            token.balanceOf(account) >= cost * amount && 
            nvsCondition &&
            amount > 0, 
            "ind"
        );
        uint256 nvsCost_;
        if (address(nvs) != address(0)) {
            nvs.transferFrom(account, treasury, nvsCost * amount);
            nvsCost_ = nvsCost;
        }
        token.transferFrom(account, treasury, cost * amount);
        uint256 id = land.currentId() + 1;
        land.mintBatchToken(account, amount, account, 0);
        for (uint256 i = 0; i < amount; i++) {           
            emit LandMinted(
                account,
                id + i,
                cost,
                nvsCost_
            );
        }
    }

    function mintAndDeposit(
        bytes32 nonce,
        uint256 amount,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        address account = msg.sender;
        _mintAndDeposit(nonce, account, cost, amount, signature);
    }

    function firstMintAndDeposit(
        bytes32 nonce,
        uint256 asgCost,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        address account = msg.sender;
        require(!isDiscounted[account], "caller not new wallet");
        isDiscounted[account] = true;
        _mintAndDeposit(nonce, account, asgCost, 1, signature);
    }

    function _mintAndDeposit(
        bytes32 nonce,
        address account,
        uint256 asgCost,
        uint256 amount,
        bytes memory signature
    ) internal {
        uint256 totalPrice = amount * asgCost;
        verifier.verifyWithdrawToken(nonce, account, totalPrice, signature);
        uint256[] memory landIds = new uint256[](amount);
        uint256 id = land.currentId() + 1;
        land.mintBatchToken(address(game), amount, account, nonce);
        for (uint256 i = 0; i < amount; i++) {   
            landIds[i] = id + i;        
            emit LandMinted(
                account,
                landIds[i],
                asgCost,
                0
            );
        }
        game.directDeposit(account, landIds);
    }

    function claim(
        bytes32 nonce,
        uint256[] memory nekoId,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        address account = msg.sender;
        verifier.verifyClaimLand(nonce, account, nekoId,signature);
        for (uint256 i = 0; i < nekoId.length; i++) {
            if (!isClaimed[nekoId[i]]) {
                isClaimed[nekoId[i]] = true;
                land.mintToken(account, true, nekoId[i]);
                emit LandMinted(
                    account,
                    land.currentId(),
                    0,
                    0
                );
            }
        }
    }

    function setGame(address game_) external onlyOwner {
        game = IGame(game_);
    }

    function setVerifier(address verifier_) external onlyOwner {
        verifier = ISignatureVerifier(verifier_);
    }

    // function setOperator(address operator_, bool state) external onlyOwner {
    //     operators[operator_] = state;
    // }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function setCost(uint256 cost_, uint256 nvsCost_) external onlyOwner {
        cost = cost_;
        nvsCost = nvsCost_;
    }

    function setNVS(address nvs_) external onlyOwner {
        nvs = IERC20Upgradeable(nvs_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    uint256[46] private __gap;
} 
