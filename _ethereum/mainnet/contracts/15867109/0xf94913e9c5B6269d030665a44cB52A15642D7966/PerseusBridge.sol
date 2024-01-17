// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ECDSA.sol";
import "./IPerseusBridge.sol";

contract PerseusBridge is Initializable, OwnableUpgradeable, IPerseusBridge {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSA for bytes32;

    address public adminAddress;
    address public signerAddress;
    IERC20 public token;

    mapping(string => bool) public claims;
    mapping(string => bool) public nftClaims;

    IPerseusNFT public nft;

    /**
     * @notice Triggered when admin address has been changed
     *
     * @param oldAdminAddress       Old admin address
     * @param newAdminAddress       New admin address
     */
    event AdminUpdated(address oldAdminAddress, address newAdminAddress);

    /**
     * @notice Triggered when signer address has been changed
     *
     * @param oldSignerAddress       Old signer address
     * @param newSignerAddress       New signer address
     */
    event SignerUpdated(address oldSignerAddress, address newSignerAddress);

    /**
     * @notice Triggered when token has been changed
     *
     * @param oldToken               Old token address
     * @param newToken               New token address
     */
    event TokenUpdated(address oldToken, address newToken);

    /**
     * @notice Triggered when a claim has been maid
     *
     * @param receiver               Address of the receiver
     * @param solanaTxId             the transaction id from solana network; used for deduplication
     * @param amount                 the amount to be claimed
     */
    event Claimed(address indexed receiver, string solanaTxId, uint256 amount);

    /**
     * @notice Triggered when a claim has been maid my an admin
     *
     * @param admin                  Address of the admin or owner
     * @param receiver               Address of the receiver
     * @param solanaTxId             the transaction id from solana network; used for deduplication
     * @param amount                 the amount to be claimed
     */
    event AdminClaimed(address indexed admin, address indexed receiver, string solanaTxId, uint256 amount);


    /**
     * @notice Triggered when nft has been changed
     *
     * @param oldNft               Old nft contract address
     * @param newNft               New nft contract address
     */
    event NftUpdated(address oldNft, address newNft);

    /**
     * @notice Triggered when a nft claim has been maid
     *
     * @param receiver               Address of the receiver
     * @param solanaTxId             the transaction id from solana network; used for deduplication
     * @param silverAmount           number of silver card tokens to be minted
     * @param goldAmount             number of gold card tokens to be minted
     * @param platinumAmount         number of platinum card tokens to be minted
     * @param blackAmount            number of black card tokens to be minted
     */
    event NftClaimed(
        address indexed receiver,
        string solanaTxId,
        uint256 silverAmount,
        uint256 goldAmount,
        uint256 platinumAmount,
        uint256 blackAmount
    );

    /**
     * @notice Triggered when a nft claim has been maid by an  admin
     *
     * @param admin                  Address of the admin or owner
     * @param receiver               Address of the receiver
     * @param solanaTxId             the transaction id from solana network; used for deduplication
     * @param silverAmount           number of silver card tokens to be minted
     * @param goldAmount             number of gold card tokens to be minted
     * @param platinumAmount         number of platinum card tokens to be minted
     * @param blackAmount            number of black card tokens to be minted
     */
    event AdminNftClaimed(
        address indexed admin,
        address indexed receiver,
        string solanaTxId,
        uint256 silverAmount,
        uint256 goldAmount,
        uint256 platinumAmount,
        uint256 blackAmount
    );

    /**
     * @notice Enforces sender to be the owner or admin
     */
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == adminAddress, "Caller is not admin");
        _;
    }

    /**
     * @notice Enforces solanaTxId to not be already claimed for an erc20 claim
     */
    modifier notAlreadyClaimed(string calldata _solanaTxId) {
        require(!claims[_solanaTxId], "Already claimed");
        _;
    }

    /**
     * @notice Enforces solanaTxId to not be already claimed for a nftClaim
     */
    modifier notAlreadyNftClaimed(string calldata _solanaTxId) {
        require(!nftClaims[_solanaTxId], "Already nftClaimed");
        _;
    }

    /**
    * @notice instantiates contract
    *
    * @param _token                 the address of the token to be distributed
    * @param _ownerAddress          the address of the owner of the contract
    * @param _ownerAddress          the address of the admin
    * @param _signerAddress         the address of the wallet that signs messages
    */
    function initialize(
        IERC20 _token,
        address _ownerAddress,
        address _adminAddress,
        address _signerAddress
    ) external initializer {
        __Ownable_init();

        adminAddress = _adminAddress;
        signerAddress = _signerAddress;
        token = _token;

        transferOwnership(_ownerAddress);
    }

    /**
     * @notice Updates the signer address
     *
     * @param _newSignerAddress      the address of the new signer
     */
    function updateSigner(address _newSignerAddress) external onlyOwner override {
        emit SignerUpdated(signerAddress, _newSignerAddress);
        signerAddress = _newSignerAddress;
    }

    /**
     * @notice Updates the admin address
     *
     * @param _newAdminAddress      the address of the new admin
     */
    function updateAdmin(address _newAdminAddress) external onlyOwner override {
        emit AdminUpdated(adminAddress, _newAdminAddress);
        adminAddress = _newAdminAddress;
    }

    /**
     * @notice Updates the token
     *
     * @param _newToken      the address of the new token contract
     */
    function updateToken(IERC20 _newToken) external onlyOwner override {
        emit TokenUpdated(address(token), address(_newToken));
        token = _newToken;
    }

    /**
     * @notice Updates the address of the NFT contract
     *
     * @param _newNft      the address of the new NFT contract
     */
    function updateNft(IPerseusNFT _newNft) external onlyOwner override {
        emit NftUpdated(address(nft), address(_newNft));
        nft = _newNft;
    }

    /**
     * @notice Claims tokens based on a signature generated by the signer
     *
     * @param _solanaTxId        the transaction id from solana network; used for deduplication
     * @param _amount            the amount to be claimed
     * @param _signature         the off-chain signature to verify correctness of the pair (msg.signer, _solanaTxId, _amount)
     */
    function claim(
        string calldata _solanaTxId,
        uint256 _amount,
        bytes calldata _signature
    ) external override notAlreadyClaimed(_solanaTxId) {
        _claim(msg.sender, _solanaTxId, _amount, _signature);

        emit Claimed(msg.sender, _solanaTxId, _amount);
    }

    /**
     * @notice Admin method to send token to an user
     *
     * @param _receiverAddress   the address of the receiver
     * @param _solanaTxId        the transaction id from solana network; used for deduplication
     * @param _amount            the amount to be claimed
     */
    function adminClaim(
        address _receiverAddress,
        string calldata _solanaTxId,
        uint256 _amount
    ) external override onlyOwnerOrAdmin notAlreadyClaimed(_solanaTxId) {

        claims[_solanaTxId] = true;
        token.safeTransfer(_receiverAddress, _amount);

        emit AdminClaimed(msg.sender, _receiverAddress, _solanaTxId, _amount);
    }

    /**
     * @notice Withdraws funds - only by owner
     *
     * @param _amount            the amount to be withdrawal
     */
    function withdraw(uint256 _amount) external override onlyOwner {
        token.safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Mints NFTs based on a signature generated by the signer
     *
     * @param _solanaTxId        the transaction id from solana network; used for deduplication
     * @param _silverAmount      number of silver card tokens to be minted
     * @param _goldAmount        number of gold card tokens to be minted
     * @param _platinumAmount    number of platinum card tokens to be minted
     * @param _blackAmount       number of black card tokens to be minted
     * @param _signature         the off-chain signature to verify correctness of the pair (msg.signer, _solanaTxId, _amount)
     */
    function nftClaim(
        string calldata _solanaTxId,
        uint256 _silverAmount,
        uint256 _goldAmount,
        uint256 _platinumAmount,
        uint256 _blackAmount,
        bytes calldata _signature
    ) external override notAlreadyNftClaimed(_solanaTxId) {
        bytes32 _messageHash = keccak256(
            abi.encodePacked(
                msg.sender,
                _solanaTxId,
                _silverAmount,
                _goldAmount,
                _platinumAmount,
                _blackAmount
            ));

        require(
            signerAddress == _messageHash.toEthSignedMessageHash().recover(_signature),
            "Invalid signature"
        );

        nftClaims[_solanaTxId] = true;

        nft.mint(
            msg.sender,
            _silverAmount,
            _goldAmount,
            _platinumAmount,
            _blackAmount
        );

        emit NftClaimed(
            msg.sender,
            _solanaTxId,
            _silverAmount,
            _goldAmount,
            _platinumAmount,
            _blackAmount
        );
    }

    /**
     * @notice Amint function to mint NFTs for an user
     *
     * @param _receiverAddress   the address of the receiver
     * @param _solanaTxId        the transaction id from solana network; used for deduplication
     * @param _silverAmount      number of silver card tokens to be minted
     * @param _goldAmount        number of gold card tokens to be minted
     * @param _platinumAmount    number of platinum card tokens to be minted
     * @param _blackAmount       number of black card tokens to be minted
     */
    function adminNftClaim(
        address _receiverAddress,
        string calldata _solanaTxId,
        uint256 _silverAmount,
        uint256 _goldAmount,
        uint256 _platinumAmount,
        uint256 _blackAmount
    ) external override onlyOwnerOrAdmin notAlreadyNftClaimed(_solanaTxId) {
        nftClaims[_solanaTxId] = true;

        nft.mint(
            _receiverAddress,
            _silverAmount,
            _goldAmount,
            _platinumAmount,
            _blackAmount
        );

        emit AdminNftClaimed(
            msg.sender,
            _receiverAddress,
            _solanaTxId,
            _silverAmount,
            _goldAmount,
            _platinumAmount,
            _blackAmount
        );
    }

    function _claim(address _receiverAddress, string calldata _solanaTxId, uint256 _amount, bytes calldata _signature) internal {
        bytes32 _messageHash = keccak256(abi.encodePacked(_receiverAddress, _solanaTxId, _amount));
        require(
            signerAddress == _messageHash.toEthSignedMessageHash().recover(_signature),
            "Invalid signature"
        );

        claims[_solanaTxId] = true;
        token.safeTransfer(_receiverAddress, _amount);
    }
}
