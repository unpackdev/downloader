// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./NFTEntry.sol";
import "./OwnerOperator.sol";
import "./TransferHelper.sol";
import "./IERC20Upgradeable.sol";

contract NFTEntryByERC20 is
    Initializable,
    OwnerOperator
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address payable _nftEntryAddress) external initializer {
        nftEntryAddress = _nftEntryAddress;
        OwnerOperator.initialize();
    }

    receive() external payable {}

    address payable public nftEntryAddress;

    uint256 public totalUserMintedByERC20;

    mapping(address => bool) public whitelistERC20;

    event UserMintByERC20(
        address caller,
        address tokenAddress,
        uint256 amountToken,
        uint256 amountNftMint,
        uint256 orderId,
        uint256[] tokenId
    );

    event WithdrawERC20Token(
        address caller, 
        IERC20Upgradeable tokenAddress, 
        uint256 amount
    );

    function setNFTEntryAddress(address payable _nftEntryAddress) public operatorOrOwner {
        require(_nftEntryAddress != address(0), 'INVALID NFT ENTRY ADDRESS.');
        nftEntryAddress = _nftEntryAddress;
    }

    function userMintByERC20(
        address tokenAddress,
        uint256 amountToken,
        uint256 amountNftMint,
        uint256 nonce,
        uint256 timestamp,
        uint256 orderId,
        bytes memory signature
    ) public {
        require(
            whitelistERC20[tokenAddress] == true,
            "TOKEN IS NOT IN WHITELIST"
        );
        require(
            amountNftMint > 0, 
            'AMOUNT MUST BE GREATER THAN 0'
        );
        require(
            NFTEntry(nftEntryAddress).balanceOf(nftEntryAddress) >= amountNftMint, 
            'AMOUNT IS MORE THAN POOL'
        );
        require(
            IERC20Upgradeable(tokenAddress).allowance(msg.sender, address(this)) >= amountToken,
            'TOKEN ALLOWANCE TOO LOW'
        );

        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), amountToken);
        NFTEntry(nftEntryAddress).userMint(0, amountNftMint, nonce, timestamp, orderId, signature);
        totalUserMintedByERC20 += amountNftMint;
        for(uint256 i = 0 ; i < NFTEntry(nftEntryAddress).getOrder(orderId).length; i++) {
           NFTEntry(nftEntryAddress).safeTransferFrom(address(this), msg.sender, NFTEntry(nftEntryAddress).getOrder(orderId)[i]);
        }

        emit UserMintByERC20(msg.sender, tokenAddress, amountToken, amountNftMint, orderId, NFTEntry(nftEntryAddress).getOrder(orderId));
    }

    function withdrawERC20Token(IERC20Upgradeable token, uint256 amount) public operatorOrOwner {
        require(amount > 0, 'AMOUNT MUST BE GREATER THAN 0');
        require(amount <= token.balanceOf(address(this)), 'INSUFFICIENT FUNDS');
        TransferHelper.safeTransfer(address(token), msg.sender, amount);
        emit WithdrawERC20Token(msg.sender, token, amount);
    }

    function setWhitelistAddress(address _address, bool approved) public operatorOrOwner {
        whitelistERC20[_address] = approved;
    }

}
