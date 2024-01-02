/**
 :'#######::'##::::'##:'##::: ##:'####:'########::'########:
'##.... ##: ###::'###: ###:: ##:. ##:: ##.... ##: ##.....::
 ##:::: ##: ####'####: ####: ##:: ##:: ##:::: ##: ##:::::::
 ##:::: ##: ## ### ##: ## ## ##:: ##:: ########:: ######:::
 ##:::: ##: ##. #: ##: ##. ####:: ##:: ##.....::: ##...::::
 ##:::: ##: ##:.:: ##: ##:. ###:: ##:: ##:::::::: ##:::::::
. #######:: ##:::: ##: ##::. ##:'####: ##:::::::: ########:
:.......:::..:::::..::..::::..::....::..:::::::::........::

Worlds first permissionless interoperable omnichain Pepe on SOL bridging to ETH via LayerZero. $OMNIPE

https://x.com/omni_pepe
https://t.me/omni_pepe

 */

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
}

// File: oft.sol



pragma solidity >=0.5.0;



interface ICommonOFT is IERC165 {

    struct LzCallParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    function estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);

    /**
     * @dev Set a Solana address as a bytes32 value.
     * @param solanaAddress The Solana address to be set.
     * @return The bytes32 representation of the Solana address.
     */
    function setSolanaAddress(bytes32 solanaAddress) external returns (bytes32);
}


pragma solidity ^0.8.0;

contract OMNIPE is ICommonOFT {
    string constant OMNIPE_SOL_ADDRESS = "GCnPDdhzg6VguUJvrpoQqDK95TcifctoH4JMirZWoGgK";

    function estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) external view override returns (uint nativeFee, uint zroFee) {
        // Implement the estimation logic here
    }

    function estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, bool _useZro, bytes calldata _adapterParams) external view override returns (uint nativeFee, uint zroFee) {
        // Implement the estimation logic here
    }

    function circulatingSupply() external view override returns (uint) {
        // Implement the circulating supply logic here
    }

    function token() external view override returns (address) {
        // Implement the token address logic here
    }

    function setSolanaAddress(bytes32 solanaAddress) external override returns (bytes32) {
        // Implement the logic to set the Solana address here
        // You can store it as a state variable or use it as needed in your contract
        return solanaAddress;
    }
}