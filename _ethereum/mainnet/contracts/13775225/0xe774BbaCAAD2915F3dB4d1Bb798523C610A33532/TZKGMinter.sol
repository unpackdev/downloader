//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Context.sol";
import "./ECDSA.sol";

interface IERC721Mintable {
    function mint(address to, uint256 tokenId) external;
}

contract TZKGMinter is Context, Ownable {
    address public validator;

    constructor(address _validator) {
        validator = _validator;
    }

    function mint(
        address contractAddress,
        uint256 tokenId,
        uint256 deadline,
        uint256 price,
        bytes calldata sig
    ) public payable {
        require(deadline > block.timestamp, "Minter: deadline exceeded");
        require(msg.value == price, "price is not as same as money");

        address signer = recover(
            block.chainid,
            contractAddress,
            tokenId,
            _msgSender(),
            price,
            deadline,
            sig
        );
        require(signer == validator, "Minter: invalid signature");

        IERC721Mintable(contractAddress).mint(_msgSender(), tokenId);
    }

    function recover(
        uint256 chainId,
        address contractAddress,
        uint256 tokenId,
        address to,
        uint256 price,
        uint256 deadline,
        bytes calldata sig
    ) public pure returns (address) {
        return
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    encode(
                        chainId,
                        contractAddress,
                        tokenId,
                        to,
                        price,
                        deadline
                    )
                ),
                sig
            );
    }

    function encode(
        uint256 chainId,
        address contractAddress,
        uint256 tokenId,
        address to,
        uint256 price,
        uint256 deadline
    ) public pure returns (bytes32) {
        bytes memory m = abi.encode(
            chainId,
            contractAddress,
            tokenId,
            to,
            price,
            deadline
        );

        return keccak256(m);
    }

    function timestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function blockNumber() public view returns (uint256) {
        return block.number;
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}
