// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import "./ERC1155TokenReceiver.sol";
import "./IERC1155InventoryBurnable.sol";
import "./Recoverable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";


contract UMADVoucherRedeemer is Recoverable, Pausable, ERC1155TokenReceiver{
    
    using ERC20Wrapper for IWrappedERC20;
    using SafeMath for uint256;

    IERC1155InventoryBurnable public immutable vouchersContract;
    IWrappedERC20 public immutable tokenContract;
    address public tokenHolder;

    mapping (uint256 => uint256) private _voucherTokenAmount;

    /**
     * Constructor.
     * @param _vouchersContract the address of the vouchers contract.
     * @param _tokenContract the address of the ERC20 token contract.
     * @param _tokenHolder the address of the ERC20 token holder.
     */
    constructor(
        IERC1155InventoryBurnable _vouchersContract,
        IWrappedERC20 _tokenContract,
        address _tokenHolder
    ) Ownable(msg.sender) Pausable(true){
        vouchersContract = _vouchersContract;
        tokenContract = _tokenContract;
        tokenHolder = _tokenHolder;
    }

    /**
     * Sets the ERC20 token value for voucher.
     * @dev Reverts if the sender is not the contract owner.
     * @param tokenIds the id of the voucher.
     * @param amounts value of the voucher in ERC20 token.
     */
    function setVoucherValues(uint256[] memory tokenIds, uint256[] memory amounts) external virtual{
        _requireOwnership(_msgSender());
        require(tokenIds.length == amounts.length, "UMADVoucherRedeemer: invalid length of array");
        for(uint256 i; i < tokenIds.length; ++i){
            uint256 amount = amounts[i];
            require(amount > 0, "UMADVoucherRedeemer: invalid amount");
            _voucherTokenAmount[tokenIds[i]] = amount;
        }
    }

    /**
     * Gets the ERC20 token value for voucher.
     * @param tokenId the id of the voucher.
     */
    function getVoucherValue(uint256 tokenId) external view virtual returns (uint256){
        return _voucherTokenAmount[tokenId];
    }

    /**
     * Validates the validity of the voucher and returns its value.
     * @dev Reverts if the voucher is not a valid voucher.
     * @param tokenId the id of the voucher.
     * @return the value of the voucher in ERC20 token.
     */
    function _voucherValue(uint256 tokenId) internal view virtual returns (uint256) {
        uint256 tokenValue = _voucherTokenAmount[tokenId];
        require(tokenValue > 0, "UMADVoucherRedeemer: invalid voucher");
        return tokenValue;
    }

    /**
     * Sets the token holder address.
     * @dev Reverts if the sender is not the contract owner.
     * @param _tokenHolder the new address for the token holder.
     */
    function setTokenHolder(address _tokenHolder) external virtual {
        _requireOwnership(_msgSender());
        tokenHolder = _tokenHolder;
    }

    /**
     * Pause the redeem function.
     * @dev Reverts if the sender is not the contract owner.
     */
    function pause() public{
        _requireOwnership(_msgSender());
        _pause();
    }

    /**
     * Unpause the redeem function.
     * @dev Reverts if the sender is not the contract owner.
     */
    function unpause() public{
        _requireOwnership(_msgSender());
        _unpause();
    }

    /**
     * Handle the receipt of a single ERC1155 token type.
     * @dev See {IERC1155TokenReceiver-onERC1155Received(address,address,uint256,uint256,bytes)}.
     */
    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 id,
        uint256 value,
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        _requireNotPaused();
        require(msg.sender == address(vouchersContract), "UMADVoucherRedeemer: wrong sender");
        vouchersContract.burnFrom(address(this), id, value); 
        uint256 tokenAmount = _voucherValue(id).mul(value);
        tokenContract.wrappedTransferFrom(tokenHolder, from, tokenAmount);
        return _ERC1155_RECEIVED;
    }

    /**
     * Handle the receipt of multiple ERC1155 token types.
     * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)}.
     */
    function onERC1155BatchReceived(
        address, /*operator*/
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        _requireNotPaused();
        require(msg.sender == address(vouchersContract), "UMADVoucherRedeemer: wrong sender");
        vouchersContract.batchBurnFrom(address(this), ids, values);
        uint256 tokenAmount;
        for (uint256 i; i != ids.length; ++i) {
            uint256 id = ids[i];
            tokenAmount = tokenAmount.add(_voucherValue(id).mul(values[i]));
        }
        tokenContract.wrappedTransferFrom(tokenHolder, from, tokenAmount);
        return _ERC1155_BATCH_RECEIVED;
    }
}