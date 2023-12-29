// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./PoolStruct.sol";
import "./PoolHash.sol";

contract PurelistPool is Ownable, Pausable, EIP712, ReentrancyGuard, IERC721Receiver {
    string public constant NAME = "Purelist Pool";
    string public constant VERSION = "1.0";

    mapping(bytes32 => bool) public cancelledOrFilled;

    mapping(address => bool) public bannedList;

    address public oracle;
    
    event Deposit(address sender, uint256 value);
    event Withdraw(Order order, bytes32 orderHash);
    event OfficialClaim(address account, uint256 amount);
    event OrderCancelled(bytes32 orderHash);
    
    constructor(address _oracle) {
        oracle = _oracle;
        DOMAIN_SEPARATOR = _hashDomain(EIP712Domain({
            name              : NAME,
            version           : VERSION,
            chainId           : block.chainid,
            verifyingContract : address(this)
        }));
    }

    function withdraw(Order calldata order, bytes calldata signature) external callerIsUser nonReentrant whenNotPaused {
        _withdraw(order, signature);
    }

    function deposit() external payable callerIsUser nonReentrant {
        require(msg.value > 0, "deposit value cannot be zero");
        emit Deposit(_msgSender(), msg.value);
    }

    receive() external payable {
        emit Deposit(_msgSender(), msg.value);
    }

    function cancelOrder(Order calldata order) external callerIsUser nonReentrant {
        require(msg.sender == order.from, "not sent by owner");
        bytes32 hash = _hashOrder(order);

        require(!cancelledOrFilled[hash], "order cancelled or filled");
        cancelledOrFilled[hash] = true;
        emit OrderCancelled(hash);
    }

    function officialClaim(address account, uint256 amount) external onlyOwner {
        require(account != address(0));
        payable(account).transfer(amount);
        emit OfficialClaim(account, amount);
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "address cannot be zero");
        oracle = _oracle;
    }

    function setBannedList(address[] calldata accounts, bool banned) external onlyOwner {
        for (uint i = 0; i < accounts.length; i ++) {
            bannedList[accounts[i]] = banned;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _withdraw(Order calldata order, bytes calldata signature) internal {
        require(!bannedList[order.from], "owner has been banned");
        require(order.suitableTime <= block.timestamp && order.expiredTime > block.timestamp, "time not suitable");
        bytes32 orderhash = _hashOrder(order);
        require(!cancelledOrFilled[orderhash], "order cancelled or filled");
        cancelledOrFilled[orderhash] = true;
        bytes32 signhash = _hashToSign(orderhash);
        require(_validateSignature(signhash, signature), "failed authorization");
        _transfer(order);
        emit Withdraw(order, signhash);
    }

    function _transfer(Order calldata order) internal {
        if (order.typ == ItemType.NATIVE) {
            payable(order.to).transfer(order.amounts[0]);
        } else if (order.typ == ItemType.ERC20) {
            IERC20(order.collection).transfer(order.to, order.amounts[0]);
        } else if (order.typ == ItemType.ERC721) {
            for (uint i = 0; i < order.tokenIds.length; i++) {
                IERC721(order.collection).transferFrom(address(this), order.to, order.tokenIds[i]);
            }
        } else if (order.typ == ItemType.ERC1155) {
            IERC1155(order.collection).safeBatchTransferFrom(address(this), order.to, order.tokenIds, order.amounts, bytes(""));
        } else {
            revert("invalid item type");
        }
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function _validateSignature(bytes32 hash, bytes memory signature) internal view returns (bool) {
        if(signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return _verify(oracle, hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return _verify(oracle, hash, r, vs);
        }
        return false;
    }

    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        require(v == 27 || v == 28, "Invalid v parameter");
        address recoveredSigner = ecrecover(digest, v, r, s);
        if (recoveredSigner == address(0)) {
          return false;
        } else {
          return signer == recoveredSigner;
        }
    }

    function _verify(
        address signer,
        bytes32 digest,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (bool) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        require(v == 27 || v == 28, "Invalid v parameter");
        address recoveredSigner = ecrecover(digest, v, r, s);
        if (recoveredSigner == address(0)) {
          return false;
        } else {
          return signer == recoveredSigner;
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

}