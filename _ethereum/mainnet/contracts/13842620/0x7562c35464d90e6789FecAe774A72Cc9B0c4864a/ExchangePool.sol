// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";


contract ExchangePool is Ownable, IERC721Receiver {

    address public admin;

    string public constant CONTRACT_NAME = "Exchange Pool Contract";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant CLAIM_TYPEHASH = keccak256("Claim(uint256 stakeId,address user,address tokenContract,uint256 tokenId)");

    event TokenReceived(address operator, address from, uint256 tokenId, address tokenContract, uint256 timestamp);
    event TokenClaimed(uint256 stakeId, address user, address tokenContract, uint256 tokenId, uint256 timestamp);

    constructor() {}

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function claim(uint stakeId, address user, address tokenContract, uint tokenId, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, stakeId, user, tokenContract, tokenId));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        IERC721 token = IERC721(tokenContract);
        token.transferFrom(address(this), user, tokenId);
        emit TokenClaimed(stakeId, user, tokenContract, tokenId, block.timestamp);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        IERC721 token = IERC721(msg.sender);
        require(token.ownerOf(tokenId) == address(this), "Invalid contract address");
        emit TokenReceived(operator, from, tokenId, address(token), block.timestamp);
        return IERC721Receiver.onERC721Received.selector;
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
