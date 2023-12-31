// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract CryptBartex is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint public totalBartexed;
    uint public bartexTime;
    uint internal allNFTs;
    uint internal allTokens;
    uint internal allNatives;
    uint internal companyCommission;
    uint internal companyProfit;

    struct Bartex {
        uint256 id;
        address proposer;
        address accepter;
        bool allowedToExchange;
        uint256[] itemProposerAcceptorIndex;
        uint256 remainingTime;
        uint8 status;
        uint8 assetTypeProvided;
        uint8 assetTypeRequired;
        bool proposerAcceptedEx;
        bool acceptorAcceptedEx;
        bool proposerCancelledEx;
        bool acceptorCancelledEx;
    }

    struct NFTDetails {
        address[] tokenAddresses;
        uint256[] tokenIds;
    }
    struct TokenDetails {
        address[] tokenAddresses;
        uint256[] amounts;
    }
    struct NativeDetails {
        uint256 amount;
    }

    enum BartexStatus {
        PROPOSED,
        ACCEPTED,
        REJECTED,
        EXCHANGED,
        CANCELLED,
        EXPIRED
    }
    enum AssetType {
        TOKEN,
        NFT,
        NATIVE
    }

    mapping(uint => Bartex) public allBartexs;
    mapping(uint => NFTDetails) internal allNFTsBartexed;
    mapping(uint => TokenDetails) internal allTokensBartexed;
    mapping(uint => NativeDetails) internal allNativesBartexed;
    mapping(address => uint256[]) internal myBartex;

    /**
     * @dev bartexExists check if the bartex exists
     * @param id Bartex id
     */

    function bartexExists(uint id) private view {
        require(id < totalBartexed, "BNE");
    }

    /**
     * @dev zeroAddress check if the address is valid
     * @param _address Address to check
     */

    function zeroAddress(address _address) private pure {
        require(_address != address(0), "Invalid address");
    }

    /**
     * @dev zeroAddresses check if the addresses are valid
     * @param _address Addresses to check
     */

    function zeroAddresses(address[] memory _address) private pure {
        for (uint i = 0; i < _address.length; i++) {
            require(_address[i] != address(0), "Invalid address");
        }
    }

    /**
     * @dev onlyAssetType check if the asset type is valid
     * @param _assetType Asset type to check
     */

    function onlyAssetType(uint8 _assetType) private pure {
        require(
            _assetType == 0 || _assetType == 1 || _assetType == 2,
            "Invalid asset"
        );
    }

    /**
     * @dev bothParties check if the user is valid
     * @param _bartexId Bartex id
     */

    function bothParties(uint _bartexId) private view {
        require(
            allBartexs[_bartexId].proposer == msg.sender ||
                allBartexs[_bartexId].accepter == msg.sender,
            "Invalid user"
        );
    }

    /**
     * @dev onlyArrayLengthProvided check if the array length is valid
     * @param _providedTokenAddresses provided token addresses
     * @param _tokenProvidedAmounts  provided token amounts
     * @param _assetTypeProvided asset type provided
     */

    function onlyArrayLengthProvided(
        address[] memory _providedTokenAddresses,
        uint256[] memory _tokenProvidedAmounts,
        uint8 _assetTypeProvided
    ) private pure {
        if (_assetTypeProvided != uint8(AssetType.NATIVE)) {
            require(_tokenProvidedAmounts.length > 0, "Invalid array length");
            require(_providedTokenAddresses.length > 0, "Invalid array length");
            require(
                _providedTokenAddresses.length == _tokenProvidedAmounts.length,
                "Invalid array length"
            );
        } else {
            require(_tokenProvidedAmounts.length == 1, "Invalid array length");
        }
    }

    /**
     * @dev onlyArrayLengthRequired check if the array length is valid
     * @param _requiredTokenAddresses required token addresses
     * @param _tokenRequiredAmounts required token amounts
     */

    function onlyArrayLengthRequired(
        address[] memory _requiredTokenAddresses,
        uint256[] memory _tokenRequiredAmounts
    ) private pure {
        require(_tokenRequiredAmounts.length > 0, "Invalid array length");
        require(_requiredTokenAddresses.length > 0, "Invalid array length");
        require(
            _requiredTokenAddresses.length == _tokenRequiredAmounts.length,
            "Invalid array length"
        );
    }

    event BartexProposalCreated(
        address proposer,
        address accepter,
        uint256 bartexId
    );
    event BartexProposalAccepted(address accepter, uint256 bartexId);
    event BartexRejected(address rejecter, uint256 bartexId);
    event BartexExchanged(address proposer, address accepter, uint256 bartexId);
    event BartexExchangedCancelled(
        address proposer,
        address accepter,
        uint256 bartexId
    );
    event Withdrawn(address withdrawer, uint256 time);

    /**
     * @dev Initializer for the presale contract
     */
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        companyCommission = 0 ether;
        bartexTime = 7 days;
    }

    /**
     * @dev proposeForNativeBartex create a bartex for native
     * @param _acceptor acceptor address
     * @param _providedTokenAddresses provided token addresses
     * @param tokenProvidedAmounts provided token amounts
     * @param _tokenRequiredAmount required token amount
     * @param _assetTypeProvided asset type provided
     */

    function proposeForNativeBartex(
        address _acceptor,
        address[] memory _providedTokenAddresses,
        uint256[] memory tokenProvidedAmounts,
        uint256 _tokenRequiredAmount,
        uint8 _assetTypeProvided
    ) external payable nonReentrant {
        zeroAddress(_acceptor);
        zeroAddresses(_providedTokenAddresses);
        onlyArrayLengthProvided(
            _providedTokenAddresses,
            tokenProvidedAmounts,
            _assetTypeProvided
        );
        onlyAssetType(_assetTypeProvided);
        require(_assetTypeProvided != uint8(AssetType.NATIVE), "not allowed");
        uint256 assetProposer = getProvidedAssetDetails(
            _providedTokenAddresses,
            tokenProvidedAmounts,
            _assetTypeProvided
        );
        allNativesBartexed[allNatives] = NativeDetails(_tokenRequiredAmount);

        allBartexs[totalBartexed] = createBartex(
            _acceptor,
            assetProposer,
            allNatives,
            _assetTypeProvided,
            uint8(AssetType.NATIVE)
        );

        myBartex[msg.sender].push(totalBartexed);
        myBartex[_acceptor].push(totalBartexed);
        allNatives++;
        totalBartexed++;
        emit BartexProposalCreated(msg.sender, _acceptor, totalBartexed);
    }

    /**
     * @dev proposeForTokenBartex create a bartex for token
     * @param _acceptor acceptor address
     * @param _providedTokenAddresses provided token addresses
     * @param _tokenProvidedAmounts provided token amounts
     * @param _requiredTokenAddresses required token addresses
     * @param _tokenRequiredAmounts required token amounts
     * @param _assetTypeProvided asset type provided
     */

    function proposeForTokenBartex(
        address _acceptor,
        address[] memory _providedTokenAddresses,
        uint256[] memory _tokenProvidedAmounts,
        address[] memory _requiredTokenAddresses,
        uint256[] memory _tokenRequiredAmounts,
        uint8 _assetTypeProvided
    ) external payable nonReentrant {
        zeroAddress(_acceptor);
        zeroAddresses(_providedTokenAddresses);
        onlyArrayLengthProvided(
            _providedTokenAddresses,
            _tokenProvidedAmounts,
            _assetTypeProvided
        );
        onlyArrayLengthRequired(_requiredTokenAddresses, _tokenRequiredAmounts);
        onlyAssetType(_assetTypeProvided);
        uint256 assetProposer = getProvidedAssetDetails(
            _providedTokenAddresses,
            _tokenProvidedAmounts,
            _assetTypeProvided
        );
        allTokensBartexed[allTokens] = TokenDetails(
            _requiredTokenAddresses,
            _tokenRequiredAmounts
        );

        allBartexs[totalBartexed] = createBartex(
            _acceptor,
            assetProposer,
            allTokens,
            _assetTypeProvided,
            uint8(AssetType.TOKEN)
        );

        myBartex[msg.sender].push(totalBartexed);
        myBartex[_acceptor].push(totalBartexed);
        allTokens++;
        totalBartexed++;
        emit BartexProposalCreated(msg.sender, _acceptor, totalBartexed);
    }

    /**
     * @dev proposeForNFTBartex create a bartex for nft
     * @param _acceptor acceptor address
     * @param _providedTokenAddresses provided token addresses
     * @param _tokenProvidedAmounts provided token amounts
     * @param _requiredTokenAddresses required token addresses
     * @param _tokenRequiredAmounts required token amounts
     * @param _assetTypeProvided asset type provided
     */

    function proposeForNFTBartex(
        address _acceptor,
        address[] memory _providedTokenAddresses,
        uint256[] memory _tokenProvidedAmounts,
        address[] memory _requiredTokenAddresses,
        uint256[] memory _tokenRequiredAmounts,
        uint8 _assetTypeProvided
    ) external payable nonReentrant {
        zeroAddress(_acceptor);
        zeroAddresses(_providedTokenAddresses);
        onlyArrayLengthProvided(
            _providedTokenAddresses,
            _tokenProvidedAmounts,
            _assetTypeProvided
        );
        onlyArrayLengthRequired(_requiredTokenAddresses, _tokenRequiredAmounts);
        onlyAssetType(_assetTypeProvided);
        uint256 assetProposer = getProvidedAssetDetails(
            _providedTokenAddresses,
            _tokenProvidedAmounts,
            _assetTypeProvided
        );
        allNFTsBartexed[allNFTs] = NFTDetails(
            _requiredTokenAddresses,
            _tokenRequiredAmounts
        );

        allBartexs[totalBartexed] = createBartex(
            _acceptor,
            assetProposer,
            allNFTs,
            _assetTypeProvided,
            uint8(AssetType.NFT)
        );

        myBartex[msg.sender].push(totalBartexed);
        myBartex[_acceptor].push(totalBartexed);
        allNFTs++;
        totalBartexed++;
        emit BartexProposalCreated(msg.sender, _acceptor, totalBartexed);
    }

    /**
     * @dev createBartex create a bartex
     * @param _acceptor acceptor address
     * @param _providedAsset provided asset
     * @param _requiredAsset required asset
     * @param _assetTypeProvided asset type provided
     * @param _assetTypeRequired asset type required
     */

    function createBartex(
        address _acceptor,
        uint256 _providedAsset,
        uint256 _requiredAsset,
        uint8 _assetTypeProvided,
        uint8 _assetTypeRequired
    ) internal view returns (Bartex memory) {
        uint256[] memory indexes = new uint256[](2);
        indexes[0] = _providedAsset;
        indexes[1] = _requiredAsset;

        Bartex memory barter = Bartex(
            totalBartexed,
            msg.sender,
            _acceptor,
            false,
            indexes,
            0,
            uint8(BartexStatus.PROPOSED),
            uint8(_assetTypeProvided),
            _assetTypeRequired,
            false,
            false,
            false,
            false
        );
        return barter;
    }

    /**
     * @dev acceptBartex accept a bartex
     * @param _bartexId Bartex id
     */

    function acceptBartex(uint _bartexId) external payable {
        bartexExists(_bartexId);
        uint256 index = allBartexs[_bartexId].itemProposerAcceptorIndex[1];

        require(
            allBartexs[_bartexId].accepter == msg.sender,
            "Invalid accepter"
        );
        require(
            allBartexs[_bartexId].status == uint8(BartexStatus.PROPOSED),
            "Invalid status"
        );
        onlyAssetType(allBartexs[_bartexId].assetTypeRequired);

        if (allBartexs[_bartexId].assetTypeRequired == uint8(AssetType.TOKEN)) {
            TokenDetails memory _token = allTokensBartexed[index];
            checkTokenProvidedAmount(_token.amounts);
            checkAllowance(_token.tokenAddresses, _token.amounts);
            require(
                transferToken(
                    _token.tokenAddresses,
                    msg.sender,
                    address(this),
                    _token.amounts
                ),
                "Transfer failed"
            );
        } else if (
            allBartexs[_bartexId].assetTypeRequired == uint8(AssetType.NATIVE)
        ) {
            require(
                msg.value >= allNativesBartexed[index].amount,
                "Invalid amount"
            );
        } else if (
            allBartexs[_bartexId].assetTypeRequired == uint8(AssetType.NFT)
        ) {
            NFTDetails memory _nft = allNFTsBartexed[index];
            ownerOfNft(_nft.tokenAddresses, _nft.tokenIds);
            getApprovedNFT(_nft.tokenAddresses, _nft.tokenIds);
            transferNFTs(
                _nft.tokenAddresses,
                address(this),
                msg.sender,
                _nft.tokenIds
            );
        }

        allBartexs[_bartexId].status = uint8(BartexStatus.ACCEPTED);
        allBartexs[_bartexId].allowedToExchange = true;
        allBartexs[_bartexId].remainingTime = block.timestamp + bartexTime;
        emit BartexProposalAccepted(msg.sender, _bartexId);
    }

    /**
     * @dev rejectOrWithdrawBartex reject or withdraw a bartex
     * @param _bartexId Bartex id
     */

    function rejectOrWithdrawBartex(uint _bartexId) external nonReentrant {
        bothParties(_bartexId);
        bartexExists(_bartexId);
        require(
            allBartexs[_bartexId].status == uint8(BartexStatus.PROPOSED),
            "Invalid status"
        );
        allBartexs[_bartexId].status = uint8(BartexStatus.REJECTED);
        uint proposerIndex = allBartexs[_bartexId].itemProposerAcceptorIndex[0];

        address proposer = allBartexs[_bartexId].proposer;
        if (allBartexs[_bartexId].assetTypeProvided == uint8(AssetType.TOKEN)) {
            TokenDetails memory _token = getToken(proposerIndex);
            transferToken(
                _token.tokenAddresses,
                address(this),
                proposer,
                _token.amounts
            );
        } else if (
            allBartexs[_bartexId].assetTypeProvided == uint8(AssetType.NATIVE)
        ) {
            NativeDetails memory _native = getNative(proposerIndex);
            transferNative(proposer, _native.amount);
        } else if (
            allBartexs[_bartexId].assetTypeProvided == uint8(AssetType.NFT)
        ) {
            NFTDetails memory _nft = getNFT(proposerIndex);
            require(
                transferNFTs(
                    _nft.tokenAddresses,
                    proposer,
                    address(this),
                    _nft.tokenIds
                ),
                "transfer fail"
            );
        }

        emit BartexRejected(msg.sender, _bartexId);
    }

    /**
     * @dev acceptBartexExchange accept a bartex exchange
     * @param _bartexId Bartex id
     */

    function acceptBartexExchange(
        uint _bartexId
    ) external payable nonReentrant {
        bothParties(_bartexId);
        bartexExists(_bartexId);
        Bartex memory bartex = allBartexs[_bartexId];
        require(bartex.remainingTime >= block.timestamp, "Expired");
        require(msg.value >= companyCommission, "Not enough commission");
        companyProfit += msg.value;

        require(bartex.allowedToExchange, "Not allowed to exchange");
        if (msg.sender == bartex.proposer) {
            allBartexs[_bartexId].proposerAcceptedEx = true;
        } else if (msg.sender == bartex.accepter) {
            allBartexs[_bartexId].acceptorAcceptedEx = true;
        }

        if (
            allBartexs[_bartexId].proposerAcceptedEx &&
            allBartexs[_bartexId].acceptorAcceptedEx
        ) {
            uint256 proposerAssetIndex = bartex.itemProposerAcceptorIndex[0];
            uint256 accepterAssetIndex = bartex.itemProposerAcceptorIndex[1];

            if (bartex.assetTypeProvided == uint8(AssetType.TOKEN)) {
                TokenDetails memory _token = getToken(proposerAssetIndex);

                transferToken(
                    _token.tokenAddresses,
                    address(this),
                    bartex.accepter,
                    _token.amounts
                );
            } else if (bartex.assetTypeProvided == uint8(AssetType.NATIVE)) {
                NativeDetails memory _native = getNative(proposerAssetIndex);
                transferNative(bartex.accepter, _native.amount);
            } else if (bartex.assetTypeProvided == uint8(AssetType.NFT)) {
                NFTDetails memory _nft = getNFT(proposerAssetIndex);
                require(
                    transferNFTs(
                        _nft.tokenAddresses,
                        bartex.accepter,
                        address(this),
                        _nft.tokenIds
                    ),
                    "Transfer fail"
                );
            }

            if (bartex.assetTypeRequired == uint8(AssetType.TOKEN)) {
                TokenDetails memory _token = getToken(accepterAssetIndex);

                require(
                    transferToken(
                        _token.tokenAddresses,
                        address(this),
                        bartex.proposer,
                        _token.amounts
                    ),
                    "Transfer fail"
                );
            } else if (bartex.assetTypeRequired == uint8(AssetType.NATIVE)) {
                NativeDetails memory _native = getNative(accepterAssetIndex);

                transferNative(bartex.proposer, _native.amount);
            } else if (bartex.assetTypeRequired == uint8(AssetType.NFT)) {
                NFTDetails memory _nft = getNFT(accepterAssetIndex);

                require(
                    transferNFTs(
                        _nft.tokenAddresses,
                        bartex.proposer,
                        address(this),
                        _nft.tokenIds
                    ),
                    "Transfer fail"
                );
            }

            allBartexs[_bartexId].status = uint8(BartexStatus.EXCHANGED);
            emit BartexExchanged(bartex.proposer, bartex.accepter, _bartexId);
        }
    }

    /**
     * @dev cancelBartexExchange cancel a bartex exchange
     * @param _bartexId Bartex id
     */

    function cancelBartexExchange(
        uint _bartexId
    ) external payable nonReentrant {
        bothParties(_bartexId);
        bartexExists(_bartexId);
        Bartex memory bartex = allBartexs[_bartexId];
        require(bartex.remainingTime >= block.timestamp, "Expired");
        require(msg.value >= companyCommission, "Not enough commission");
        companyProfit += msg.value;

        require(bartex.allowedToExchange, "Not allowed to exchange");
        if (msg.sender == bartex.proposer) {
            allBartexs[_bartexId].proposerCancelledEx = true;
        } else if (msg.sender == bartex.accepter) {
            allBartexs[_bartexId].acceptorCancelledEx = true;
        }

        if (
            allBartexs[_bartexId].proposerCancelledEx &&
            allBartexs[_bartexId].acceptorCancelledEx
        ) {
            uint256 proposerAssetIndex = bartex.itemProposerAcceptorIndex[0];
            uint256 accepterAssetIndex = bartex.itemProposerAcceptorIndex[1];
            if (bartex.assetTypeProvided == uint8(AssetType.TOKEN)) {
                TokenDetails memory _token = getToken(proposerAssetIndex);
                transferToken(
                    _token.tokenAddresses,
                    address(this),
                    bartex.proposer,
                    _token.amounts
                );
            } else if (bartex.assetTypeProvided == uint8(AssetType.NATIVE)) {
                NativeDetails memory _native = getNative(proposerAssetIndex);
                transferNative(bartex.proposer, _native.amount);
            } else if (bartex.assetTypeProvided == uint8(AssetType.NFT)) {
                NFTDetails memory _nft = getNFT(proposerAssetIndex);
                require(
                    transferNFTs(
                        _nft.tokenAddresses,
                        bartex.proposer,
                        address(this),
                        _nft.tokenIds
                    ),
                    "Transfer failed"
                );
            }

            if (bartex.assetTypeRequired == uint8(AssetType.TOKEN)) {
                TokenDetails memory _token = getToken(accepterAssetIndex);
                transferToken(
                    _token.tokenAddresses,
                    address(this),
                    bartex.accepter,
                    _token.amounts
                );
            } else if (bartex.assetTypeRequired == uint8(AssetType.NATIVE)) {
                NativeDetails memory _native = getNative(accepterAssetIndex);

                transferNative(bartex.accepter, _native.amount);
            } else if (bartex.assetTypeRequired == uint8(AssetType.NFT)) {
                NFTDetails memory _nft = getNFT(accepterAssetIndex);
                require(
                    transferNFTs(
                        _nft.tokenAddresses,
                        bartex.accepter,
                        address(this),
                        _nft.tokenIds
                    ),
                    "Transfer failed"
                );
            }

            allBartexs[_bartexId].status = uint8(BartexStatus.CANCELLED);
            allBartexs[_bartexId].allowedToExchange = false;
            emit BartexExchangedCancelled(
                bartex.proposer,
                bartex.accepter,
                _bartexId
            );
        }
    }

    /**
     * @dev withdrawAssets withdraw the your assets after the bartex time is over
     * @param _bartexId Bartex id
     */

    function withdrawAssets(uint _bartexId) public payable nonReentrant {
        bothParties(_bartexId);
        bartexExists(_bartexId);
        Bartex memory bartex = allBartexs[_bartexId];
        require(bartex.remainingTime < block.timestamp, "Withdraw Not Allowed");
        require(msg.value >= companyCommission, "Not enough commission");
        companyProfit += msg.value;
        require(bartex.allowedToExchange, "Not allowed to exchange");

        if (msg.sender == bartex.proposer) {
            uint256 proposerAssetIndex = bartex.itemProposerAcceptorIndex[0];
            if (bartex.assetTypeProvided == uint8(AssetType.TOKEN)) {
                TokenDetails memory _token = getToken(proposerAssetIndex);
                transferToken(
                    _token.tokenAddresses,
                    address(this),
                    bartex.proposer,
                    _token.amounts
                );
            } else if (bartex.assetTypeProvided == uint8(AssetType.NATIVE)) {
                NativeDetails memory _native = getNative(proposerAssetIndex);
                transferNative(bartex.proposer, _native.amount);
            } else if (bartex.assetTypeProvided == uint8(AssetType.NFT)) {
                NFTDetails memory _nft = getNFT(proposerAssetIndex);
                require(
                    transferNFTs(
                        _nft.tokenAddresses,
                        bartex.proposer,
                        address(this),
                        _nft.tokenIds
                    ),
                    "Transfer failed"
                );
            }
        } else if (msg.sender == bartex.accepter) {
            uint256 accepterAssetIndex = bartex.itemProposerAcceptorIndex[1];
            if (bartex.assetTypeRequired == uint8(AssetType.TOKEN)) {
                TokenDetails memory _token = getToken(accepterAssetIndex);
                transferToken(
                    _token.tokenAddresses,
                    address(this),
                    bartex.accepter,
                    _token.amounts
                );
            } else if (bartex.assetTypeRequired == uint8(AssetType.NATIVE)) {
                NativeDetails memory _native = getNative(accepterAssetIndex);

                transferNative(bartex.accepter, _native.amount);
            } else if (bartex.assetTypeRequired == uint8(AssetType.NFT)) {
                NFTDetails memory _nft = getNFT(accepterAssetIndex);
                require(
                    transferNFTs(
                        _nft.tokenAddresses,
                        bartex.accepter,
                        address(this),
                        _nft.tokenIds
                    ),
                    "Transfer failed"
                );
            }
        }
        allBartexs[_bartexId].status = uint8(BartexStatus.EXPIRED);
        emit Withdrawn(msg.sender, block.timestamp);
    }

    /**
     * @dev getProvidedAssetDetails get the provided asset details
     * @param _providedTokenAddresses provided token addresses
     * @param _tokenProvidedAmounts provided token amounts
     * @param _assetProvidedType asset type provided
     */

    function getProvidedAssetDetails(
        address[] memory _providedTokenAddresses,
        uint256[] memory _tokenProvidedAmounts,
        uint8 _assetProvidedType
    ) internal returns (uint256) {
        uint256 index;
        if (_assetProvidedType == uint(AssetType.TOKEN)) {
            checkTokenProvidedAmount(_tokenProvidedAmounts);
            checkAllowance(_providedTokenAddresses, _tokenProvidedAmounts);
            transferToken(
                _providedTokenAddresses,
                msg.sender,
                address(this),
                _tokenProvidedAmounts
            );
            allTokensBartexed[allTokens] = TokenDetails(
                _providedTokenAddresses,
                _tokenProvidedAmounts
            );
            allTokens++;
            index = allTokens - 1;
        } else if (_assetProvidedType == uint(AssetType.NATIVE)) {
            require(msg.value >= _tokenProvidedAmounts[0], "Invalid amount");
            allNativesBartexed[allNatives] = NativeDetails(
                _tokenProvidedAmounts[0]
            );
            allNatives++;
            index = allNatives - 1;
        } else if (_assetProvidedType == uint(AssetType.NFT)) {
            ownerOfNft(_providedTokenAddresses, _tokenProvidedAmounts);
            getApprovedNFT(_providedTokenAddresses, _tokenProvidedAmounts);
            transferNFTs(
                _providedTokenAddresses,
                address(this),
                msg.sender,
                _tokenProvidedAmounts
            );
            allNFTsBartexed[allNFTs] = NFTDetails(
                _providedTokenAddresses,
                _tokenProvidedAmounts
            );
            allNFTs++;
            index = allNFTs - 1;
        }
        return index;
    }

    /**
     * @dev transferToken transfer token
     * @param _tokenAddresses token addresses
     * @param _from from address
     * @param _to to address
     * @param _amounts token amounts
     */

    function transferToken(
        address[] memory _tokenAddresses,
        address _from,
        address _to,
        uint[] memory _amounts
    ) internal returns (bool) {
        for (uint i = 0; i < _amounts.length; i++) {
            IERC20Upgradeable token = IERC20Upgradeable(_tokenAddresses[i]);
            require(_amounts[i] <= token.balanceOf(_from), "No Funds");
            if (_from == address(this)) {
                require(token.transfer(_to, _amounts[i]), "trx fail");
            } else {
                require(
                    token.transferFrom(_from, _to, _amounts[i]),
                    "trx fail"
                );
            }
        }
        return true;
    }

    /**
     * @dev transferNative transfer native
     * @param _to to address
     * @param _amount amount
     */

    function transferNative(address _to, uint _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Amount not sent");
    }

    /**
     * @dev transferNFTs transfer nfts
     * @param _tokenAddresses token addresses
     * @param _to to address
     * @param _from from address
     * @param _tokenIds token ids
     */
    function transferNFTs(
        address[] memory _tokenAddresses,
        address _to,
        address _from,
        uint[] memory _tokenIds
    ) internal returns (bool) {
        for (uint i = 0; i < _tokenIds.length; i++) {
            IERC721Upgradeable token = IERC721Upgradeable(_tokenAddresses[i]);
            require(token.ownerOf(_tokenIds[i]) == _from, "not owner");
            token.transferFrom(_from, _to, _tokenIds[i]);
        }
        return true;
    }

    /**
     * @dev ownerOfNft check if the owner of nft is valid
     * @param tokenAddresses token addresses
     * @param tokenIds token ids
     */

    function ownerOfNft(
        address[] memory tokenAddresses,
        uint256[] memory tokenIds
    ) internal view {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(
                IERC721Upgradeable(tokenAddresses[i]).ownerOf(tokenIds[i]) ==
                    msg.sender,
                "Invalid token owner"
            );
        }
    }

    /**
     * @dev getApprovedNFT check if the nft is approved
     * @param tokenAddresses token addresses
     * @param tokenId token ids
     */

    function getApprovedNFT(
        address[] memory tokenAddresses,
        uint[] memory tokenId
    ) internal view {
        for (uint i = 0; i < tokenId.length; i++) {
            require(
                IERC721Upgradeable(tokenAddresses[i]).getApproved(tokenId[i]) ==
                    address(this),
                "no approval"
            );
        }
    }

    /**
     * @dev checkAllowance check if the allowance is valid
     * @param _providedTokenAddresses provided token addresses
     * @param _tokenProvidedAmounts provided token amounts
     */

    function checkAllowance(
        address[] memory _providedTokenAddresses,
        uint256[] memory _tokenProvidedAmounts
    ) internal view {
        for (uint i = 0; i < _providedTokenAddresses.length; i++) {
            require(
                IERC20Upgradeable(_providedTokenAddresses[i]).allowance(
                    msg.sender,
                    address(this)
                ) >= _tokenProvidedAmounts[i],
                "Insufficient allowance"
            );
        }
    }

    /**
     * @dev checkTokenProvidedAmount check if the token amount is valid
     * @param _tokenProvidedAmounts provided token amounts
     */

    function checkTokenProvidedAmount(
        uint256[] memory _tokenProvidedAmounts
    ) internal pure {
        for (uint i = 0; i < _tokenProvidedAmounts.length; i++) {
            require(_tokenProvidedAmounts[i] > 0, "Invalid token amount");
        }
    }

    /**
     * @dev getMyBartexed get the bartexed
     * @param _address address
     */

    function getMyBartexed(
        address _address
    ) external view returns (uint256[] memory) {
        return myBartex[_address];
    }

    /**
     * @dev getAssets get the assets
     * @param _bartexId Bartex id
     */

    function getAssets(
        uint _bartexId
    ) external view returns (uint256[] memory) {
        return (allBartexs[_bartexId].itemProposerAcceptorIndex);
    }

    /**
     * @dev withdrawCommission widtdraw the company commission
     */

    function withdrawCommission() external onlyOwner nonReentrant {
        require(companyProfit > 0);
        uint amount = companyProfit;
        companyProfit = 0;
        transferNative(msg.sender, amount);
    }

    /**
     * @dev updateCompanyCommission update the company commission
     * @param _commission commission
     */

    function updateCompanyCommission(uint _commission) external onlyOwner {
        companyCommission = _commission;
    }

    /**
     * @dev getToken get token information
     * @param index token index
     */

    function getToken(uint256 index) public view returns (TokenDetails memory) {
        return allTokensBartexed[index];
    }

    /**
     * @dev getNative get native information
     * @param index native index
     */

    function getNative(
        uint256 index
    ) public view returns (NativeDetails memory) {
        return allNativesBartexed[index];
    }

    /**
     * @dev getNFT get nft information
     * @param index nft index
     */

    function getNFT(uint256 index) public view returns (NFTDetails memory) {
        return allNFTsBartexed[index];
    }

    /**
     * @dev getCompanyComission get the company commission
     */

    function getCompanyComission() public view returns (uint) {
        return companyCommission;
    }

    /**
     * @dev updateBartexTime update bartex time
     */

    function updateBartexTime(uint timeInSeconds) external onlyOwner {
        bartexTime = timeInSeconds;
    }

}
