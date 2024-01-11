//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

/**
 * @notice Whitelist stage of Adventurers Token workflow
 */
abstract contract WhiteList is ERC721, EIP712 {
    string public constant EIP712_VERSION = "1.0.0";

    /* state */
    address public signer;
    mapping(address /* minter */ => /* minted */ uint) public whitelistMinters;

    constructor() EIP712(NAME, EIP712_VERSION) {
        signer = msg.sender;
    }

    /* eip-712 */
    bytes32 private constant PASS_TYPEHASH = keccak256("MintPass(address wallet,uint256 count)");

    /* change eip-712 signer address, set 0 to disable WL */
    function setSigner(address _value) external onlyOwner {
        signer = _value;
    }

    function mintSelected(uint _count, uint _signatureCount, bytes memory _signature)
        external returns (uint from, uint to)
    {
        require(signer != address(0), "eip-712: whitelist mint disabled");

        bytes32 _digest = _hashTypedDataV4(
            keccak256(abi.encode(PASS_TYPEHASH, msg.sender, _signatureCount))
        );
        require(ECDSA.recover(_digest, _signature) == signer, "eip-712: invalid signature");
        uint _maxCount = _signatureCount + 1 - whitelistMinters[msg.sender];
        require(_count < _maxCount, "eip-712: invalid count");
        whitelistMinters[msg.sender] += _count;

        return _mint(msg.sender, _count);
    }
}
