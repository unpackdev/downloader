// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20Reward.sol";
import "./Validate.sol";

/**
 * @dev Extension of {ERC20} that allows users to burn its token or burnFrom its allowance.
 */
contract ERC20Mintable is ERC20Reward {
    // keccak256('MintAllRewardBySig(uint8 signDomain,uint256 chainId,address contractAddress,uint256 fee,uint256 nonce)')
    bytes32 private constant _MINTALLREWARDBYSIG_TYPEHASH = 0xbde9ded4b0f17394af57db78b30f32f7ecfcc04693dd0e113fd2181ebbdd1142;

    event Mint(address indexed minter, address indexed _mintTo, uint256 _value);

    function __ERC20Mintable_init() internal onlyInitializing {
        __ERC20Mintable_init_unchained();
    }

    function __ERC20Mintable_init_unchained() internal onlyInitializing {}

    function mintAllReward() external {
        updateAccumulatedAmountPerShare();
        uint256 mintingAllowance = _getMintableAllowance(_msgSender());
        require(mintingAllowance > 0, 'ERC20Mintable: Minting allowance need to be greater than 0');
        _mint(_msgSender(), mintingAllowance);
    }

    function mintAllRewardBySig(
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(expiry >= block.timestamp, 'ERC20Mintable: Signature expired');

        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _MINTALLREWARDBYSIG_TYPEHASH,
                        GluwacoinModels.SigDomain.Mint,
                        block.chainid,
                        address(this),
                        fee,
                        nonce
                    )
                )
            ),
            v,
            r,
            s
        );
        _useNonce(signer, GluwacoinModels.SigDomain.Mint, nonce);

        updateAccumulatedAmountPerShare();
        uint256 mintingAllowance = _getMintableAllowance(signer);
        require(mintingAllowance > 0, 'ERC20Mintable: Minting allowance need to be greater than 0');
        _mint(signer, mintingAllowance);

        _collect(signer, fee, msg.sender);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        emit Mint(msg.sender, account, amount);
        for (uint256 i = _userInfo[account].debtCount; i > 0; ) {
            _userInfo[account].debt[i - 1] += amount;
            if (block.number > _userInfo[account].debtBlock[i - 1]) {
                break;
            }
            unchecked {
                --i;
            }
        }
        super._mint(account, amount);
    }

    uint256[50] private __gap;
}
