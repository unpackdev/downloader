pragma solidity ^0.8.18;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1271.sol";
import "./IERC1155Receiver.sol";
import "./IERC721Receiver.sol";
import "./SignatureChecker.sol";
import "./Bytecode.sol";
import "./IERC6551Account.sol";
import "./IERC6551Executable.sol";

/**
 * @title TokenGatedAccount
 * @dev This contract represents a Token Gated Account (TGA) which serves as an interface for interacting with
 * various token standards and executing operations based on the ownership and authorization of tokens.
 * The contract implements multiple interfaces to ensure compatibility and extend functionality.
 *
 * @author Logan Brutsche
 */
contract TokenGatedAccount is IERC165, IERC1271, IERC6551Account, IERC6551Executable, IERC1155Receiver, IERC721Receiver {
    address public bondedAddress;
    address public tokenOwnerAtLastBond;

    /**
     * @dev Ensures that the message sender is either the token owner or the bonded account, 
     * unless the owner has changed since the last bond call.
     */
    modifier onlyAuthorizedMsgSender() {
        require(_isValidSigner(msg.sender), "Unauthorized caller");
        _;
    }
    
    /**
     * @dev Emitted when a new address is bonded to this contract.
     * @param _newBondedAddress The address that was bonded.
     */
    event NewBondedAddress(address indexed _newBondedAddress);

    /**
     * @dev Bonds a specified address to this contract.
     * Note the bonded address can pass this bond on without authorization from owner().
     * @param _addressToBond The address to bond.
     */
    function bond(address _addressToBond) 
        external
        onlyAuthorizedMsgSender()
    {
        bondedAddress = _addressToBond;
        tokenOwnerAtLastBond = owner();

        emit NewBondedAddress(_addressToBond);
    }

    uint public state;

    receive() external payable {}
    fallback() external payable {}

    /**
     * @dev Executes a call on another contract on behalf of the token owner or bonded account.
     * @param _to The contract address to call.
     * @param _value The amount of ether to send.
     * @param _data The call data.
     * @param operation The operation type (only call operations are supported).
     * @return result The result data of the call or its revert message.
     */
    function execute(address _to, uint256 _value, bytes calldata _data, uint operation)
        external
        payable
        onlyAuthorizedMsgSender()
        returns (bytes memory result)
    {
        require(operation == 0, "Only call operations are supported");

        state ++;

        bool success;
        (success, result) = _to.call{value: _value}(_data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * @dev Returns the token details that this contract is associated with.
     * @return _chainId The chain ID.
     * @return _tokenContract The address of the token contract.
     * @return _tokenId The ID of the token.
     */
    function token()
        external
        view
        returns (
            uint256 _chainId,
            address _tokenContract,
            uint256 _tokenId
        )
    {
        uint256 length = address(this).code.length;
        return
            abi.decode(
                Bytecode.codeAt(address(this), length - 0x60, length),
                (uint256, address, uint256)
            );
    }

    /**
     * @dev Returns the owner of the token associated with this contract from the ERC721 contract.
     * @return The address of the token owner.
     */
    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this.token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    /**
     * @dev Checks if this contract supports a specified interface.
     * @param _interfaceId The ID of the interface to check.
     * @return true if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return (_interfaceId == type(IERC165).interfaceId ||
            _interfaceId == type(IERC6551Account).interfaceId);
    }

    /**
     * @dev Checks if a specified signer is valid for this contract.
     * @param signer The address of the signer.
     * @return The function selector if the signer is valid, 0 otherwise.
     */
    function isValidSigner(address signer, bytes calldata) external view returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    /**
     * @dev Internal function to check if a specified signer is valid.
     * @param signer The address of the signer.
     * @return true if the signer is valid, false otherwise.
     */
    function _isValidSigner(address signer) internal view returns (bool) {
        return signer == owner() || (signer == bondedAddress && tokenOwnerAtLastBond == owner());
    }

    /**
     * @dev Checks if a specified signature is valid for a given hash.
     * @param hash The hash of the data.
     * @param signature The signature to check.
     * @return The function selector if the signature is valid, empty bytes otherwise.
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4)
    {
        bool isValid = 
            SignatureChecker.isValidSignatureNow(owner(), hash, signature) ||
            (SignatureChecker.isValidSignatureNow(bondedAddress, hash, signature) && tokenOwnerAtLastBond == owner());

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token.
     * @return The function selector.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of multiple ERC1155 tokens.
     * @return The function selector.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external returns (bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Handles the receipt of a single ERC721 token.
     * @return The function selector.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
