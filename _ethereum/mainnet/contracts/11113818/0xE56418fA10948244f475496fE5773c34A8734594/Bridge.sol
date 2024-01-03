// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "./ERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./IWETH.sol";

contract Bridge is Ownable {
    using ECDSA for bytes32;
    address public immutable WETH;
    mapping(uint256 => bool) redeemedTransactions;

    event Mint(
        ERC20 indexed token,
        bytes32 ellipticoin_address,
        uint256 amount
    );

    constructor(address _WETH) public {
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function mintWETH(bytes32 ellipticoin_address) public payable {
        IWETH(WETH).deposit{value: msg.value}();
        ERC20(WETH).transfer(address(this), msg.value);
        Mint(ERC20(WETH), ellipticoin_address, msg.value);
    }

    function mint(
        ERC20 token,
        bytes32 ellipticoin_address,
        uint256 amount
    ) public {
        token.transferFrom(msg.sender, address(this), amount);
        Mint(token, ellipticoin_address, amount);
    }

    function releaseWETH(
        address to,
        uint256 amount,
        uint32 foreignTransactionId,
        bytes memory signature
    ) public {
        release(ERC20(WETH), address(this), amount, foreignTransactionId, signature);
        IWETH(WETH).withdraw(amount);
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "Ether transfer failed");
    }

    function release(
        ERC20 token,
        address to,
        uint256 amount,
        uint32 foreignTransactionId,
        bytes memory signature
    ) public {
        require(!redeemedTransactions[foreignTransactionId], "invalid foreignTransactionId");
        redeemedTransactions[foreignTransactionId] = true;
        bytes32 hash = keccak256(
            abi.encodePacked(address(token), msg.sender, amount, foreignTransactionId, this)
        );
        require(signedByOwner(hash, signature), "invalid signature");
        token.transfer(to, amount);
    }

    function signedByOwner(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool signed)
    {
        return hash.recover(signature) == owner();
    }
}
