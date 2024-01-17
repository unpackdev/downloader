// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155.sol";
import "./IFayreMembershipCard721.sol";
import "./IFayreTokenLocker.sol";


contract FayreNFTSwapperLite is Ownable, IERC721Receiver, IERC1155Receiver {
    enum SwapAssetType {
        LIQUIDITY,
        ERC20,
        ERC721,
        ERC1155
    }

    struct SwapAssetData {
        address contractAddress;
        SwapAssetType assetType;
        uint256 id;
        uint256 amount;
    }

    struct SwapRequest {
        address creator;
        address counterpart;
        SwapAssetData[] creatorAssetData;
        SwapAssetData[] counterpartAssetData;
    }

    struct SwapData {
        SwapRequest swapRequest;
        uint256 creatorFee;
        uint256 end;
    }

    struct TokenLockerSwapFeeData {
        uint256 lockedTokensAmount;
        uint256 fee;
    }

    struct ContractStatusData {
        address contractAddress;
        bool isWhitelisted;
    }

    event CreateSwap(uint256 indexed swapId, address indexed creator, address indexed counterpart);
    event FinalizeSwap(uint256 indexed swapId, address indexed creator, address indexed counterpart);
    event CancelSwap(uint256 indexed swapId, address indexed creator, address indexed counterpart);
    event RejectSwap(uint256 indexed swapId, address indexed creator, address indexed counterpart);

    mapping(uint256 => SwapData) public swapsData;
    address[] public membershipCardsAddresses;
    uint256 public membershipCardsAddressesCount;
    address public tokenLockerAddress;
    address public treasuryAddress;
    uint256 public swapFee;
    uint256 public currentSwapId;
    mapping(string => uint256) public cardsSwapFee;
    mapping(string => uint256) public cardsExpirationDeltaTime;
    TokenLockerSwapFeeData[] public tokenLockerSwapFeesData;
    uint256 public tokenLockerSwapFeesCount;
    mapping(address => uint256[]) public usersSwapsIds;
    mapping(address => uint256) public usersSwapsCount;
    mapping(address => bool) public isContractWhitelisted;

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
 
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == 0x01ffc9a7 || interfaceID == type(IERC721Receiver).interfaceId || interfaceID == type(IERC1155Receiver).interfaceId;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function setSwapFee(uint256 newSwapFee) external onlyOwner {
        swapFee = newSwapFee;
    }

    function addMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                revert("Membership card address already present");

        membershipCardsAddresses.push(membershipCardsAddress);

        membershipCardsAddressesCount++;
    }

    function removeMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "Membership card address not found");

        membershipCardsAddresses[indexToDelete] = membershipCardsAddresses[membershipCardsAddresses.length - 1];

        membershipCardsAddresses.pop();

        membershipCardsAddressesCount--;
    }

    function setTokenLockerAddress(address newTokenLockerAddress) external onlyOwner {
        tokenLockerAddress = newTokenLockerAddress;
    }

    function addTokenLockerSwapFeeData(uint256 lockedTokensAmount, uint256 fee) external onlyOwner {
        for (uint256 i = 0; i < tokenLockerSwapFeesData.length; i++)
            if (tokenLockerSwapFeesData[i].lockedTokensAmount == lockedTokensAmount)
                revert("E#17");

        tokenLockerSwapFeesData.push(TokenLockerSwapFeeData(lockedTokensAmount, fee));

        tokenLockerSwapFeesCount++;
    }

    function removeTokenLockerSwapFeeData(uint256 lockedTokensAmount) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < tokenLockerSwapFeesData.length; i++)
            if (tokenLockerSwapFeesData[i].lockedTokensAmount == lockedTokensAmount)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "Wrong token locker swap fee data");

        tokenLockerSwapFeesData[indexToDelete] = tokenLockerSwapFeesData[tokenLockerSwapFeesData.length - 1];

        tokenLockerSwapFeesData.pop();

        tokenLockerSwapFeesCount--;
    }

    function setCardSwapFee(string calldata symbol, uint256 newCardSwapFee) external onlyOwner {
        cardsSwapFee[symbol] = newCardSwapFee;
    }

    function setCardExpirationDeltaTime(string calldata symbol, uint256 newCardExpirationDeltaTime) external onlyOwner {
        cardsExpirationDeltaTime[symbol] = newCardExpirationDeltaTime;
    }

    function setContractsStatuses(ContractStatusData[] calldata contractsStatusesData) external onlyOwner {
        for (uint256 i = 0; i < contractsStatusesData.length; i++)
            isContractWhitelisted[contractsStatusesData[i].contractAddress] = contractsStatusesData[i].isWhitelisted;
    }

    function createSwap(SwapRequest calldata swapRequest) external payable {
        require(swapRequest.creator == _msgSender(), "Only creator can create the swap");
        require(swapRequest.creator != swapRequest.counterpart, "Creator and counterpart cannot be the same address");

        bool creatorAssetNFTFound = _processAssetData(swapRequest.creatorAssetData);

        bool counterpartAssetNFTFound = _processAssetData(swapRequest.counterpartAssetData);

        require(creatorAssetNFTFound || counterpartAssetNFTFound, "At least one basket must contains one nft");

        uint256 swapId = currentSwapId++;

        swapsData[swapId].swapRequest = swapRequest;

        uint256 processedFee = _processFee(_msgSender(), swapFee);

        _checkProvidedLiquidity(swapRequest.creatorAssetData, processedFee);

        swapsData[swapId].creatorFee = processedFee;

        _transferAsset(swapRequest.creator, address(this), swapsData[swapId].swapRequest.creatorAssetData);

        usersSwapsIds[swapRequest.creator].push(swapId);
        usersSwapsCount[swapRequest.creator]++;

        usersSwapsIds[swapRequest.counterpart].push(swapId);
        usersSwapsCount[swapRequest.counterpart]++;

        emit CreateSwap(swapId, swapRequest.creator, swapRequest.counterpart);
    }

    function finalizeSwap(uint256 swapId, bool rejectSwap) external payable {
        SwapData storage swapData = swapsData[swapId];

        require(swapData.end == 0, "Swap already finalized");
        require(swapData.swapRequest.counterpart == _msgSender() || swapData.swapRequest.creator == _msgSender() || owner() == _msgSender() , "Only counterpart/creator/owner can conclude/reject the swap");

        swapData.end = block.timestamp;

        if (rejectSwap) {
            _cancelSwap(swapData);

            emit RejectSwap(swapId, swapData.swapRequest.creator, swapData.swapRequest.counterpart);

            return;
        }

        require(swapData.swapRequest.counterpart == _msgSender(), "Only the counterpart can conclude the swap");

        uint256 processedFee = _processFee(_msgSender(), swapFee);

        _checkProvidedLiquidity(swapData.swapRequest.counterpartAssetData, processedFee);

        uint256 mergedFees = swapData.creatorFee + processedFee;

        if (mergedFees > 0) {
            (bool feeSendToTreasurySuccess, ) = treasuryAddress.call{value: mergedFees}("");

            require(feeSendToTreasurySuccess, "Unable to send fees to treasury");
        }

        _transferAsset(swapData.swapRequest.counterpart, swapData.swapRequest.creator, swapData.swapRequest.counterpartAssetData);

        _transferAsset(address(this), swapData.swapRequest.counterpart, swapData.swapRequest.creatorAssetData);

        emit FinalizeSwap(swapId, swapData.swapRequest.creator, swapData.swapRequest.counterpart);
    }

    function _cancelSwap(SwapData storage swapData) private {
        swapData.end = block.timestamp;

        _transferAsset(address(this), swapData.swapRequest.creator, swapData.swapRequest.creatorAssetData);

        if (swapData.creatorFee > 0) {
            (bool creatorFeeRefundSuccess, ) = swapData.swapRequest.creator.call{value: swapData.creatorFee }("");

            require(creatorFeeRefundSuccess, "Unable to refund fee to creator");
        }
    }

    function _transferAsset(address from, address to, SwapAssetData[] storage assetData) private {
        for (uint256 i = 0; i < assetData.length; i++) {
            if (assetData[i].assetType == SwapAssetType.LIQUIDITY) {
                if (to != address(this)) {
                    (bool liquiditySendSuccess, ) = to.call{value: assetData[i].amount}("");

                    require(liquiditySendSuccess, "Unable to transfer liquidity");
                }
            }
            else if (assetData[i].assetType == SwapAssetType.ERC20) {
                if (from == address(this)) {
                    require(IERC20(assetData[i].contractAddress).transfer(to, assetData[i].amount), "ERC20 transfer failed");
                } else {
                    require(IERC20(assetData[i].contractAddress).transferFrom(from, to, assetData[i].amount), "ERC20 transfer failed");
                }
            }
            else if (assetData[i].assetType == SwapAssetType.ERC721) {
                IERC721(assetData[i].contractAddress).safeTransferFrom(from, to, assetData[i].id, "");
            }
            else if (assetData[i].assetType == SwapAssetType.ERC1155) {
                IERC1155(assetData[i].contractAddress).safeTransferFrom(from, to, assetData[i].id, assetData[i].amount, "");
            }
        }
    }

    function _processFee(address owner, uint256 fee) private returns(uint256) {
        //Process locked tokens
        if (tokenLockerAddress != address(0)) {
            uint256 minLockDuration = IFayreTokenLocker(tokenLockerAddress).minLockDuration();

            IFayreTokenLocker.LockData memory lockData = IFayreTokenLocker(tokenLockerAddress).usersLockData(owner);

            if (lockData.amount > 0)
                if (lockData.start + minLockDuration <= lockData.expiration && lockData.start + minLockDuration >= block.timestamp)
                    for (uint256 j = 0; j < tokenLockerSwapFeesData.length; j++)
                        if (lockData.amount >= tokenLockerSwapFeesData[j].lockedTokensAmount)
                            if (fee > tokenLockerSwapFeesData[j].fee)
                                fee = tokenLockerSwapFeesData[j].fee;
        }

        //Process on-chain membership cards
        if (fee > 0)
            for (uint256 i = 0; i < membershipCardsAddresses.length; i++) {
                uint256 membershipCardsAmount = IFayreMembershipCard721(membershipCardsAddresses[i]).balanceOf(owner);

                if (membershipCardsAmount <= 0)
                    continue;

                string memory membershipCardSymbol = IFayreMembershipCard721(membershipCardsAddresses[i]).symbol();

                if (cardsExpirationDeltaTime[membershipCardSymbol] > 0) {
                    for (uint256 j = 0; j < membershipCardsAmount; j++) {
                        uint256 currentTokenId = IFayreMembershipCard721(membershipCardsAddresses[i]).tokenOfOwnerByIndex(owner, j);

                        if (IFayreMembershipCard721(membershipCardsAddresses[i]).membershipCardMintTimestamp(currentTokenId) + cardsExpirationDeltaTime[membershipCardSymbol] >= block.timestamp) {
                            uint256 cardSwapFee = cardsSwapFee[membershipCardSymbol];

                            if (fee > cardSwapFee)
                                fee = cardSwapFee;
                        }
                    }
                } else {
                    uint256 cardSwapFee = cardsSwapFee[membershipCardSymbol];

                    if (fee > cardSwapFee)
                        fee = cardSwapFee;
                }
            }

        return fee;
    }

    function _processAssetData(SwapAssetData[] calldata assetData) private view returns(bool nftFound) {
        for (uint256 i = 0; i < assetData.length; i++) {
            if (assetData[i].assetType == SwapAssetType.ERC721 || assetData[i].assetType == SwapAssetType.ERC1155)
                nftFound = true;

            if (assetData[i].assetType == SwapAssetType.ERC20 || assetData[i].assetType == SwapAssetType.ERC721 || assetData[i].assetType == SwapAssetType.ERC1155)
                require(isContractWhitelisted[assetData[i].contractAddress], "Contract not whitelisted");
        }
    }

    function _checkProvidedLiquidity(SwapAssetData[] memory assetData, uint256 fee) private {
        require(msg.value >= fee, "Liquidity below fee");

        uint256 providedLiquidityForAsset = msg.value - fee;

        for (uint256 i = 0; i < assetData.length; i++)
            if (assetData[i].assetType == SwapAssetType.LIQUIDITY)
                require(providedLiquidityForAsset == assetData[i].amount, "Wrong liquidity provided");
    }
}