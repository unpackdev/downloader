/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IERC20.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./Math.sol";
import "./IGateway.sol";
import "./IPool.sol";
import "./INXMaster.sol";
import "./IDistributor.sol";
import "./IQuotationData.sol";
import "./AbstractDistributor.sol";
import "./IWNXMToken.sol";
import "./NexusHelper.sol";
import "./IUniswapV2Router02.sol";
import "./IExchangeAdapter.sol";
import "./IWETH.sol";

contract NexusDistributor is
    AbstractDistributor,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using Math for uint256;

    string public constant DEFAULT_BASE_URI =
        "https://brightunion.io/documents/nfts/nexus/cover.png";
    // @dev DEPRECATED
    uint256 public feePercentage;
    bool public buysAllowed;
    /*
    address where `buyCover` distributor fees and `ethOut` from `sellNXM` are sent. Controlled by Owner.
  */
    address payable public treasury;

    /*
    NexusMutual contracts
  */
    IGateway public gateway;
    IERC20Upgradeable public nxmToken;
    IWETH public wEthToken;
    INXMaster public master;
    IWNXMToken public wnxmToken;
    address public uniswapV2Adapter;
    address public uniswapV3Adapter;

    modifier onlyTokenApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "NexusDistributor: Not approved or owner"
        );
        _;
    }

    /**
     * @dev Standard pattern of constructing proxy contracts with the same signature as the constructor.
     */
    function __NexusDistributor_init(
        address _gatewayAddress,
        address _nxmTokenAddress,
        address _masterAddress,
        address _wnxmTokenAddress,
        address _wETHAddress,
        address payable _treasury,
        string memory _tokenName,
        string memory _tokenSymbol,
        address[] calldata _exchangeAdapters
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init(_tokenName, _tokenSymbol);

        _setBaseURI(DEFAULT_BASE_URI);
        buysAllowed = true;
        treasury = _treasury;
        gateway = IGateway(_gatewayAddress);
        nxmToken = IERC20Upgradeable(_nxmTokenAddress);
        wEthToken = IWETH(_wETHAddress);
        wnxmToken = IWNXMToken(_wnxmTokenAddress);
        master = INXMaster(_masterAddress);
        uniswapV2Adapter = _exchangeAdapters[0];
        uniswapV3Adapter = _exchangeAdapters[1];
    }

    function getCover(
        address _owner,
        uint256 _coverId,
        bool _isActive,
        uint256 _loopLimit
    ) external view returns (NexusHelper.Cover memory _cover) {
        uint256 limit;
        uint256 arraySize;
        if (_isActive == true) {
            uint256[] memory userCovers = IQuotationData(
                master.getLatestAddress("QD")
            ).getAllCoversOfUser(_owner);
            limit = userCovers.length.min(_loopLimit);
            arraySize = userCovers.length;
        } else {
            uint256 ownerBalance = balanceOf(_owner);
            limit = ownerBalance.min(_loopLimit);
            arraySize = ownerBalance;
        }

        NexusHelper.Cover[] memory covers = new NexusHelper.Cover[](arraySize);
        for (uint256 i = 0; i < limit; i++) {
            uint256 tokenId = _isActive == true
                ? i
                : tokenOfOwnerByIndex(_owner, i);

            NexusHelper.Cover memory cover;

            (
                cover.status,
                cover.coverAmount,
                cover.productId,
                cover.expiration,
                cover.contractAddress,
                cover.currency,
                cover.premium,
                cover.refAddress
            ) = gateway.getCover(tokenId);

            covers[i] = cover;
        }
        return covers.length > 0 ? covers[_coverId] : _cover;
    }

    // @dev buy cover for a coverable identified by its contractAddress
    // @param contractAddress contract address of coverable
    // @param coverAsset asset of the premium and of the sum assured.
    // @param sumAssured amount payable if claim is submitted and considered valid
    // @param amountOut amount of expected wNXM out after swap
    // @param coverType cover type dermining how the data parameter is decoded
    // @param maxPriceWithFee max price (including fee) to be spent on the cover.
    // @param data abi-encoded field with additional cover data fields
    function buyCover(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint256 amountOut,
        uint16 coverPeriod,
        uint8 coverType,
        uint256 maxPriceWithFee,
        bytes calldata data
    ) external payable nonReentrant {
        require(buysAllowed, "NexusDistributor: buys not allowed");

        // Buy wNXM with Ether or ERC20 asset
        (uint256 wNXMAmount, uint256 coverPriceNXM) = _buyWNXM(
            coverAsset,
            amountOut,
            maxPriceWithFee,
            data
        );

        // Unwrap wNXM
        wnxmToken.unwrap(wNXMAmount);

        require(
            nxmToken.balanceOf(address(this)) >= coverPriceNXM,
            "Distributor not enough NXM"
        );

        // approve gateway coverprice in NXM - this price is given by nexus quote API
        nxmToken.approve(address(gateway), coverPriceNXM);

        // Buy nexus cover with NXM
        // Balance of NXM after coverbuy is sent to treasury
        uint256 coverId = 1;
        gateway.buyCover(
            contractAddress,
            address(nxmToken),
            sumAssured,
            coverPeriod,
            IGateway.CoverType(coverType),
            data
        );

        // mint token using the coverId as a tokenId (guaranteed unique)
        _mint(_msgSender(), coverId);

        // Returning contract balance of NXM to treasury
        _transferAmdApprove(
            address(nxmToken),
            address(this),
            address(treasury)
        );

        // Returning contract balance  of buying asset to treasury
        _transferAmdApprove(
            address(coverAsset),
            address(this),
            address(treasury)
        );

        emit BuyCoverEvent(
            contractAddress,
            coverType,
            coverPeriod,
            coverAsset,
            sumAssured,
            maxPriceWithFee
        );
    }

    function _transferAmdApprove(
        address _asset,
        address _from,
        address _to
    ) internal {
        if (_asset == ETH && wEthToken.balanceOf(address(this)) > 0) {
            wEthToken.approve(_to, wEthToken.balanceOf(address(_to)));
            require(
                wEthToken.transfer(_to, wEthToken.balanceOf(address(_from))),
                "NexusDistributor : Weth tranfer failed"
            );
        } else if (IERC20Upgradeable(_asset).balanceOf(address(_from)) > 0) {
            SafeERC20Upgradeable.safeApprove(
                IERC20Upgradeable(_asset),
                _to,
                IERC20Upgradeable(_asset).balanceOf(_from)
            );
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(_asset),
                _to,
                IERC20Upgradeable(_asset).balanceOf(_from)
            );
        }
    }

    // @notice Internal logic to buy wNXM
    // @dev solves function stack limit of buyCover method
    // @param tokenAsset ERC20 paye to buy cover
    // @param amountOut uint256 expected amount out from SDK
    // @param maxPriceWithFee uint256 price with fee
    function _buyWNXM(
        address asset,
        uint256 amountOut,
        uint256 priceWithFee,
        bytes calldata data
    ) internal returns (uint256, uint256) {
        (
            address[] memory path,
            uint24[] memory poolFees,
            string memory exchangeVersion,
            uint256 coverPrice,
            uint256 priceInNXM
        ) = abi.decode(data, (address[], uint24[], string, uint256, uint256));

        address exchangeAddress = keccak256(bytes(exchangeVersion)) ==
            keccak256(bytes("V2"))
            ? uniswapV2Adapter
            : uniswapV3Adapter;

        // avoid stack overflow
        uint256 expectedAmountOut = amountOut;
        uint256 maxPriceWithFee = priceWithFee;
        address tokenAssetAddress = asset;

        uint256 _wNXMAmount;
        if (tokenAssetAddress == ETH) {
            require(
                msg.value >= maxPriceWithFee,
                "NexusDistributor: Insufficient ETH sent"
            );

            // Wrap ETH into WETH
            wEthToken.deposit{value: msg.value}();

            require(
                wEthToken.balanceOf(address(this)) >= maxPriceWithFee,
                "NexusDistributor: Not enough wETH"
            );
            wEthToken.approve(exchangeAddress, maxPriceWithFee);
            _wNXMAmount = _swapTokenForWNXM(
                exchangeAddress,
                address(wEthToken),
                path,
                expectedAmountOut,
                maxPriceWithFee,
                poolFees
            );
        } else {
            require(
                IERC20(tokenAssetAddress).allowance(
                    _msgSender(),
                    address(this)
                ) >= maxPriceWithFee,
                "NexusDistributor need cover price allowance"
            );
            IERC20(tokenAssetAddress).transferFrom(
                _msgSender(),
                address(this),
                maxPriceWithFee
            );
            IERC20(tokenAssetAddress).approve(
                address(exchangeAddress),
                maxPriceWithFee
            );
            _wNXMAmount = _swapTokenForWNXM(
                exchangeAddress,
                tokenAssetAddress,
                path,
                expectedAmountOut,
                maxPriceWithFee,
                poolFees
            );
        }

        return (_wNXMAmount, priceInNXM);
    }

    // @notice Define Dex swap method to use
    // @dev If path of intermediary tokens array is > 0, it will call multihop on dex v2 or v3
    // @dev The array of fees will be passed as it is & either be used for v3 or ignored on v2
    // @param exchangeAddress Uniswap dex address, defined on caller method, either v2 or v3
    // @param tokenIn Asset address used to buy wNXM
    // @param path Array of intermediary tokens to compleete the swap
    // @param expectedAmountOut amount expected out from swap
    // @param maxPriceWithFee cover price with internal fee
    // @param poolFees Array of fees from intermediary token pools if any
    // @return Enough amount of wNXM to buy the cover
    function _swapTokenForWNXM(
        address exchangeAddress,
        address tokenIn,
        address[] memory path,
        uint256 expectedAmountOut,
        uint256 maxPriceWithFee,
        uint24[] memory poolFees
    ) internal returns (uint256 _wNXMAmount) {
        if (path[0] != address(0)) {
            // At this point value of _wNXMAmount is actually how much we spent
            // to buy expectedAmountOut of wNXM.
            _wNXMAmount = IExchangeAdapter(exchangeAddress).exactOutput(
                address(tokenIn),
                path,
                address(wnxmToken),
                address(this),
                expectedAmountOut, // Expected wNXM out froim SDK
                maxPriceWithFee, // _amountInMaximum,
                poolFees
            );
        } else {
            _wNXMAmount = IExchangeAdapter(exchangeAddress).exactOutputSingle(
                address(tokenIn),
                address(wnxmToken),
                address(this),
                expectedAmountOut, // Expected wNXM out froim SDK
                maxPriceWithFee, // _amountInMaximum,
                poolFees[0]
            );

            // If swap maxAmountIn "maxPriceWithFee" is greater than the swap amount spent "_wNXMAmount"
            // and nxmToken balance of this contract is greater or equal to swap expected output
            if (
                maxPriceWithFee >= _wNXMAmount &&
                nxmToken.balanceOf(address(this)) >= expectedAmountOut
            ) {
                // wNXMAmount is now the contract balance in wNXM we will unwrap
                _wNXMAmount = nxmToken.balanceOf(address(this));
            }
        }
    }

    // @notice Submit a claim for the cover
    // @param tokenId cover token id
    // @param data abi-encoded field with additional claim data fields
    function submitClaim(uint256 tokenId, bytes calldata data)
        external
        onlyTokenApprovedOrOwner(tokenId)
        returns (uint256)
    {
        // coverId = tokenId
        uint256 claimId = gateway.submitClaim(tokenId, data);
        emit NexusHelper.ClaimSubmitted(tokenId, claimId, _msgSender());
        return claimId;
    }

    // @notice Submit a claim for the cover
    // @param tokenId cover token id
    // @param incidentId id of the incident
    // @param coveredTokenAmount amount of yield tokens covered
    // @param coverAsset yield token that is covered
    function claimTokens(
        uint256 tokenId,
        uint256 incidentId,
        uint256 coveredTokenAmount,
        address coverAsset
    )
        external
        onlyTokenApprovedOrOwner(tokenId)
        returns (
            uint256 claimId,
            uint256 payoutAmount,
            address payoutToken
        )
    {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(coverAsset),
            _msgSender(),
            address(this),
            coveredTokenAmount
        );
        SafeERC20Upgradeable.safeApprove(
            IERC20Upgradeable(coverAsset),
            address(gateway),
            coveredTokenAmount
        );
        // coverId = tokenId
        (claimId, payoutAmount, payoutToken) = gateway.claimTokens(
            tokenId,
            incidentId,
            coveredTokenAmount,
            coverAsset
        );
        _burn(tokenId);
        if (payoutToken == ETH) {
            (
                bool ok, /* data */

            ) = address(_msgSender()).call{value: payoutAmount}("");
            require(ok, "Distributor: ETH transfer to sender failed.");
        } else {
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(payoutToken),
                _msgSender(),
                payoutAmount
            );
        }
        emit NexusHelper.ClaimSubmitted(tokenId, claimId, _msgSender());
    }

    // @notice Redeem the claim to the cover. Requires that the payout is completed.
    // @param tokenId cover token id
    function redeemClaim(uint256 tokenId, uint256 claimId)
        public
        onlyTokenApprovedOrOwner(tokenId)
        nonReentrant
    {
        require(
            gateway.getClaimCoverId(claimId) == tokenId,
            "Distributor: coverId claimId mismatch"
        );
        (
            IGateway.ClaimStatus status,
            uint256 amountPaid,
            address coverAsset
        ) = gateway.getPayoutOutcome(claimId);
        require(
            status == IGateway.ClaimStatus.ACCEPTED,
            "Distributor: Claim not accepted"
        );

        _burn(tokenId);
        if (coverAsset == ETH) {
            (
                bool ok, /* data */

            ) = _msgSender().call{value: amountPaid}("");
            require(ok, "Distributor: Transfer to NFT owner failed");
        } else {
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(coverAsset),
                _msgSender(),
                amountPaid
            );
        }

        emit NexusHelper.ClaimPayoutRedeemed(
            tokenId,
            claimId,
            _msgSender(),
            amountPaid,
            coverAsset
        );
    }

    // @notice Execute an action on specific cover token. The action is identified by an `action` id.
    //  Allows for an ETH transfer or an ERC20 transfer.
    //  If less than the supplied assetAmount is needed, it is returned to `_msgSender()`.
    // @dev The purpose of this function is future-proofing for updates to the cover buy->claim cycle.
    // @param tokenId id of the cover token
    // @param assetAmount optional asset amount to be transferred along with the action executed
    // @param asset optional asset to be transferred along with the action executed
    // @param action action identifier
    // @param data abi-encoded field with action parameters
    // @return response (abi-encoded response, amount withheld from the original asset amount supplied)

    function executeCoverAction(
        uint256 tokenId,
        uint256 assetAmount,
        address asset,
        uint8 action,
        bytes calldata data
    )
        external
        payable
        onlyTokenApprovedOrOwner(tokenId)
        nonReentrant
        returns (bytes memory response, uint256 withheldAmount)
    {
        if (assetAmount == 0) {
            return gateway.executeCoverAction(tokenId, action, data);
        }
        if (asset == ETH) {
            require(
                msg.value >= assetAmount,
                "Distributor: Insufficient ETH sent"
            );
            (response, withheldAmount) = gateway.executeCoverAction{
                value: msg.value
            }(tokenId, action, data);
            uint256 ethRemainder = assetAmount.sub(withheldAmount);
            (
                bool ok, /* data */

            ) = address(_msgSender()).call{value: ethRemainder}("");
            require(
                ok,
                "Distributor: Returning ETH remainder to sender failed."
            );
            return (response, withheldAmount);
        }

        IERC20Upgradeable token = IERC20Upgradeable(asset);
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(asset),
            _msgSender(),
            address(this),
            assetAmount
        );
        SafeERC20Upgradeable.safeApprove(
            IERC20Upgradeable(asset),
            address(gateway),
            assetAmount
        );
        (response, withheldAmount) = gateway.executeCoverAction(
            tokenId,
            action,
            data
        );
        uint256 remainder = assetAmount.sub(withheldAmount);

        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(asset),
            _msgSender(),
            remainder
        );
        return (response, withheldAmount);
    }

    // @notice Switch NexusMutual membership to `newAddress`.
    // @param newAddress address
    function switchMembership(address newAddress) external onlyOwner {
        nxmToken.approve(address(gateway), uint256(-1));
        gateway.switchMembership(newAddress);
    }

    // @notice Set if buyCover calls are allowed (true) or not (false).
    // @param _buysAllowed value set for buysAllowed
    function setBuysAllowed(bool _buysAllowed) external onlyOwner {
        buysAllowed = _buysAllowed;
    }

    // @notice Set treasury address where `buyCover` distributor fees and `ethOut` from `sellNXM` are sent.
    // @param _treasury new treasury address
    function setTreasuryDetails(address payable _treasury) external onlyOwner {
        treasury = _treasury;
    }

    // @dev required to be allow for receiving ETH claim payouts
    receive() external payable {}

    // @dev Function to set the base URI for all token IDs. It is
    //  automatically added as a prefix to the value returned in {tokenURI},
    //  or to the token ID if {tokenURI} is empty.
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }
}
