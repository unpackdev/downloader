// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "./ERC721Enumerable.sol";

import "./wstETHFarm.sol";
import "./OwnableMaster.sol";

contract wstETHManager is ERC721Enumerable, OwnableMaster, wstETHFarm {

    string public baseURI;
    string public baseExtension;

    // Tracks increment of keys
    uint256 public totalMinted;

    // Tracks reserved counter
    uint256 public totalReserved;

    // Tracks amount of reusable NFTs
    uint256 public availableNFTCount;

    // Maps access to wiseLendingNFT through farmNFT
    mapping(uint256 => uint256) public farmingKeys;

    // Tracks reusable wiseLendingNFTs after burn
    mapping(uint256 => uint256) public availableNFTs;

    // Tracks reserved NFTs mapped to address
    mapping(address => uint256) public reserved;

    modifier onlyKeyOwner(
        uint256 _keyId
    ) {
        if (isOwner(_keyId, msg.sender) == false) {
            revert InvalidOwner();
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _wiseLendingAddress,
        uint256 _collateralFactor
    )
        ERC721(
            _name,
            _symbol
        )
        OwnableMaster(
            msg.sender
        )
        wstETHFarm(
            _wiseLendingAddress,
            _collateralFactor
        )
    {
        baseURI = _initBaseURI;
    }

    function _incrementReserved()
        internal
        returns (uint256)
    {
        return ++totalReserved;
    }

    function changeMinDeposit(
        uint256 _newMinDeposit
    )
        external
        onlyMaster
    {
        minDepositUsdAmount = _newMinDeposit;

        emit MinDepositChange(
            _newMinDeposit,
            block.timestamp
        );
    }

    function _getNextReserveKey()
        internal
        returns (uint256)
    {
        return totalMinted + _incrementReserved();
    }

    function _reserveKey(
        address _userAddress,
        uint256 _wiseLendingNFT
    )
        internal
        returns (uint256)
    {
        if (reserved[_userAddress] > 0) {
            revert AlreadyReserved();
        }

        uint256 keyId = _getNextReserveKey();

        reserved[_userAddress] = keyId;
        farmingKeys[keyId] = _wiseLendingNFT;

        return keyId;
    }

    function getMinAmountOut(
        uint256 _keyId,
        uint256 _slippage
    )
        external
        view
        returns (uint256)
    {
        uint256 collateral = _getPostionCollateralToken(
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
    function shutdownFarm(
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
            wiseLendingNFT,
            _amount,
            _leverage
        );

        uint256 keyId = _reserveKey(
            msg.sender,
            wiseLendingNFT
        );

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
            wiseLendingNFT,
            msg.value,
            _leverage
        );

        uint256 keyId = _reserveKey(
            msg.sender,
            wiseLendingNFT
        );

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
            uint256 nftId = POSITION_NFT.mintPositionForUser(
                address(this)
            );

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

        if (reserved[msg.sender] == _keyId) {
            reserved[msg.sender] = 0;
        } else {
            _burn(
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

    function isOwner(
        uint256 _keyId,
        address _owner
    )
        public
        view
        returns (bool)
    {
        if (reserved[_owner] == _keyId) {
            return true;
        }

        if (ownerOf(_keyId) == _owner) {
            return true;
        }

        return false;
    }

    function _mintKeyForUser(
        uint256 _keyId,
        address _userAddress
    )
        internal
        returns (uint256)
    {
        if (_keyId == 0) {
            revert InvalidKey();
        }

        delete reserved[
            _userAddress
        ];

        _mint(
            _userAddress,
            _keyId
        );

        totalMinted++;
        totalReserved--;

        return _keyId;
    }

    function approveMint(
        address _spender,
        uint256 _keyId
    )
        external
    {
        if (reserved[msg.sender] == _keyId) {
            _mintKeyForUser(
                _keyId,
                msg.sender
            );
        }

        approve(
            _spender,
            _keyId
        );
    }

    function mintReserved()
        external
        returns (uint256)
    {
        return _mintKeyForUser(
            reserved[
                msg.sender
            ],
            msg.sender
        );
    }

    /**
     * @dev Returns positions of owner
     */
    function walletOfOwner(
        address _owner
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256 reservedId = reserved[
            _owner
        ];

        uint256 ownerTokenCount = balanceOf(
            _owner
        );

        uint256 reservedCount;

        if (reservedId > 0) {
            reservedCount = 1;
        }

        uint256[] memory tokenIds = new uint256[](
            ownerTokenCount + reservedCount
        );

        uint256 i;

        for (i; i < ownerTokenCount; ++i) {
            tokenIds[i] = tokenOfOwnerByIndex(
                _owner,
                i
            );
        }

        if (reservedId > 0) {
            tokenIds[i] = reservedId;
        }

        return tokenIds;
    }

    /**
     * @dev Allows to update base target for MetaData.
     */
    function setBaseURI(
        string memory _newBaseURI
    )
        external
        onlyMaster
    {
        baseURI = _newBaseURI;

        emit BaseUrlChange(
            _newBaseURI,
            block.timestamp
        );
    }

    function setBaseExtension(
        string memory _newBaseExtension
    )
        external
        onlyMaster
    {
        baseExtension = _newBaseExtension;

        emit BaseExtensionChange(
            _newBaseExtension,
            block.timestamp
        );
    }

    /**
     * @dev Returns path to MetaData URI
     */
    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId) == true,
            "wstETHManager: WRONG_TOKEN"
        );

        string memory currentBaseURI = baseURI;

        if (bytes(currentBaseURI).length == 0) {
            return "";
        }

        return string(
            abi.encodePacked(
                currentBaseURI,
                _toString(_tokenId),
                baseExtension
            )
        );
    }

    /**
     * @dev Converts tokenId uint to string.
     */
    function _toString(
        uint256 _tokenId
    )
        internal
        pure
        returns (string memory str)
    {
        if (_tokenId == 0) {
            return "0";
        }

        uint256 j = _tokenId;
        uint256 length;

        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(
            length
        );

        uint256 k = length;
        j = _tokenId;

        while (j != 0) {
            bstr[--k] = bytes1(
                uint8(
                    48 + j % 10
                )
            );
            j /= 10;
        }

        str = string(
            bstr
        );
    }
}
