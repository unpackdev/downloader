// SPDX-License-Identifier: MIT
//
// Made with ❤️ in 🎵
//
pragma solidity 0.8.10;

import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./PublicSale.sol";

contract EpsonMusicSale is ERC1155Holder, PublicSale, ReentrancyGuard {
    using ECDSA for bytes32;

    uint256 public constant MINT_PRICE = 0.1 ether;

    IERC1155 private immutable _music;
    uint256 private immutable _saleTokenId;
    uint256 private immutable _maxMint; // max mint amount per address
    mapping(address => uint256) private _minted; // mint count of each address
    bool private _isPublicSalePhase = false; // start with whitelist sale by default

    event Purchase(address indexed account, uint256 amount);
    event WithdrawETH(address indexed owner, uint256 amount);
    event WithdrawTokens(address indexed owner, uint256 tokenId, uint256 amount);
    event EnabledPublicSalePhase(address indexed owner);
    event DisabledPublicSalePhase(address indexed owner);

    constructor(
        IERC1155 musicContract,
        uint256 tokenIdToSale,
        uint256 maxMintPerAddress
    ) {
        _music = musicContract;
        _saleTokenId = tokenIdToSale;
        _maxMint = maxMintPerAddress;
    }

    /**
     * @dev Purchase with the whitelist signature proof from owner.
     * If the public sale phase is active, can pass any data as a signatureProof.
     */
    function purchase(uint256 amount, bytes memory signatureProof) external payable whenPublicSaleActive nonReentrant {
        // Check
        require(_isPublicSalePhase || isInWhitelist(_msgSender(), signatureProof), 'MusicSale: not in the whitelist');
        require(amount > 0, 'MusicSale: must purchase at least 1');
        require(msg.value == amount * MINT_PRICE, 'MusicSale: incorrect payment amount');
        require(_minted[_msgSender()] + amount <= _maxMint, 'MusicSale: exceed max mint per address');
        require(amount <= tokenBalance(), 'MusicSale: not enough supply');

        // Effect
        _minted[_msgSender()] += amount;

        // Interact
        _music.safeTransferFrom(address(this), _msgSender(), _saleTokenId, amount, '');

        emit Purchase(_msgSender(), amount);
    }

    //
    // 🎵🎵🎵 Admin functions 🎵🎵🎵
    //

    /**
     * @dev Enable Whitelist Phase, allow non-whitelisted addresses to purchase (only owner)
     */
    function enablePublicSalePhase() external onlyOwner {
        _isPublicSalePhase = true;

        emit EnabledPublicSalePhase(_msgSender());
    }

    /**
     * @dev Allow only whitelisted addresses to purchase (only owner)
     */
    function disablePublicSalePhase() external onlyOwner {
        _isPublicSalePhase = false;

        emit DisabledPublicSalePhase(_msgSender());
    }

    /**
     * @dev Withdraw all ETH in this contract (only owner)
     */
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);

        emit WithdrawETH(owner(), balance);
    }

    /**
     * @dev Withdraw all remaining tokens this contract (only owner)
     */
    function withdrawTokens(uint256 tokenId) external onlyOwner {
        uint256 balance = _music.balanceOf(address(this), tokenId);
        _music.safeTransferFrom(address(this), owner(), tokenId, balance, '');

        emit WithdrawTokens(owner(), tokenId, balance);
    }

    //
    // 🎵🎵🎵 View functions 🎵🎵🎵
    //

    /**
     * @dev Check if the account is in whitelist by signature proof from owner
     */
    function isInWhitelist(address account, bytes memory signatureProof) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked('whitelist', address(this), account));
        address signer = messageHash.toEthSignedMessageHash().recover(signatureProof);
        return signer == owner();
    }

    function tokenBalance() public view returns (uint256) {
        return _music.balanceOf(address(this), _saleTokenId);
    }

    function mintedAmount(address account) public view returns (uint256) {
        return _minted[account];
    }

    function maxMint() public view returns (uint256) {
        return _maxMint;
    }

    function music() public view returns (IERC1155) {
        return _music;
    }

    function saleTokenId() public view returns (uint256) {
        return _saleTokenId;
    }

    function isPublicSalePhase() public view returns (bool) {
        return _isPublicSalePhase;
    }
}
