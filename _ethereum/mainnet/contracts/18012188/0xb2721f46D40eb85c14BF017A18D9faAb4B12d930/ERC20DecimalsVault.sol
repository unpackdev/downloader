// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ERC20DefaultVault.sol";

contract ERC20DecimalsVault is ERC20DefaultVault, Ownable {
    using SafeERC20 for ERC20Burnable;

    struct Decimals {
        uint128 sourceChain;
        uint128 destinationChain;
    }

    // assetId => destinationChainId => decimals
    mapping(bytes32 => mapping(uint256 => Decimals)) public decimals;

    event DecimalsChanged(
        bytes32 indexed _assetId,
        uint256 indexed _destinationChainId,
        uint256 _sourceDecimals,
        uint256 _destinationDecimals
    );

    constructor(
        address _bridge,
        bytes32[] memory _assetIds,
        address[] memory _tokenAddresses,
        address[] memory _burnListAddresses
    )
        ERC20DefaultVault(_bridge, _assetIds, _tokenAddresses, _burnListAddresses)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function setTokenDecimals(
        bytes32 _assetId,
        uint256 _destinationChainId,
        uint256 _sourceDecimals,
        uint256 _destinationDecimals
    ) external onlyOwner {
        require(_sourceDecimals != 0, "Decimals cannot be 0");
        require(_destinationDecimals != 0, "Decimals cannot be 0");

        decimals[_assetId][_destinationChainId] = Decimals({
            sourceChain: uint128(_sourceDecimals),
            destinationChain: uint128(_destinationDecimals)
        });

        emit DecimalsChanged(_assetId, _destinationChainId, _sourceDecimals, _destinationDecimals);
    }

    function lock(
        bytes32 _assetId,
        uint8 _destinationChainId,
        uint64 _depositCount,
        address _user,
        bytes calldata _data
    ) external payable virtual override onlyBridge {
        bytes memory recipientAddress;

        (uint256 amount, uint256 recipientAddressLength) = abi.decode(_data, (uint256, uint256));
        recipientAddress = bytes(_data[64:64 + recipientAddressLength]);

        address tokenAddress = assetIdToTokenAddress[_assetId];
        require(tokenAllowlist[tokenAddress], "Vault: token is not in the allowlist");

        if (tokenBurnList[tokenAddress]) {
            // burn on destination chain
            ERC20Burnable(tokenAddress).burnFrom(_user, amount);
        } else {
            // lock on source chain
            ERC20Burnable(tokenAddress).safeTransferFrom(_user, address(this), amount);
        }

        // Format amount based on the difference in the decimals
        // The formatted amunt would be reported by the observers on the destination chain through the LockRecord
        Decimals memory tokenDecimals = decimals[_assetId][_destinationChainId];
        require(tokenDecimals.sourceChain > 0, "Vault: Decimals not added");

        if (tokenDecimals.sourceChain > tokenDecimals.destinationChain) {
            uint256 difference = tokenDecimals.sourceChain - tokenDecimals.destinationChain;
            amount = amount / 10**difference;
            require(amount > 0, "Vault: Insufficient amount");
        } else if (tokenDecimals.sourceChain < tokenDecimals.destinationChain) {
            uint256 difference = tokenDecimals.destinationChain - tokenDecimals.sourceChain;
            amount = amount * 10**difference;
        }

        lockRecords[_destinationChainId][_depositCount] = LockRecord(
            tokenAddress,
            _destinationChainId,
            _assetId,
            recipientAddress,
            _user,
            amount
        );
    }
}
