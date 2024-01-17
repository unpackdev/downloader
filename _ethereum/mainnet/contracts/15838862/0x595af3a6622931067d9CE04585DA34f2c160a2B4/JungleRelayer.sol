// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC1155ReceiverUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";

/**
 * @title Jungle Relayer Contract
 * @dev This contract acts as a User to buy NFTs on behalf of Jungle users
 *      and automatically transfer it to the user in the same transaction.
 */
contract JungleRelayer is OwnableUpgradeable, ERC1155ReceiverUpgradeable, IERC721ReceiverUpgradeable, UUPSUpgradeable, NativeMetaTransaction {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum HowToCall { Call, DelegateCall }
    enum NFTType { ERC721, ERC1155 }

    struct NFTData {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        NFTType nftType;
    }

    struct Relay {
        //Contract address of other platform where user wans to execute the call
        address contractAddress;
        //ERC20 token address, in which payment is made, zero address for native token(ETH)
        address paymentToken;
        //Price at which it will be sold on the other platform
        uint256 baseAmount;
        //Encoded function call data which will be called in contract address
        bytes data;
        //Any address which needs to be approved to allow token transfer
        address tokenTransferApproval;
    }

    uint16  public constant MAX_BASIS_POINTS = 10000;
    address public feeRecipient; // Address in which resaleFee will be deposited
    address public feeController;
    uint16  public resaleFee; // Fee charged for resale
    uint16  public cashback; // Fee or amount which will be trasfer back

    //Stores the current caller for one execution, acts as a mutex variable for Re-entrancy
    address private currentCaller;

    mapping(address =>mapping(bytes4 => bool)) public isVerified;
    mapping(address => bool) public isVerifiedForApproval;

    event FeeRecipientChanged(address _feeRecipient);
    event CashbackChanged(uint16 _cashback);
    event ResaleFeeChanged(uint16 _resaleFee);
    event EtherReceived(address sender, uint256 _etherAmount);

    modifier onlyFeeController() {
        require(_msgSender() == feeController, "Invalid Caller");
        _;
    }

    function initialize(address _initialContract, 
                        address _initialApprovalContract, 
                        address _feeRecipient, 
                        address _defaultFeeController, 
                        uint16 _resaleFee, 
                        uint16 _cashback, 
                        bytes4 _functionSig,
                        address _contractOwner) external initializer{
        require(_contractOwner != address(0), "Invalid owner");
        __Ownable_init();
        _initializeEIP712();
        require(_feeRecipient != address(0), "Invalid Fee Recipient.");
        require(_defaultFeeController != address(0), "Invalid Fee Setter.");
        require(_initialContract != address(0), "Initial Contract cannot be Zero Address");
        require(_cashback <= _resaleFee, "Invalid cashback or resaleFee amount.");
        isVerified[_initialContract][_functionSig] = true;
        feeRecipient = _feeRecipient;
        feeController = _defaultFeeController;
        resaleFee = _resaleFee;
        cashback = _cashback;

        if(_initialApprovalContract != address(0)){
            isVerifiedForApproval[_initialApprovalContract] = true;
        }
        _transferOwnership(_contractOwner);
    }

    //Only owner function for upgrading proxy.
    function _authorizeUpgrade(address) internal override onlyOwner {}    

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }    

    fallback() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /**
     * Executes a message call to a contract.
     * Transfers resaleFee to admin and cashback to user, if any.
     * resaleFee amount is calculated from the salePrice, and added on top of it.
     * cashback amount is calculated from the salePrice, and deducted from resaleFee to send to user
     *
     * If payment is in Ether, transfers any extra balance returned by 
     * relay.contractAddress, back to the user.
     *
     * If payment is in ERC20 token, necessary approval are given beforehand.
     *
     * NFTs received in this contract during this execution are instantly
     * transferred to the current caller if the NFT contract supports safeTransferFrom,
     * otherwise nftData has to be passed in the execute function, and those NFTs will be 
     * checked and transferred to the caller.
     *
     * @dev Can be called by any user.
     * @param relay Relay object with call data.
     * @param nftDatas NFT Data object array to transfer NFTs if any.
     */
    function execute(Relay calldata relay, NFTData[] memory nftDatas) external payable {

        require(currentCaller == address(0), "Reentrant call");
        require(relay.contractAddress != address(this), "Can't call to same contract");
        require(isVerified[relay.contractAddress][bytes4(relay.data)], "Either Contract or Function not verified");

        //Mutex variable update, function entered
        currentCaller = _msgSender();

        verifyNFTData(nftDatas);

        uint256 resaleFeeAmount = (relay.baseAmount * resaleFee) / MAX_BASIS_POINTS;
        uint256 cashbackAmount  = (relay.baseAmount * cashback ) / MAX_BASIS_POINTS;
        uint256 totalAmount = relay.baseAmount + resaleFeeAmount;

        if(relay.paymentToken == address(0)) {
            require(totalAmount >= msg.value, "Incorrect value.");

            uint256 contractBalance = msg.value;
            
            (bool result,) = _call(relay.contractAddress, HowToCall.Call, relay.data, relay.baseAmount);
            require(result, "Function call not successful.");

            if(cashbackAmount > 0){
                resaleFeeAmount -= cashbackAmount;
                (bool success,) = payable(_msgSender()).call{value: cashbackAmount}("");
                require(success, "Cashback transfer failed.");
            }

            if(resaleFeeAmount > 0){
                (bool success,) = payable(feeRecipient).call{value: resaleFeeAmount}("");
                require(success, "ResaleFee transfer failed.");
            }

            uint256 remainingBalance = contractBalance - relay.baseAmount - cashbackAmount - resaleFeeAmount;
            if(remainingBalance > 0){
                (bool success,) = payable(_msgSender()).call{value: remainingBalance}("");
                require(success, "Remaining balance transfer failed.");
            }
        }
        else {
            IERC20Upgradeable(relay.paymentToken).safeTransferFrom(_msgSender(), address(this), totalAmount);

            if(relay.tokenTransferApproval != address(0) && 
               isVerifiedForApproval[relay.tokenTransferApproval] && 
               isContract(relay.paymentToken)) {
                uint256 tokenApproval = IERC20Upgradeable(relay.paymentToken).allowance(address(this), relay.tokenTransferApproval);
                if(tokenApproval < totalAmount){
                    IERC20Upgradeable(relay.paymentToken).safeApprove(relay.tokenTransferApproval, 0);
                    IERC20Upgradeable(relay.paymentToken).safeApprove(relay.tokenTransferApproval, type(uint).max);
                }
            }

            (bool result,) = _call(relay.contractAddress, HowToCall.Call, relay.data, 0);
            require(result, "Function call not successful.");

            if(cashbackAmount > 0){
                resaleFeeAmount -= cashbackAmount;
                IERC20Upgradeable(relay.paymentToken).safeTransfer(_msgSender(), cashbackAmount);
            }

            if(resaleFeeAmount > 0){
                IERC20Upgradeable(relay.paymentToken).safeTransfer(feeRecipient, resaleFeeAmount);
            }
        }

        transferNFTData(nftDatas);

        //Mutex variable update, function exited
        currentCaller = address(0);
    }

    /**
     * Execute a message call to a contract
     *
     * @dev Can be called by the owner.
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function call(address dest, HowToCall howToCall, bytes memory data)
    external payable onlyOwner
    returns (bool result, bytes memory ret)
    {
        (result, ret) =  _call(dest, howToCall, data, msg.value);
    }
    /**
     * Recovers ether from the contract.
     * This contract is not supposed to hold any ether at anytime.
     * If any user accidently transfers ether to the contract only
     * owner will be able to recover those ethers.
     *
     * @dev Can be called by the owner.
     * @param receiver Address to which the ether will be sent to
     * @return result Result of the transfer (success or failure)
     */
    function recoverEther(address receiver)
    external onlyOwner
    returns (bool result, bytes memory ret)
    {
        require(receiver != address(0), "Receiver address cannot be zero address");
        (result, ret) =  _call(receiver, HowToCall.Call, "", address(this).balance);
    }

    /**
     * @dev Sets the feeController
     * can be only called the owner
     * @param _feeController address of new feeSetter
     */
    function setFeeController(address _feeController) external onlyOwner {
        require(_feeController != address(0), "Invalid Address");
        feeController = _feeController;
    }
    /**
     * @dev Sets the verified contract and function sig
     * @param _contractAddress address of the contract
     * @param _functionSig function signature
     * @param _tokenTransferApproval address where relayer can approve payment for ERC20 tokens
     * @param _status true or false
     */
    function setVerified(address _contractAddress, 
                         bytes4 _functionSig,
                         address _tokenTransferApproval, 
                         bool _status) external onlyFeeController {
        require(_contractAddress != address(0), "Contract Address cannot be a zero address");

        if(_functionSig != bytes4(0)){
            isVerified[_contractAddress][_functionSig] =  _status;
        }
        if(_tokenTransferApproval != address(0)){
            isVerifiedForApproval[_tokenTransferApproval] = _status;
        }
    }
    
    /**
     * @dev Set fee recipient
     * @param _feeRecipient address of the fee recipient
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Fee recipient cannot be a zero address");
        feeRecipient = _feeRecipient;
        emit FeeRecipientChanged(_feeRecipient);
    }

     /**
     * @dev Set resale fee
     * @param _resaleFee resaleFee amount in uint256
     */
    function setResaleFee(uint16 _resaleFee) external onlyFeeController {
        require(_resaleFee < MAX_BASIS_POINTS, "ResaleFee too high. ");
        resaleFee = _resaleFee;
        emit ResaleFeeChanged(_resaleFee);

    }

    /**
    * @dev Set cashback
    * @param _cashback cashback amount in uint256
     */
    function setCashback(uint16 _cashback) external onlyFeeController {
        require(_cashback <= resaleFee, "Cashback cannot be greater than resaleFee ");
        cashback = _cashback;
        emit CashbackChanged(_cashback);
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. Transfers the NFT to the currentCaller 
     * as soon as it is received. Prevents the contract from receiving NFTs when the contract is not in execution. 
     * This function is called from the NFT contract at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param _id The ID of the token being transferred
     * @param _value The amount of tokens being transferred
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(address, address, uint256 _id, uint256 _value, bytes calldata _data) external override returns(bytes4) {
        require(currentCaller != address(0), "onERC1155Received: transfer not accepted");

        IERC1155Upgradeable(_msgSender()).safeTransferFrom(address(this), currentCaller, _id, _value, _data);

        return this.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. Transfers the NFTs to the currentCaller 
     * as soon as they are received. Prevents the contract from receiving NFTs when the contract is not in execution. 
     * This function is called from the NFT contract at the end of a `safeBatchTransferFrom` after the balances have
     * been updated. 
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param _ids An array containing ids of each token being transferred (order and length must match values array)
     * @param _values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(address, address, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override returns(bytes4) {
        require(currentCaller != address(0),"onERC1155BatchReceived: transfer not accepted");
        IERC1155Upgradeable(_msgSender()).safeBatchTransferFrom(address(this), currentCaller, _ids, _values, _data);
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     * Transfers the NFTs to the currentCaller as soon as they are received. 
     * Prevents the contract from receiving NFTs when the contract is not in execution.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256 tokenId, bytes memory data) external override returns(bytes4) {
        require(currentCaller != address(0),"onERC1155Received: transfer not accepted");
        IERC721Upgradeable(_msgSender()).safeTransferFrom(address(this), currentCaller, tokenId, data);
        return this.onERC721Received.selector;
    }

    /**
     * Transfer NFTs to user, if not automatically transferred by onReceived functions.
     * This is for NFT contracts which do not perform safeTransfer checks
     *
     * @param nftDatas NFT Data object array to transfer NFTs if any.
     */
    function transferNFTData(NFTData[] memory nftDatas) internal {
        for(uint8 i = 0; i < nftDatas.length; i++){
            NFTData memory nftData = nftDatas[i];
            if(nftData.nftType == NFTType.ERC721){
                address ownerOfToken = IERC721Upgradeable(nftData.contractAddress).ownerOf(nftData.tokenId);
                if(ownerOfToken == address(this)){
                    IERC721Upgradeable(nftData.contractAddress).transferFrom(address(this), _msgSender(),nftData.tokenId);
                }
            }
            else if(nftData.nftType == NFTType.ERC1155){
                uint256 tokenBalance = IERC1155Upgradeable(nftData.contractAddress).balanceOf(address(this), nftData.tokenId);
                if(tokenBalance==nftData.amount){
                    IERC1155Upgradeable(nftData.contractAddress).safeTransferFrom(address(this), _msgSender(), nftData.tokenId, nftData.amount, "");
                }
            }
        }
    }

    /**
     * Internal function to execute a message call to a contract
     *
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function _call(address dest, HowToCall howToCall, bytes memory data, uint256 value)
    internal
    returns (bool result, bytes memory ret)
    {
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call{value:value}(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
    }

    /**
     * Contract should not hold any NFT which is being sold.
     *
     * @param nftDatas NFT Data object array to verify NFTs if any.
     */
    function verifyNFTData(NFTData[] memory nftDatas) internal view {
        for(uint8 i = 0; i < nftDatas.length; i++){
            NFTData memory nftData = nftDatas[i];
            if(nftData.nftType == NFTType.ERC721) {
                address ownerOfToken = IERC721Upgradeable(nftData.contractAddress).ownerOf(nftData.tokenId);
                require(ownerOfToken != address(this), "Invalid NFT data");
            }
            else if(nftData.nftType == NFTType.ERC1155){
                uint256 tokenBalance = IERC1155Upgradeable(nftData.contractAddress).balanceOf(address(this), nftData.tokenId);
                require(tokenBalance==0, "Invalid NFT data");
            }
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}