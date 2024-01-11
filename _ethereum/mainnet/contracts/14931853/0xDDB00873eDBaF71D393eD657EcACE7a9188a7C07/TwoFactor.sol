// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";


contract TwoFactor is Ownable, ERC721Holder, ERC1155Holder {
    
    using SafeERC20 for IERC20;

    bytes32 private encryptedPassword;
    bool private isInitialized;
    address private backupWallet;
  
    function init(address _sender, address _backupWallet, bytes32 _encryptedPassword) external encryptedPasswordNotNull(_encryptedPassword){        
        require(_sender!= address(0), "Sender address can not be zero");
        require(_backupWallet!= address(0), "Backup address can not be zero");
        require(_backupWallet!= _sender, "Backup wallet can not be same as sender wallet");
        require(isInitialized == false, "Contract already initialized");
        encryptedPassword = _encryptedPassword;
        _transferOwnership(_sender);
        backupWallet = _backupWallet;
        isInitialized = true;
    }
    
    receive() external payable {        
    }

    function transferERC20AssetsToWallet(
        bytes memory _oldPassword,
        bytes32 _newEncryptedPassword,
        address[] memory erc20tokenAddressList
    )
        external
        onlyOwner
        passwordMatchAndNewUpdated(_oldPassword, _newEncryptedPassword)
        encryptedPasswordNotNull(_newEncryptedPassword)
    {
        encryptedPassword = _newEncryptedPassword;
        _transferERC20FundsToAddress(owner(), erc20tokenAddressList);
    }

    function transferERC721AssetsToWallet(
        bytes memory _oldPassword,
        bytes32 _newEncryptedPassword,
        address tokenAddress,
        uint256 tokenId
    )
        external
        onlyOwner
        passwordMatchAndNewUpdated(_oldPassword, _newEncryptedPassword)
        encryptedPasswordNotNull(_newEncryptedPassword)
     {
        encryptedPassword = _newEncryptedPassword;
        _transferERC721FundsToAddress(owner(), tokenAddress, tokenId);
    }

    function transferERC1155AssetsToWallet(
        bytes memory _oldPassword,
        bytes32 _newEncryptedPassword,
        address tokenAddress,
        uint256 tokenId
    )
        external
        onlyOwner
        passwordMatchAndNewUpdated(_oldPassword, _newEncryptedPassword)
        encryptedPasswordNotNull(_newEncryptedPassword)
    {
        encryptedPassword = _newEncryptedPassword;
        _transferERC1155FundsToAddress(owner(), tokenAddress, tokenId);
    }

    function transferNativeAssetToWallet(
        bytes memory _oldPassword,
        bytes32 _newEncryptedPassword
    )
        external
        onlyOwner
        passwordMatchAndNewUpdated(_oldPassword, _newEncryptedPassword)
        encryptedPasswordNotNull(_newEncryptedPassword)
    {
        encryptedPassword = _newEncryptedPassword;
        _transferNativeFundsToAddress(payable(owner()));
    }

    //put old raw password and new hashed password
    function updatePassword(
        bytes memory _oldPassword,
        bytes32 _newEncryptedPassword
    )
        external
        onlyOwner
        passwordMatchAndNewUpdated(_oldPassword, _newEncryptedPassword)
        encryptedPasswordNotNull(_newEncryptedPassword)
    {
        encryptedPassword = _newEncryptedPassword;
    }

    modifier passwordMatchAndNewUpdated(
        bytes memory _oldPassword,
        bytes32 _newEncryptedPassword
    ) {
        bytes32 _passwordSent = keccak256(abi.encodePacked(_oldPassword));
        require(
            _passwordSent != _newEncryptedPassword,
            "New password should be different"
        );
        require(_passwordSent == encryptedPassword, "Passwords don't match");
        _;
    }

    modifier encryptedPasswordNotNull(bytes32 _encryptedPassword)
    {
        require(_encryptedPassword != keccak256(abi.encodePacked('')), "Password can not be null");
        _;

    }


    //WHEN WALLET KEYS GET COMPROMISED OR 2FA PASSWORD IS LOST, WE RECOMMEND TO SEND YOUR ASSETS TO RECOVERY WALLET (OR COLD WALLET)

    function sendERC20FundsToBackupWallet(
        address[] memory erc20tokenAddressList
    ) external onlyOwner {
        _transferERC20FundsToAddress(backupWallet, erc20tokenAddressList);
    }

    function sendERC721FundsToBackupWallet(
        address tokenAddress,
        uint256 tokenId
    ) external onlyOwner {
        _transferERC721FundsToAddress(backupWallet, tokenAddress, tokenId);
    }

    function sendERC1155FundsToBackupWallet(
        address tokenAddress,
        uint256 tokenId
    ) external onlyOwner {
        _transferERC1155FundsToAddress(backupWallet, tokenAddress, tokenId);
    }

    function sendNativeFundsToBackupWallet() external onlyOwner {
        _transferNativeFundsToAddress(payable(backupWallet));
    }

    function _transferERC721FundsToAddress(
        address toAddress,
        address tokenAddress,
        uint256 tokenId
    ) private {
        IERC721(tokenAddress).safeTransferFrom(address(this), toAddress, tokenId);
    }

    function _transferERC1155FundsToAddress(
        address toAddress,
        address tokenAddress,
        uint256 tokenId
    ) private {
        uint256 balance = IERC1155(tokenAddress).balanceOf(
            address(this),
            tokenId
        );
        if (balance > 0) {
            IERC1155(tokenAddress).safeTransferFrom(
                address(this),
                toAddress,
                tokenId,
                balance,
                ""
            );
        }
    }

    function _transferERC20FundsToAddress(
        address toAddress,
        address[] memory tokenAddressList
    ) private {
        require(tokenAddressList.length != 0, "Assets list cannot be empty");
        for (uint256 i = 0; i < tokenAddressList.length; i++) {
            uint256 balance = IERC20(tokenAddressList[i]).balanceOf(
                address(this)
            );
            if (balance > 0) {
                IERC20(tokenAddressList[i]).safeTransfer(toAddress, balance);
            }
        }
    }

    function _transferNativeFundsToAddress(address payable toAddress) private {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            toAddress.transfer(balance);
        }
    }
}
