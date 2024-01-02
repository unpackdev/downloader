// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./console.sol";

import "./IMOPNERC6551Account.sol";
import "./IMOPNGovernance.sol";

import "./IERC165.sol";
import "./IERC1271.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./Multicall.sol";
import "./SignatureChecker.sol";
import "./ERC6551AccountLib.sol";

error NotAuthorized();
error OwnerNotExist();

interface ICryptoPunks {
    function punkIndexToAddress(
        uint index
    ) external view returns (address owner);
}

contract MOPNERC6551Account is
    IERC165,
    IERC1271,
    IERC721Receiver,
    IERC1155Receiver,
    IMOPNERC6551Account,
    Multicall
{
    address public immutable governance;

    uint256 public state;

    constructor(address governance_) {
        governance = governance_;
    }

    receive() external payable {}

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable returns (bytes memory result) {
        require(_isValidSigner(msg.sender), "Invalid signer");
        require(operation == 0, "Only call operations are supported");
        ++state;
        return _call(to, value, data);
    }

    function executeProxy(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation,
        address msgsender
    ) external payable onlyHelper returns (bytes memory result) {
        require(_isValidSigner(msgsender), "Invalid signer");
        require(operation == 0, "Only call operations are supported");
        ++state;
        return _call(to, value, data);
    }

    /// @dev Executes a low-level call
    function _call(
        address to,
        uint256 value,
        bytes calldata data
    ) internal returns (bytes memory result) {
        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function token()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        bytes memory footer = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .token();
        if (chainId != block.chainid) return address(0);

        if (tokenContract == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
            return ICryptoPunks(tokenContract).punkIndexToAddress(tokenId);
        } else {
            return IERC721(tokenContract).ownerOf(tokenId);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId);
    }

    function isValidSigner(
        address signer,
        bytes calldata
    ) external view virtual returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    function _isValidSigner(
        address signer
    ) internal view virtual returns (bool) {
        return signer == owner();
    }

    /// @dev Allows ERC-1155 tokens to be received. This function can be overriden.
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @dev Allows ERC-1155 token batches to be received. This function can be overriden.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    modifier onlyHelper() {
        if (msg.sender != IMOPNGovernance(governance).ERC6551AccountHelper())
            revert NotAuthorized();
        _;
    }
}
