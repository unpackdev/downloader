// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;
pragma abicoder v2;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./AccessControl.sol";
import "./ERC2771Context.sol";


contract DastraLaunchpad is ERC2771Context, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    using ECDSA for bytes32;

    bytes32 public constant SIGNER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct PlacedToken {
        address owner;
        uint256 price;
        uint256 initialVolume;
        uint256 volume;
        uint256 collectedAmount; // in _pricingToken
        bool isActive;
    }

    mapping (uint256 => bool) public nonces;
    mapping (IERC20Metadata => PlacedToken) public placedTokens;


    uint256 internal _feePercent;
    IERC20Metadata private _pricingToken;
    address private _feeCollector;

    event TokenPlaced(IERC20Metadata token, uint256 nonce);
    event RoundFinished(IERC20Metadata token);
    event TokensBought(IERC20Metadata token, address buyer, uint256 amount);
    event FundsCollected(IERC20Metadata token);

    constructor(address pricingToken_, uint256 feePercent_, address feeCollector_, address trustedForwarder) ERC2771Context(trustedForwarder) {
        _feePercent = feePercent_;
        _pricingToken = IERC20Metadata(pricingToken_);
        _feeCollector = feeCollector_;
        _setRoleAdmin(SIGNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(SIGNER_ROLE, msg.sender);
    }

    function feeCollector() public view returns(address) {
        return _feeCollector;
    }

    function setFeeCollector(address feeCollector_) public onlyRole(ADMIN_ROLE) {
        _feeCollector = feeCollector_;
    }

    function feePercent() public view returns(uint256) {
        return _feePercent;
    }

    function setFeePercent(uint256 feePercent_) public onlyRole(ADMIN_ROLE) {
        _feePercent = feePercent_;
    }

    function pricingToken() public view returns(IERC20Metadata) {
        return _pricingToken;
    }

    function setPricingToken(IERC20Metadata pricingToken_) public onlyRole(ADMIN_ROLE) {
        _pricingToken = pricingToken_;
    }

    function placeTokens(uint256 nonce, uint256 price, IERC20Metadata token, uint256 initialVolume, bytes memory signature) public {
        address sender = _msgSender();

        require(!nonces[nonce], "Launchpad: Invalid nonce");
        require(!placedTokens[token].isActive, "Launchpad: This token was already placed");
        require(initialVolume > 0, "Launchpad: initial Volume must be >0");

        address signer = keccak256(abi.encodePacked(sender, address(token), initialVolume, price, nonce))
        .toEthSignedMessageHash().recover(signature);

        require(hasRole(SIGNER_ROLE, signer), "Launchpad: Invalid signature");
        
        token.safeTransferFrom(sender, address(this), initialVolume);

        placedTokens[token] = PlacedToken ({
                                            owner: sender,
                                            price: price,
                                            initialVolume: initialVolume,
                                            volume: initialVolume,
                                            collectedAmount: 0,
                                            isActive: true
                                        });
        
        nonces[nonce] = true;

        emit TokenPlaced(token, nonce);
    }

    function _sendCollectedFunds(address sender, IERC20Metadata token) private {
        PlacedToken storage placedToken = placedTokens[token];
        require (sender == placedToken.owner, "Launchpad: You are not the owner of this token");

        _pricingToken.safeTransfer(placedToken.owner, placedToken.collectedAmount);
        placedToken.collectedAmount = 0;

        emit FundsCollected(token);
    }

    function getCollectedFunds(IERC20Metadata token) public nonReentrant{
        _sendCollectedFunds(_msgSender(), token);
    }

    function finishRound(IERC20Metadata token) public nonReentrant {
        address sender = _msgSender();
        PlacedToken storage placedToken = placedTokens[token];

        require(sender == placedToken.owner, "Launchpad: You are not the owner of this token");

        _sendCollectedFunds(sender, token);
        
        token.safeTransfer(sender, placedToken.volume);
        delete placedTokens[token];

        emit RoundFinished(token);
    }

    function _buyTokens(IERC20Metadata token, uint256 volume, address payer, address receiver) internal {
        PlacedToken storage placedToken = placedTokens[token];
        require(placedToken.isActive == true, "Dastra: Round isn't active");

        _pricingToken.safeTransferFrom(payer, address(this), volume);

        uint256 tokensAmount = volume * (10 ** token.decimals()) / placedToken.price;
        require(tokensAmount <= placedToken.volume, "Dastra: Not enough volume");

        token.safeTransfer(receiver, tokensAmount);

        uint256 fee = volume * _feePercent / 100;
        placedToken.collectedAmount += volume - fee;
        placedToken.volume -= tokensAmount;
        _pricingToken.safeTransfer(_feeCollector, fee);

        emit TokensBought(token, receiver, tokensAmount);
    }

    function buyTokens(IERC20Metadata token, uint256 value) public nonReentrant {
        _buyTokens(token, value, _msgSender(), _msgSender());
        
    }

    function buyTokensFor(IERC20Metadata token, uint256 value, address receiver) public nonReentrant {
        _buyTokens(token, value, _msgSender(), receiver);
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}