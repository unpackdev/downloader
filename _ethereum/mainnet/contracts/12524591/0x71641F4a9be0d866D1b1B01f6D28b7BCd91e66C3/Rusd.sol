// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./ERC20Burnable.sol";
import "./IIncentive.sol";
import "./IRusd.sol";
import "./CoreRef.sol";

/// @title RUSD stablecoin
/// @author Ring Protocol
contract Rusd is IRusd, ERC20Burnable, CoreRef {

    /// @notice incentive contract, 0 address if N/A
    address public override incentiveContract;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    /// @notice Rusd token constructor
    /// @param core Ring Core address to reference
    constructor(address core) ERC20("Ring USD", "RUSD") CoreRef(core) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /// @param incentive the associated incentive contract
    function setIncentiveContract(address incentive)
        external
        override
        onlyGovernor
    {
        incentiveContract = incentive;
        emit IncentiveContractUpdate(incentive);
    }

    /// @notice mint RUSD tokens
    /// @param account the account to mint to
    /// @param amount the amount to mint
    function mint(address account, uint256 amount)
        external
        override
        onlyMinter
        whenNotPaused
    {
        _mint(account, amount);
        emit Minting(account, msg.sender, amount);
    }

    /// @notice burn RUSD tokens from caller
    /// @param amount the amount to burn
    function burn(uint256 amount) public override(IRusd, ERC20Burnable) {
        super.burn(amount);
        emit Burning(msg.sender, msg.sender, amount);
    }

    /// @notice burn RUSD tokens from specified account
    /// @param account the account to burn from
    /// @param amount the amount to burn
    function burnFrom(address account, uint256 amount)
        public
        override(IRusd, ERC20Burnable)
        onlyBurner
        whenNotPaused
    {
        _burn(account, amount);
        emit Burning(account, msg.sender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        super._transfer(sender, recipient, amount);
        if (incentiveContract != address(0)) {
            IIncentive(incentiveContract).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }
    }

    /// @notice permit spending of RUSD
    /// @param owner the RUSD holder
    /// @param spender the approved operator
    /// @param value the amount approved
    /// @param deadline the deadline after which the approval is no longer valid
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // solhint-disable-next-line not-rely-on-time
        require(deadline >= block.timestamp, "Ring: EXPIRED");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Ring: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}
