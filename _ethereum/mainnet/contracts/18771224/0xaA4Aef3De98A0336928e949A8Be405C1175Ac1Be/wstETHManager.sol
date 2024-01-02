// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

/**
 * @author Christoph Krpoun
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

import "./wstETHFarm.sol";
import "./OwnableMaster.sol";
import "./MinterReserver.sol";

/**
 * @dev The wstETH power farm is an automated leverage contract working as a
 * second layer for Wise lending. It needs to be registed inside the latter one
 * to have access to the pools. It uses BALANCER FLASHLOANS as well as CURVE POOLS and
 * the LIDO contracts for staked ETH and wrapped staked ETH.
 * The corresponding contract addresses can be found in {wstETHFarmDeclarations.sol}.
 *
 * It allows to open leverage positions with wrapped ETH in form of aave wrapped ETH.
 * For opening a position the user needs to have {_initalAmount} of ETH or WETH in the wallet.
 * A maximum of 15x leverage is possible. Once the user registers with its position NFT that
 * NFT is locked for ALL other interactions with wise lending as long as the positon is open!
 *
 * For more infos see {https://wisesoft.gitbook.io/wise/}
 */

contract wstETHManager is OwnableMaster, wstETHFarm, MinterReserver {

    /**
     * @dev Standard receive functions forwarding
     * directly send ETH to the master address.
     */
    receive()
        external
        payable
    {
        emit ETHReceived(
            msg.value,
            msg.sender
        );
    }

    constructor(
        address _wiseLendingAddress,
        uint256 _collateralFactor,
        address _powerFarmNFTs
    )
        OwnableMaster(
            msg.sender
        )
        MinterReserver(
            _powerFarmNFTs
        )
        wstETHFarmDeclarations(
            _wiseLendingAddress,
            _collateralFactor
        )
    {
    }

    function changeMinDeposit(
        uint256 _newMinDeposit
    )
        external
        onlyMaster
    {
        minDepositEthAmount = _newMinDeposit;

        emit MinDepositChange(
            _newMinDeposit,
            block.timestamp
        );
    }

    function getMinAmountOut(
        uint256 _keyId,
        uint256 _slippage
    )
        external
        view
        returns (uint256)
    {
        uint256 collateral = _getPostionCollateralTokenAmount(
            farmingKeys[_keyId]
        );

        uint256 amountStETH = WST_ETH.getStETHByWstETH(
            collateral
        );

        uint256 amountOut = CURVE.get_dy(
            1,
            0,
            amountStETH
        );

        return amountOut
            * _slippage
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev External function deactivating the power farm by
     * disableing the openPosition function. Allowing user
     * to manualy payback and withdraw.
     */
    function shutDownFarm(
        bool _state
    )
        external
        onlyMaster
    {
        isShutdown = _state;

        emit FarmStatus(
            _state,
            block.timestamp
        );
    }

    /**
     * @dev External set function to change referral address
     * for lido staking. Can only be called by master.
     */
    function changeRefAddress(
        address _newAddress
    )
        external
        onlyMaster
    {
        referralAddress = _newAddress;

        emit ReferralUpdate(
            _newAddress,
            block.timestamp
        );
    }

    function enterFarm(
        bool _isAave,
        uint256 _amount,
        uint256 _leverage
    )
        external
        isActive
        updatePools
        returns (uint256)
    {
        uint256 wiseLendingNFT = _getWiseLendingNFT();

        _safeTransferFrom(
            WETH_ADDRESS,
            msg.sender,
            address(this),
            _amount
        );

        _openPosition(
            _isAave,
            wiseLendingNFT,
            _amount,
            _leverage
        );

        uint256 keyId = _reserveKey(
            msg.sender,
            wiseLendingNFT
        );

        isAave[keyId] = _isAave;

        emit FarmEntry(
            keyId,
            wiseLendingNFT,
            _leverage,
            _amount,
            block.timestamp
        );

        return keyId;
    }

    function enterFarmETH(
        bool _isAave,
        uint256 _leverage
    )
        external
        payable
        isActive
        updatePools
        returns (uint256)
    {
        uint256 wiseLendingNFT = _getWiseLendingNFT();

        _wrapETH(
            msg.value
        );

        _openPosition(
            _isAave,
            wiseLendingNFT,
            msg.value,
            _leverage
        );

        uint256 keyId = _reserveKey(
            msg.sender,
            wiseLendingNFT
        );

        isAave[keyId] = _isAave;

        emit FarmEntry(
            keyId,
            wiseLendingNFT,
            _leverage,
            msg.value,
            block.timestamp
        );

        return keyId;
    }

    function _getWiseLendingNFT()
        internal
        returns (uint256)
    {
        if (availableNFTCount == 0) {

            uint256 nftId = POSITION_NFT.mintPosition();

            _registrationFarm(
                nftId
            );

            POSITION_NFT.approve(
                AAVE_HUB_ADDRESS,
                nftId
            );

            return nftId;
        }

        return availableNFTs[
            availableNFTCount--
        ];
    }

    function exitFarm(
        uint256 _keyId,
        uint256 _minOutAmount,
        bool _ethBack
    )
        external
        updatePools
        onlyKeyOwner(_keyId)
    {
        uint256 wiseLendingNFT = farmingKeys[
            _keyId
        ];

        delete farmingKeys[
            _keyId
        ];

        if (reservedKeys[msg.sender] == _keyId) {
            reservedKeys[msg.sender] = 0;
        } else {
            FARMS_NFTS.burnKey(
                _keyId
            );
        }

        emit FarmExit(
            _keyId,
            wiseLendingNFT,
            _minOutAmount,
            block.timestamp
        );

        availableNFTs[
            ++availableNFTCount
        ] = wiseLendingNFT;

        _closingPosition(
            isAave[_keyId],
            wiseLendingNFT,
            _minOutAmount,
            _ethBack
        );
    }

    function manuallyPaybackShares(
        uint256 _keyId,
        uint256 _paybackShares
    )
        external
        updatePools
    {
        _manuallyPaybackShares(
            farmingKeys[_keyId],
            _paybackShares
        );

        emit ManualPaybackShares(
            _keyId,
            farmingKeys[_keyId],
            _paybackShares,
            block.timestamp
        );
    }

    function manuallyWithdrawShares(
        uint256 _keyId,
        uint256 _withdrawShares
    )
        external
        updatePools
        onlyKeyOwner(_keyId)
    {
        _manuallyWithdrawShares(
            farmingKeys[_keyId],
            _withdrawShares
        );

        emit ManualWithdrawShares(
            _keyId,
            farmingKeys[_keyId],
            _withdrawShares,
            block.timestamp
        );
    }
}
