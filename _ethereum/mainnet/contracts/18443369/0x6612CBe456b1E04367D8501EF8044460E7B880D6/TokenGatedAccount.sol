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

contract TokenGatedAccount is IERC165, IERC1271, IERC6551Account, IERC6551Executable, IERC1155Receiver, IERC721Receiver {
    address public bondedAddress;
    address public tokenOwnerAtLastBond;

    // ensures the msg.sender is either:
    //  * the token owner
    //  * the bonded account - UNLESS owner() has changed since that bond call
    modifier onlyAuthorizedMsgSender() {
        require(_isValidSigner(msg.sender), "Unauthorized caller");
        _;
    }

    event NewBondedAddress(address indexed _newBondedAddress);

    // note that we the bonded address can pass this bond on without authorization from owner()
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

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this.token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return (_interfaceId == type(IERC165).interfaceId ||
            _interfaceId == type(IERC6551Account).interfaceId);
    }

    function isValidSigner(address signer, bytes calldata) external view returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function _isValidSigner(address signer) internal view returns (bool) {
        return signer == owner() || (signer == bondedAddress && tokenOwnerAtLastBond == owner());
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        bool isValid = 
            SignatureChecker.isValidSignatureNow(owner(), hash, signature) ||
            (SignatureChecker.isValidSignatureNow(bondedAddress, hash, signature) && tokenOwnerAtLastBond == owner());

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

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
