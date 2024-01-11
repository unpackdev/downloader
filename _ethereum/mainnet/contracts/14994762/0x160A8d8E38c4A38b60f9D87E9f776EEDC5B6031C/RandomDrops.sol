// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./OwnerPausable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./Random.sol";
import "./IMintable.sol";
import "./OwnerTokenWithdraw.sol";

contract RandomDrops is OwnerPausable, OwnerTokenWithdraw, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    struct DropsInfo {
        uint256 startTime;
        uint256 endTime; // 0 means no end time
        uint256 waitingNum; // waiting to mint token ids Num
        uint256 maxDropEachAddress; // max drops each address can get
        uint256 maxGasPrice; // max gas price
        address nftAddress; // IMintable
        bytes32 merkleRoot;
    }

    struct QuoteTokenInfo {
        address finAddress;
        uint256 price;
        uint256 limit; // Maximum purchase quantity
        uint256 maxDropEachTx; // maximum mint each transaction
        uint256 quantity; // count of bought tokens
    }

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // waiting num => tokenIds The address of the contract that will be used to mint the tokens
    mapping(uint256 => EnumerableSet.UintSet) private waitingToMintTokenIds;
    // drop num => dropsInfo
    mapping(uint256 => DropsInfo) public dropsInfos;
    // drop num => quoteToken => quoteTokenInfo
    mapping(uint256 => mapping(address => QuoteTokenInfo)) public quoteTokenInfos;
    // drop num => eoa address => count of drops
    mapping(uint256 => mapping(address => uint256)) public addressGetDropsCount;
    event SetDropsInfo(
        uint256 indexed dropNum,
        address indexed nftAddress,
        uint256 startTime,
        uint256 endTime,
        uint256 waitingNum,
        uint256 maxDropEachAddress,
        uint256 maxGasPrice,
        bytes32 merkleRoot
    );
    event SetQuoteTokenInfo(
        uint256 indexed dropNum,
        address quoteToken,
        address finAddresses,
        uint256 price,
        uint256 maxDropEachTx,
        uint256 limit
    );
    event Drop(
        uint256 indexed dropNum,
        address indexed nft,
        address user,
        uint256 tokenId,
        address quoteToken,
        uint256 price,
        address finAddress
    );

    function addWaitingToMintTokenId(uint256 _waitingNum, uint256 _tokenId) public onlyOwner {
        waitingToMintTokenIds[_waitingNum].add(_tokenId);
    }

    function addWaitingToMintTokenIdFromTo(
        uint256 _waitingNum,
        uint256 _fromTokenId,
        uint256 _toTokenId
    ) external onlyOwner {
        for (; _fromTokenId <= _toTokenId; ++_fromTokenId) {
            waitingToMintTokenIds[_waitingNum].add(_fromTokenId);
        }
    }

    function addWaitingToMintTokenIds(uint256 _waitingNum, uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i; i < _tokenIds.length; ++i) {
            waitingToMintTokenIds[_waitingNum].add(_tokenIds[i]);
        }
    }

    function removeWaitingToMintTokenId(uint256 _waitingNum, uint256 _tokenId) public onlyOwner {
        waitingToMintTokenIds[_waitingNum].remove(_tokenId);
    }

    function removeWaitingToMintTokenIdFromTo(
        uint256 _waitingNum,
        uint256 _fromTokenId,
        uint256 _toTokenId
    ) external onlyOwner {
        for (; _fromTokenId <= _toTokenId; ++_fromTokenId) {
            waitingToMintTokenIds[_waitingNum].remove(_fromTokenId);
        }
    }

    function removeWaitingToMintTokenIds(uint256 _waitingNum, uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i; i < _tokenIds.length; ++i) {
            waitingToMintTokenIds[_waitingNum].remove(_tokenIds[i]);
        }
    }

    function getWaitingToMintLength(uint256 _waitingNum) external view returns (uint256) {
        return waitingToMintTokenIds[_waitingNum].length();
    }

    function getWaitingToMintAt(uint256 _waitingNum, uint256 index) external view returns (uint256) {
        return waitingToMintTokenIds[_waitingNum].at(index);
    }

    function getWaitingToMints(uint256 _waitingNum) external view returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](waitingToMintTokenIds[_waitingNum].length());
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            tokenIds[i] = waitingToMintTokenIds[_waitingNum].at(i);
        }
    }

    function setDropsInfo(
        uint256 _dropNum,
        address _nftAddress,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _waitingNum,
        uint256 _maxDropEachAddress,
        uint256 _maxGasPrice,
        bytes32 _merkleRoot
    ) public onlyOwner {
        dropsInfos[_dropNum] = DropsInfo({
            startTime: _startTime,
            endTime: _endTime,
            waitingNum: _waitingNum,
            maxDropEachAddress: _maxDropEachAddress,
            maxGasPrice: _maxGasPrice,
            nftAddress: _nftAddress,
            merkleRoot: _merkleRoot
        });
        emit SetDropsInfo(
            _dropNum,
            _nftAddress,
            _startTime,
            _endTime,
            _waitingNum,
            _maxDropEachAddress,
            _maxGasPrice,
            _merkleRoot
        );
    }

    function setQuoteTokenInfos(
        uint256 _dropNum,
        address[] memory _quoteTokens,
        address[] memory _finAddresses,
        uint256[] memory _prices,
        uint256[] memory _maxDropEachTxs,
        uint256[] memory _limits
    ) public onlyOwner {
        require(
            _quoteTokens.length == _prices.length &&
                _prices.length == _maxDropEachTxs.length &&
                _maxDropEachTxs.length == _limits.length,
            'length error'
        );
        for (uint256 i; i < _quoteTokens.length; ++i) {
            quoteTokenInfos[_dropNum][_quoteTokens[i]].finAddress = _finAddresses[i];
            quoteTokenInfos[_dropNum][_quoteTokens[i]].price = _prices[i];
            quoteTokenInfos[_dropNum][_quoteTokens[i]].maxDropEachTx = _maxDropEachTxs[i];
            quoteTokenInfos[_dropNum][_quoteTokens[i]].limit = _limits[i];
            emit SetQuoteTokenInfo(
                _dropNum,
                _quoteTokens[i],
                _finAddresses[i],
                _prices[i],
                _maxDropEachTxs[i],
                _limits[i]
            );
        }
    }

    function drop(
        uint256 _dropNum,
        address _quoteToken,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external payable whenNotPaused nonReentrant returns (uint256[] memory tokenIds) {
        require(tx.origin == msg.sender, 'only EOA');
        require(
            block.timestamp >= dropsInfos[_dropNum].startTime && dropsInfos[_dropNum].startTime != 0,
            'not start yet'
        );
        require(dropsInfos[_dropNum].endTime == 0 || block.timestamp <= dropsInfos[_dropNum].endTime, 'ended');
        require(
            (msg.value == 0 && _quoteToken != ETH_ADDRESS) || (_quoteToken == ETH_ADDRESS && msg.value == _amount),
            'value error'
        );
        require(
            dropsInfos[_dropNum].maxGasPrice == 0 || tx.gasprice <= dropsInfos[_dropNum].maxGasPrice,
            'gas price too high!'
        );
        QuoteTokenInfo storage quoteTokenInfo = quoteTokenInfos[_dropNum][_quoteToken];
        require(quoteTokenInfo.price != 0, 'quote token disable');
        require(_amount >= quoteTokenInfo.price, 'amount not enough');
        require(quoteTokenInfo.limit > quoteTokenInfo.quantity, 'quote token limit');
        require(
            dropsInfos[_dropNum].merkleRoot == 0 ||
                MerkleProof.verify(
                    _merkleProof,
                    dropsInfos[_dropNum].merkleRoot,
                    keccak256(abi.encodePacked(_msgSender()))
                ),
            'Invalid proof.'
        );
        uint256 size = Math.min(quoteTokenInfo.limit.sub(quoteTokenInfo.quantity), _amount.div(quoteTokenInfo.price));
        size = Math.min(size, quoteTokenInfo.maxDropEachTx);
        uint256 waitingNum = dropsInfos[_dropNum].waitingNum;
        size = Math.min(size, waitingToMintTokenIds[waitingNum].length());
        size = Math.min(
            size,
            dropsInfos[_dropNum].maxDropEachAddress.sub(addressGetDropsCount[_dropNum][_msgSender()])
        );
        require(size > 0, 'no token to mint');

        _amount = size.mul(quoteTokenInfo.price);

        if (_quoteToken == ETH_ADDRESS) {
            Address.sendValue(payable(quoteTokenInfo.finAddress), _amount);
            if (msg.value > _amount) Address.sendValue(payable(_msgSender()), msg.value - _amount);
        } else {
            IERC20(_quoteToken).safeTransferFrom(_msgSender(), quoteTokenInfo.finAddress, _amount);
        }
        tokenIds = new uint256[](size);
        for (uint256 i; i < size; ++i) {
            tokenIds[i] = waitingToMintTokenIds[waitingNum].at(
                Random.gen(uint256(uint160(_msgSender())).add(i), waitingToMintTokenIds[waitingNum].length())
            );
            require(waitingToMintTokenIds[waitingNum].remove(tokenIds[i]), 'remove error');
            IMintable(dropsInfos[_dropNum].nftAddress).mint(_msgSender(), tokenIds[i]);
            emit Drop(
                _dropNum,
                dropsInfos[_dropNum].nftAddress,
                _msgSender(),
                tokenIds[i],
                _quoteToken,
                quoteTokenInfo.price,
                quoteTokenInfo.finAddress
            );
            addressGetDropsCount[_dropNum][_msgSender()]++;
            quoteTokenInfo.quantity++;
        }
    }

    function getQuoteTokenInfos(uint256 _dropNum, address[] memory _quoteTokens)
        public
        view
        returns (QuoteTokenInfo[] memory infos)
    {
        infos = new QuoteTokenInfo[](_quoteTokens.length);
        for (uint256 i; i < _quoteTokens.length; ++i) {
            infos[i] = quoteTokenInfos[_dropNum][_quoteTokens[i]];
        }
    }
}
