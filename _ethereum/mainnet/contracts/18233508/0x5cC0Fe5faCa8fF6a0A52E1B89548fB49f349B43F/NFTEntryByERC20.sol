// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./NFTEntry.sol";
import "./OwnerOperator.sol";
import "./TransferHelper.sol";
import "./IERC20Upgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";

contract NFTEntryByERC20 is
    ERC2771ContextUpgradeable,
    OwnerOperator
{

    function initialize(address payable _nftEntryAddress, address[] memory _trustedForwarder) external initializer {
        nftEntryAddress = _nftEntryAddress;
        OwnerOperator.initialize();
        // Inititalize the context for ERC2771 meta transactions
        __ERC2771Context_init(_trustedForwarder);
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
        bytes memory signature,
        address userAddress
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
            IERC20Upgradeable(tokenAddress).allowance(userAddress, address(this)) >= amountToken,
            'TOKEN ALLOWANCE TOO LOW'
        );

        TransferHelper.safeTransferFrom(tokenAddress, userAddress, address(this), amountToken);
        NFTEntry(nftEntryAddress).userMint(0, amountNftMint, nonce, timestamp, orderId, signature);
        totalUserMintedByERC20 += amountNftMint;
        for(uint256 i = 0 ; i < NFTEntry(nftEntryAddress).getOrder(orderId).length; i++) {
           NFTEntry(nftEntryAddress).safeTransferFrom(address(this), userAddress, NFTEntry(nftEntryAddress).getOrder(orderId)[i]);
        }

        emit UserMintByERC20(userAddress, tokenAddress, amountToken, amountNftMint, orderId, NFTEntry(nftEntryAddress).getOrder(orderId));
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
