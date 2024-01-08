// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // solhint-disable-line compiler-version

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./StorageSlotOwnable.sol";
import "./ERC20OnApprove.sol";

import "./AirdropRegistryStorage.sol";
import "./AirdropRegistryVerify.sol";

// import "./AirdropRegistryMerkleProof.sol";

contract AirdropRegistry is AirdropRegistryStorage, StorageSlotOwnable, OnApprove, AirdropRegistryVerify {
    using SafeERC20 for IERC20;

    event Claimed(address indexed token, address indexed beneficiary, uint256 amount, uint256 nonce);

    function chainid() external view returns (uint256) {
        return block.chainid;
    }

    //////////////////////////////////////////
    //
    // Kernel
    //
    //////////////////////////////////////////

    function implementationVersion() public view virtual override returns (string memory) {
        return "1.0.0";
    }

    function _initializeKernel(bytes memory data) internal override {
        (address owner_, address tokenWallet_) = abi.decode(data, (address, address));
        _setOwner(owner_);
        tokenWallet = tokenWallet_;
        _registerInterface(OnApprove(this).onApprove.selector);
    }

    //////////////////////////////////////////
    //
    // OnApprove
    //
    //////////////////////////////////////////

    function onApprove(
        address owner,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        spender;
        data;
        IERC20(msg.sender).safeTransferFrom(owner, address(this), amount);
        return true;
    }

    ///////////////////////////////////
    //
    // helper
    //
    ///////////////////////////////////

    /// @dev claim token with ecdsa signature
    function claim(
        address token,
        address beneficiary,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) public {
        AirdropInfo memory d = AirdropInfo({
            token: token,
            beneficiary: beneficiary,
            amount: amount,
            nonce: nonce,
            chainID: block.chainid
        });

        // check owner approved the airdrop
        (bool success, bytes32 hash) = verifyAirdropInfo(d, signature);
        require(success, "invalid-signature");
        require(!claimed[hash], "already-claimed");

        // check token wallet balance and allowance
        address tokenWallet_ = tokenWallet;
        require(IERC20(token).allowance(tokenWallet_, address(this)) >= amount, "insufficient allowance");
        require(IERC20(token).balanceOf(tokenWallet_) >= amount, "insufficient balance");

        claimed[hash] = true;
        IERC20(token).safeTransferFrom(tokenWallet, beneficiary, amount);

        emit Claimed(token, beneficiary, amount, nonce);
    }

    /// @dev claim token with ecdsa signature
    function claims(
        address[] calldata tokens,
        address[] calldata beneficiaries,
        uint256[] calldata amounts,
        uint256[] calldata nonces,
        bytes[] calldata signatures
    ) external {
        uint256 n = tokens.length;
        require(n == beneficiaries.length, "invalid-length");
        require(n == amounts.length, "invalid-length");
        require(n == nonces.length, "invalid-length");
        require(n == signatures.length, "invalid-length");

        for (uint256 i = 0; i < n; i++) {
            claim(tokens[i], beneficiaries[i], amounts[i], nonces[i], signatures[i]);
        }
    }
}
