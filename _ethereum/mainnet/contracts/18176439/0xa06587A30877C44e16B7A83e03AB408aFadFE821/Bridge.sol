// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";

import "./IWrappedERC20.sol";
import "./IWrappedERC721.sol";
import "./IWrappedERC1155.sol";

import "./EIP712Utils.sol";

/// @title A bridge contract
contract Bridge is
    EIP712Utils,
    IERC721Receiver,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{

    using SafeERC20Upgradeable for IWrappedERC20;

    // @dev Padding 100 words of storage for upgradeability. Follows OZ's guidance.
    uint256[100] private __gap;
    /// @dev Names of supported chains
    mapping(string => bool) public supportedChains;
    /// @dev Monitor fees for ERC20 tokens
    /// @dev Map from token address to fees
    mapping(address => uint256) public tokenFees;
    /// @dev Monitor nonces. Prevent replay attacks
    mapping(uint256 => bool) public nonces;

    bytes32 public constant BOT_MESSENGER_ROLE = keccak256("BOT_MESSENGER_ROLE");
    address public botMessenger;
    address public stablecoin;
    address public stargateToken;
    /// @dev Last verified nonce
    uint256 public lastNonce;

    /// @notice The chain bringe was deployed to
    string public chain; // Shouldn't change after initialization

    //========== Fees ==========

    uint256 private constant PERCENT_DENOMINATOR = 100_000;

    uint256 private constant MIN_ERC20_ST_FEE_USD = 750;//$0.0075
    uint256 private constant MAX_ERC20_ST_FEE_USD = 15000;//$0.15
    uint256 private constant MIN_ERC20_TT_FEE_USD = 1000;//$0.01
    uint256 private constant MAX_ERC20_TT_FEE_USD = 20000;//$0.2
    uint256 private constant ERC20_ST_FEE_RATE = 225;//0.225%
    uint256 private constant ERC20_TT_FEE_RATE = 300;//0.3%
    uint256 private constant ERC721_1155_ST_FEE_USD = 20000;//$0.2 
    uint256 private constant ERC721_1155_FEE_USD = 30000;//$0.3

    /// @dev Checks if caller is an admin
    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Bridge: the caller is not an admin!");
        _;
    }

    /// @dev Checks the contracts is supported on the given chain
    modifier isSupportedChain(string memory _chain) {
        require(supportedChains[_chain], "Bridge: the chain is not supported!");
        _;
    }

    /// @notice Initializes internal variables, sets roles
    /// @param _botMessenger The address of bot messenger
    /// @param _stablecoin The address of USD stablecoin
    /// @param _chain The chain bridge was deployed to
    function initialize(
        address _botMessenger,
        address _stablecoin,
        string memory _chain
    ) public initializer
    {
        require(_botMessenger != address(0), "Bridge: default bot messenger can not be zero address!");
        require(_stablecoin != address(0), "Bridge: stablecoin can not be zero address!");
        // The caller becomes an admin
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // The provided address gets a special role (used in signature verification)
        botMessenger = _botMessenger;
        stablecoin = _stablecoin;
        chain = _chain;
        _setupRole(BOT_MESSENGER_ROLE, botMessenger);

    }

    /// @notice Allow this contract to receiver ERC721 tokens
    /// @dev Should return the selector of itself
    /// @dev Whenever an ERC721 token is transferred to this contract 
    ///      via ERC721.safeTransferFrom this function is called   
    function onERC721Received(address operator, address from, uint256 tokeid, bytes calldata data)
    public 
    returns (bytes4) 
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Allow this contract to receiver ERC1155 tokens
    /// @dev Should return the selector of itself
    /// @dev Whenever an ERC1155 token is transferred to this contract 
    ///      via ERC1155.safeTransferFrom this function is called   
    function onERC1155Received(address operator, address from, uint256 tokeid, uint256 amount, bytes calldata data)
    public 
    returns (bytes4) 
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @notice Locks tokens if the user is permitted to lock
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param params sourceBridgeParams structure (see definition in IBridge.sol)
    /// @return True if tokens were locked successfully
    function lockWithPermit(Assets assetType, sourceBridgeParams calldata params)
        external
        payable
        isSupportedChain(params.targetChain)
        nonReentrant
        returns(bool) 
    {   
        if(assetType != Assets.Native)
            require(msg.value == 0, "Bridge: wrong asset, only native lock payable");

        address sender = msg.sender;
        // Verify the signature (contains v, r, s) using the domain separator
        // This will prove that the user has burnt tokens on the target chain
        bytes32 typeHash = EIP712Utils.getVerifyPriceTypeHash(params);
        signatureVerification(typeHash, params.nonce, params.v, params.r, params.s);
        // Calculate the fee and save it
        uint256 feeAmount;
        if(assetType == Assets.Native || assetType == Assets.ERC20){
            feeAmount = calcFeeScaled(
                params.amount,
                params.stargateAmountForOneUsd,
                params.transferedTokensAmountForOneUsd,
                params.payFeesWithST
            );
        } else {
            feeAmount = calcFeeFixed(
                params.amount,
                params.stargateAmountForOneUsd,
                params.payFeesWithST
            );
        }
        if(params.payFeesWithST) 
            payFees(sender, stargateToken, feeAmount);
        if(!params.payFeesWithST && assetType == Assets.ERC20) 
            payFees(sender, params.token, feeAmount);
        if(!params.payFeesWithST && assetType == Assets.Native){
            require(
                msg.value >= params.amount + feeAmount,
                "Bridge: not enough native tokens were sent to cover the fees!"
            );
            tokenFees[params.token] += feeAmount;
        }
        //Pay with stablecoins if you bridge ERC721 or ERC1155 and do not want to use ST
        if(!params.payFeesWithST && (assetType == Assets.ERC721 || assetType == Assets.ERC1155)) 
            payFees(sender, stablecoin, feeAmount);

        processAsset(
            assetType,
            sender,
            params.token,
            params.tokenId,
            params.amount
        );

        emit Lock(
            assetType,
            sender,
            params.receiver,
            params.amount,
            params.token,
            params.tokenId,
            params.targetChain
        );
        return true;
    }

    /// @notice Burn tokens if the user is permitted to burn
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param params sourceBridgeParams structure (see definition in IBridge.sol)
    /// @return True if tokens were burned successfully
    function burnWithPermit(Assets assetType, sourceBridgeParams calldata params)
        external
        isSupportedChain(params.targetChain)
        nonReentrant
        returns(bool) 
    {       
        require(assetType != Assets.Native, "Bridge: wrong asset, can't burn native token");
        address sender = msg.sender;
        // Verify the signature (contains v, r, s) using the domain separator
        // This will prove that the user has burnt tokens on the target chain
        bytes32 typeHash = EIP712Utils.getVerifyPriceTypeHash(params);
        signatureVerification(typeHash, params.nonce, params.v, params.r, params.s);
        // Calculate the fee and save it
        uint256 feeAmount;
        if(assetType == Assets.Native || assetType == Assets.ERC20){
            feeAmount = calcFeeScaled(
                params.amount,
                params.stargateAmountForOneUsd,
                params.transferedTokensAmountForOneUsd,
                params.payFeesWithST
            );
        } else {
            feeAmount = calcFeeFixed(
                params.amount,
                params.stargateAmountForOneUsd,
                params.payFeesWithST
            );
        }

        if(params.payFeesWithST) 
            payFees(sender, stargateToken, feeAmount);
        if(!params.payFeesWithST && assetType == Assets.ERC20) 
            payFees(sender, params.token, feeAmount);
        //Pay with stablecoins if you bridge ERC721 or ERC1155 and do not want to use ST
        if(!params.payFeesWithST && (assetType == Assets.ERC721 || assetType == Assets.ERC1155)) 
            payFees(sender, stablecoin, feeAmount);

        discardAsset(
            assetType,
            sender,
            params.token,
            params.tokenId,
            params.amount
        );

        emit Burn(
            assetType,
            sender,
            params.receiver,
            params.amount,
            params.token,
            params.tokenId,
            params.targetChain
        );
        return true;
    }

    /// @notice Mint tokens if the user is permitted to mint
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param params targetBridgeParams structure (see definition in IBridge.sol)
    /// @return True if tokens were minted successfully
    function mintWithPermit(Assets assetType, targetBridgeParams calldata params)
        external
        nonReentrant
        returns(bool) 
    {        
        require(assetType != Assets.Native, "Bridge: wrong asset, can't mint native token");
        address sender = msg.sender;
        // Verify the signature (contains v, r, s) using the domain separator
        // This will prove that the user has burnt tokens on the target chain
        bytes32 typeHash = EIP712Utils.getPermitTypeHash(sender, params, chain);
        signatureVerification(typeHash, params.nonce, params.v, params.r, params.s);

        mintAsset(
            assetType,
            sender,
            params.token,
            params.tokenId,
            params.amount
        );

        emit Mint(
            assetType,
            sender,
            sender,
            params.amount,
            params.token,
            params.tokenId,
            chain
        );
        return true;
    }

    /// @notice Unlocks tokens if the user is permitted to unlock
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param params targetBridgeParams structure (see definition in IBridge.sol)
    /// @return True if tokens were unlocked successfully
    function unlockWithPermit(Assets assetType, targetBridgeParams calldata params)
        external
        nonReentrant
        returns(bool) 
    {        
        address sender = msg.sender;
        // Verify the signature (contains v, r, s) using the domain separator
        // This will prove that the user has burnt tokens on the target chain
        bytes32 typeHash = EIP712Utils.getPermitTypeHash(sender, params, chain);
        signatureVerification(typeHash, params.nonce, params.v, params.r, params.s);
        
        unlockAsset(
            assetType,
            sender,
            params.token,
            params.tokenId,
            params.amount
        );

        emit Unlock(
            assetType,
            sender,
            sender,
            params.amount,
            params.token,
            params.tokenId,
            chain
        );
        return true;
    }

    /// @dev Verifies that chain signature is valid 
    /// @param typeHash abi encoded type hash digest
    /// @param nonce Prevent replay attacks
    /// @param v Last byte of the signed PERMIT_DIGEST
    /// @param r First 32 bytes of the signed PERMIT_DIGEST
    /// @param v 32-64 bytes of the signed PERMIT_DIGEST
    function signatureVerification(
        bytes32 typeHash,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(!nonces[nonce], "Bridge: request already processed!");

        bytes32 permitDigest = EIP712Utils.getPermitDigest(typeHash);
        // Recover the signer of the PERMIT_DIGEST
        address signer = ecrecover(permitDigest, v, r, s);
        // Compare the recover and the required signer
        require(signer == botMessenger, "Bridge: invalid signature!");

        nonces[nonce] = true;
        lastNonce = nonce;
    }

    //==========Helper Functions==========

    /// @notice Sets the admin
    /// @param newAdmin Address of the admin   
    function setAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Bridge: new admin can not have a zero address!");
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        emit SetAdmin(newAdmin);
    }

    /// @notice Sets the stablecoin
    /// @param newStablecoin Address of the stablecoin
    function setStablecoin(address newStablecoin) external onlyAdmin {
        stablecoin = newStablecoin;
    }

    /// @notice Sets the stargate token
    /// @param newStargateToken Address of the stargate token   
    function setStargateToken(address newStargateToken) external onlyAdmin {
        stargateToken = newStargateToken;
    }

    /// @notice Sets the bot messenger
    /// @param newBotMessenger Address of the bot messenger (backend server)   
    function setBotMessenger(address newBotMessenger) external onlyAdmin {
        require(newBotMessenger != address(0), "Bridge: new bot messenger can not have a zero address!");
        botMessenger = newBotMessenger;
    }

    /// @notice Lock tokens
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param sender Owner of the locked tokens
    /// @param token Address of the locked token
    /// @param tokenId ID of the locked ERC721 or ERC1155 token, 0 otherwise
    /// @param amount An amount of tokens to lock
    function processAsset(
        Assets assetType,
        address sender,
        address token,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if(assetType == Assets.Native){
            require(msg.value >= amount, "Bridge: wrong native tokens amount");
            return;
        }
        if(assetType == Assets.ERC20){
            IWrappedERC20(token).safeTransferFrom(sender, address(this), amount);
            return;
        }
        if(assetType == Assets.ERC721){
            IWrappedERC721(token).safeTransferFrom(sender, address(this), tokenId);
            return;
        }
        if(assetType == Assets.ERC1155){
            IWrappedERC1155(token).safeTransferFrom(sender, address(this), tokenId, amount, bytes("iamtoken"));   
            return;
        }
        revert("Bridge: wrong asset");
    }

    /// @notice Burn tokens
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param sender Owner of thetokens
    /// @param token Address of the token
    /// @param tokenId ID of the ERC721 or ERC1155 token, 0 otherwise
    /// @param amount An amount of tokens to burn
    function discardAsset(
        Assets assetType,
        address sender,
        address token,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if(assetType == Assets.ERC20){
            IWrappedERC20(token).burn(sender, amount);
            return;
        }
        if(assetType == Assets.ERC721){
            require(
                IWrappedERC721(token).ownerOf(tokenId) == msg.sender,
                "Bridge: cannot burn ERC721, msg.sender not owner"
            );
            IWrappedERC721(token).burn(tokenId);
            return;
        }
        if(assetType == Assets.ERC1155){
            IWrappedERC1155(token).burn(sender, tokenId, amount);   
            return;
        }
        revert("Bridge: wrong asset");
    }

    /// @notice Mint wrapped tokens
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param sender receiver of the minted tokens
    /// @param token Address of the wrapped token
    /// @param tokenId ID of the wrapped ERC721 or ERC1155 token, 0 otherwise
    /// @param amount An amount of tokens to mint
    function mintAsset(
        Assets assetType,
        address sender,
        address token,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if(assetType == Assets.ERC20){
            IWrappedERC20(token).mint(sender, amount);
            return;
        }
        if(assetType == Assets.ERC721){
            IWrappedERC721(token).mint(sender, tokenId);
            return;
        }
        if(assetType == Assets.ERC1155){
            IWrappedERC1155(token).mint(sender, tokenId, amount);   
            return;
        }
        revert("Bridge: wrong asset");
    }

    /// @notice Transfers locked token back to it's owner
    /// @param assetType 0-native, 1-ERC20, 2-ERC721, 3-ERC1155
    /// @param sender Owner of the locked tokens
    /// @param token Address of the locked token
    /// @param tokenId ID of the locked ERC721 or ERC1155 token, 0 otherwise
    /// @param amount An amount of tokens to unlock
    function unlockAsset(
        Assets assetType,
        address sender,
        address token,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if(assetType == Assets.Native){
        // Check if there is enough native tokens on the bridge (no fees)
            require(
                address(this).balance >= amount,
                "Bridge: not enough native tokens on the bridge balance!"
            );
            (bool success, ) = sender.call{ value: amount }("");
            require(success, "Bridge: native tokens unlock failed!");
            return;
        }
        if(assetType == Assets.ERC20){
        // Check if there is enough custom tokens on the bridge (no fees)
            require(
                IWrappedERC20(token).balanceOf(address(this)) >= amount,
                "Bridge: not enough ERC20 tokens on the bridge balance!"
            );
            IWrappedERC20(token).safeTransfer(sender, amount);
            return;
        }
        if(assetType == Assets.ERC721){
        // Check if bridge owns the token
            require(
                IWrappedERC721(token).ownerOf(tokenId) == address(this),
                "Bridge: bridge doesn't own token with this ID!"
            );
            IWrappedERC721(token).safeTransferFrom(address(this),sender, tokenId);
            return;
        }
        if(assetType == Assets.ERC1155){
        // Check if there is enough custom tokens on the bridge (no fees)
            require(
                IWrappedERC1155(token).balanceOf(address(this), tokenId) > 0,
                "Bridge: not enough ERC1155 tokens on the bridge balance!"
            );
            IWrappedERC1155(token).safeTransferFrom(address(this), sender, tokenId, amount, bytes("iamtoken"));   
            return;
        }
        revert("Bridge: wrong asset");
    }
    /// @notice Calculates a fee for bridge operations with ERC20 and native tokens
    /// @param amount An amount of TT tokens that were sent
    /// @param stargateAmountForOneUsd Stargate tokens (ST) amount for one USD
    /// @param transferedTokensAmountForOneUsd TT tokens amount for one USD
    /// @param payFeesWithST true if user choose to pay fees with stargate tokens
    /// @return The fee amount in ST or TT depending on user's preferences
    function calcFeeScaled(
        uint256 amount,
        uint256 stargateAmountForOneUsd,
        uint256 transferedTokensAmountForOneUsd,
        bool payFeesWithST
    ) public pure returns(uint256) {
        uint256 result;

        if(payFeesWithST) {
            //TT * fee rate => USD
            result = amount * ERC20_ST_FEE_RATE / transferedTokensAmountForOneUsd;
            result = result > MIN_ERC20_ST_FEE_USD ? result : MIN_ERC20_ST_FEE_USD;
            result = result < MAX_ERC20_ST_FEE_USD ? result : MAX_ERC20_ST_FEE_USD;
            //USD => ST
            result = result * stargateAmountForOneUsd / PERCENT_DENOMINATOR;
        }
        else if(transferedTokensAmountForOneUsd == 0) {
            result = amount * ERC20_TT_FEE_RATE / PERCENT_DENOMINATOR;
        } else {
            //TT * fee rate => USD
            result = amount * ERC20_TT_FEE_RATE / transferedTokensAmountForOneUsd;
            result = result > MIN_ERC20_TT_FEE_USD ? result : MIN_ERC20_TT_FEE_USD;
            result = result < MAX_ERC20_TT_FEE_USD ? result : MAX_ERC20_TT_FEE_USD;
            //USD => TT
            result = result * transferedTokensAmountForOneUsd / PERCENT_DENOMINATOR;
        }
        return result;
    }

    /// @notice Calculates a fee for bridge operations with ERC721 and ERC1155 tokens
    /// @param amount An amount of tokens that were sent (always 1 if ERC721)
    /// @param stargateAmountForOneUsd Stargate tokens (ST) amount for one USD
    /// @param payFeesWithST true if user choose to pay fees with stargate tokens
    /// @return The fee amount in ST or USD depending on user's preferences
    function calcFeeFixed(
        uint256 amount,
        uint256 stargateAmountForOneUsd,
        bool payFeesWithST
    ) public view returns(uint256) {
        uint256 result;
        if(payFeesWithST) {
            result = amount * (stargateAmountForOneUsd * ERC721_1155_ST_FEE_USD);
            result = result / PERCENT_DENOMINATOR;
        }
        else {
            result = amount * (10 ** IWrappedERC20(stablecoin).decimals()) * ERC721_1155_FEE_USD;
            result = result / PERCENT_DENOMINATOR;
        }
        return result;
    }

    /// @notice Transfer fees from user's wallet to contract address
    /// @param sender user's address
    /// @param token address of token in which fees are paid
    /// @param feeAmount fee amount
    function payFees(address sender, address token, uint256 feeAmount) internal {
        // lazy skip if fee tokens aren't set or amount is zero (useful in case of USDT)
        if(token == address(0) || feeAmount == 0)
            return;
        tokenFees[token] += feeAmount;
        IWrappedERC20(token).safeTransferFrom(sender, address(this), feeAmount);
    }

    /// @notice Withdraws fees accumulated from a specific token operations
    /// @param token The address of the token which transfers collected fees
    /// @param amount The amount of fees from a single token to be withdrawn
    function withdraw(address token, uint256 amount) external nonReentrant onlyAdmin {
        require(tokenFees[token] != 0, "Bridge: no fees were collected for this token!");
        require(tokenFees[token] >= amount, "Bridge: amount of fees to withdraw is too large!");
        
        tokenFees[token] -= amount;
        if(token == address(0)){
            (bool success, ) = msg.sender.call{ value: amount }("");
            require(success, "Bridge: native tokens withdraw failed!");
        } else
            IWrappedERC20(token).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice Adds a chain supported by the bridge
    /// @param newChain The name of the chain
    function setSupportedChain(string memory newChain) external onlyAdmin {
        supportedChains[newChain] = true;
        emit SetNewChain(newChain);
    }

    /// @notice Removes a chain supported by the bridge
    /// @param oldChain The name of the chain
    function removeSupportedChain(string memory oldChain) external onlyAdmin {
        supportedChains[oldChain] = false;
        emit RemoveChain(oldChain);
    }
}
