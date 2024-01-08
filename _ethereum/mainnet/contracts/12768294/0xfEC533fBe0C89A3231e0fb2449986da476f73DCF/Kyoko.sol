// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./ERC165.sol";
import "./Counters.sol";
import "./ERC721.sol";

import "./BorrowToken.sol";
import "./LenderToken.sol";

contract Kyoko is Ownable, ERC721Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    BorrowToken public bToken; // bToken

    LenderToken public lToken; // lToken

    // If true, any operation will be rejected
    bool public pause = false;

    // fixed interestRate: 12%, perBlock 15s, month 30 days, year 12 months, preBlock interestRate = 0.12 * 10**18 / (Seconds * Minutes * Hours * Days * Months / perBlockTime(15s) )
    uint256 public interestRate = 57870370371;

    uint256 public cycle = 90 days; // Minimum borrowing cycle

    uint256 public emergencyCycle = 30 days; // Minimum emergency cycle

    uint256 public fee = 50; // admin fee

    IERC20[] public whiteList; // whiteList

    struct MARK {
        bool isBorrow; // has borrow erc20
        bool isRepay; // has repay erc20
        bool hasWithdraw; // This nft has withdraw
    }

    struct Nft {
        address holder; // nft holder
        uint256 tokenId; // nft tokenId
        IERC721 nftToken; // nft address
        uint256 amount; // debt amount
        IERC20 erc20Token; // debt token address
        uint256 bTokenId; // btoken id
        uint256 lTokenId; // ltoken id
        uint256 borrowBlock; // borrow block number
        uint256 borrowTimestamp; // borrow timestamp
        uint256 emergencyTimestamp; // emergency timestamp
        uint256 repayAmount; // repayAmount
        MARK marks;
    }

    IERC721[] public NftAdrList;

    mapping(IERC721 => Nft[]) public NftMap; // Collaterals mapping

    // received collateral
    event NFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    // deposit collateral
    event DepositErc721(
        uint256 _tokenId,
        IERC721 _nftToken,
        uint256 _amount,
        IERC20 _erc20Token
    );

    // lend erc20
    event LendERC20(
        uint256 _tokenId,
        IERC721 _nftToken,
        uint256 _amount,
        IERC20 _erc20Token,
        uint256 _bTokenId
    );

    // borrow erc20
    event Borrow(
        uint256 _tokenId,
        IERC721 _nftToken,
        uint256 _amount,
        IERC20 _erc20Token,
        uint256 _bTokenId
    );
    // repay erc20
    event Repay(
        uint256 _tokenId,
        IERC721 _nftToken,
        uint256 _amount,
        IERC20 _erc20Token,
        uint256 _bTokenId
    );

    // Claim collateral
    event ClaimCollateral(
        uint256 _tokenId,
        IERC721 _nftToken,
        IERC20 _erc20Token,
        uint256 _bTokenId
    );

    // LToken claim erc20 token
    event LTokenClaimERC20(
        uint256 _tokenId,
        IERC721 _nftToken,
        uint256 _amount,
        IERC20 _erc20Token,
        uint256 _lenderNftTokenId,
        uint256 _bTokenId
    );

    // execute emergency to warning holder
    event ExecuteEmergency(
        uint256 _tokenId,
        IERC721 _nftToken,
        IERC20 _erc20Token,
        uint256 _lenderNftTokenId,
        uint256 _bTokenId
    );

    // Liquidate collateral
    event Liquidate(
        uint256 _tokenId,
        IERC721 _nftToken,
        IERC20 _erc20Token,
        uint256 _lenderNftTokenId,
        uint256 _bTokenId
    );

    constructor(BorrowToken _bToken, LenderToken _lToken) {
        bToken = _bToken;
        lToken = _lToken;
    }

    modifier isPause() {
        require(!pause, "Now Pause");
        _;
    }

    modifier checkDebt(uint256 _amount) {
        require(_amount > 0, "The amount must > 0");
        _;
    }

    modifier checkWhiteList(IERC20 _address) {
        bool include;
        for (uint256 index = 0; index < whiteList.length; index++) {
            if (whiteList[index] == _address) {
                include = true;
                break;
            }
        }
        require(include, "The address is not whitelisted");
        _;
    }

    modifier checkCollateralStatus(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        uint256 _bTokenId,
        IERC20 _erc20Token
    ) {
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        require(!_nft.marks.isRepay && _nft.marks.isBorrow, "NFT status wrong");
        _;
    }

    function setPause(bool _pause) public onlyOwner {
        pause = _pause;
    }

    function setInterestRate(uint256 _interestRate) public isPause onlyOwner {
        interestRate = _interestRate;
    }

    function setCycle(uint256 _cycle) public isPause onlyOwner {
        cycle = _cycle;
    }

    function setEmergencyCycle(uint256 _emergencyCycle)
        public
        isPause
        onlyOwner
    {
        emergencyCycle = _emergencyCycle;
    }

    function setWhiteList(IERC20[] memory _whiteList) public isPause onlyOwner {
        whiteList = _whiteList;
    }

    function setFee(uint256 _fee) public isPause onlyOwner {
        fee = _fee;
    }

    function getWhiteListLength() public view returns (uint256 length) {
        length = whiteList.length;
    }

    function addWhiteList(IERC20 _address) public isPause onlyOwner {
        whiteList.push(_address);
    }

    function _addNftAdr(IERC721 _nftToken) internal {
        uint256 len = NftAdrList.length;
        bool hasAdr = false;
        for (uint256 index = 0; index < len; index++) {
            if (_nftToken == NftAdrList[index]) {
                hasAdr = true;
                break;
            }
        }
        if (!hasAdr) NftAdrList.push(_nftToken);
    }

    function getNftMapLength(IERC721 _nftToken)
        public
        view
        returns (uint256 length)
    {
        length = NftMap[_nftToken].length;
    }

    function getNftAdrListLength() public view returns (uint256 length) {
        length = NftAdrList.length;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Holder) returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    // deposit NFT
    function depositErc721(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        uint256 _amount,
        IERC20 _erc20Token
    ) public isPause checkDebt(_amount) checkWhiteList(_erc20Token) {
        bool isERC721 = IERC721(_nftToken).supportsInterface(0x80ac58cd);
        require(isERC721, "Parameter _nftToken is not ERC721 contract address");
        // mint bToken
        uint256 _bTokenId = bToken.mint(msg.sender);
        _addNftAdr(_nftToken);
        MARK memory _mark = MARK(false, false, false);
        // save collateral info
        NftMap[_nftToken].push(
            Nft({
                holder: msg.sender,
                tokenId: _nftTokenId,
                nftToken: _nftToken,
                amount: _amount,
                erc20Token: _erc20Token,
                bTokenId: _bTokenId,
                borrowBlock: 0,
                borrowTimestamp: 0,
                emergencyTimestamp: 0,
                repayAmount: 0,
                lTokenId: 0,
                marks: _mark
            })
        );
        IERC721(_nftToken).safeTransferFrom(
            msg.sender,
            address(this),
            _nftTokenId
        );
        emit DepositErc721(_nftTokenId, _nftToken, _amount, _erc20Token);
    }

    // Lend ERC20
    function lendERC20(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        uint256 _amount,
        IERC20 _erc20Token,
        uint256 _bTokenId
    ) public isPause checkDebt(_amount) checkWhiteList(_erc20Token) {
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        require(!_nft.marks.isBorrow, "This collateral already borrowed");
        // mint lToken
        uint256 _lTokenId = lToken.mint(msg.sender);
        // set collateral lTokenid
        _setCollateralLTokenId(_nftTokenId, _nftToken, _bTokenId, _lTokenId);
        // get lend amount
        uint256 tempAmount =
            calcLenderAmount(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        require(_amount >= tempAmount, "The _amount is not match");
        // get fee
        uint256 _fee = _amount - _nft.amount;
        IERC20(_erc20Token).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        IERC20(_erc20Token).safeTransfer(owner(), _fee);
        emit LendERC20(_nftTokenId, _nftToken, _amount, _erc20Token, _bTokenId);
        // borrow action
        _borrow(_nftTokenId, _nftToken, _erc20Token, _bTokenId);
    }

    function _borrow(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        IERC20 _erc20Token,
        uint256 _bTokenId
    ) internal {
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        // change collateral status
        _changeCollateralStatus(
            _nftTokenId,
            _nftToken,
            true,
            false,
            false,
            block.timestamp,
            _nft.repayAmount,
            _nft.emergencyTimestamp
        );
        // send erc20 token to collateral _nft.holder
        IERC20(_erc20Token).safeTransfer(address(_nft.holder), _nft.amount);
        emit Borrow(
            _nftTokenId,
            _nftToken,
            _nft.amount,
            _erc20Token,
            _bTokenId
        );
    }

    function repay(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        uint256 _amount,
        IERC20 _erc20Token,
        uint256 _bTokenId
    ) public isPause checkDebt(_amount) checkWhiteList(_erc20Token) {
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        // get repay amount
        uint256 _repayAmount =
            calcInterestRate(
                _nftTokenId,
                _nftToken,
                _bTokenId,
                _erc20Token,
                true
            );
        require(_amount >= _repayAmount, "Wrong amount.");
        // change collateral status
        _changeCollateralStatus(
            _nftTokenId,
            _nftToken,
            false,
            true,
            false,
            _nft.borrowTimestamp,
            _repayAmount,
            _nft.emergencyTimestamp
        );
        // send erc20 token to contract
        IERC20(_erc20Token).safeTransferFrom(
            address(msg.sender),
            address(this),
            _repayAmount
        );
        emit Repay(
            _nftTokenId,
            _nftToken,
            _repayAmount,
            _erc20Token,
            _bTokenId
        );
    }

    function claimCollateral(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        IERC20 _erc20Token,
        uint256 _bTokenId
    ) public isPause {
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        if (_nft.marks.isBorrow) {
            require(_nft.marks.isRepay, "This debt is not repay");
        }
        _changeCollateralStatus(
            _nftTokenId,
            _nftToken,
            false,
            true,
            true,
            _nft.borrowTimestamp,
            _nft.repayAmount,
            _nft.emergencyTimestamp
        );
        // send bToken to contract for widthdraw collateral
        IERC721(bToken).safeTransferFrom(msg.sender, address(0), _bTokenId);
        // send collateral to msg.sender
        IERC721(_nftToken).safeTransferFrom(
            address(this),
            msg.sender,
            _nftTokenId
        );
        emit ClaimCollateral(_nftTokenId, _nftToken, _erc20Token, _bTokenId);
    }

    function lTokenClaimERC20(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        IERC20 _erc20Token,
        uint256 _lTokenId,
        uint256 _bTokenId
    ) public isPause checkWhiteList(_erc20Token) {
        // check collateral holder has borrow
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        require(_nft.marks.isRepay, "This debt is not clear");
        // send lToken to contract
        IERC721(lToken).safeTransferFrom(msg.sender, address(0), _lTokenId);
        // send erc20 token to msg.sender
        IERC20(_erc20Token).safeTransfer(msg.sender, _nft.repayAmount);
        emit LTokenClaimERC20(
            _nftTokenId,
            _nftToken,
            _nft.repayAmount,
            _erc20Token,
            _lTokenId,
            _bTokenId
        );
    }

    function executeEmergency(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        IERC20 _erc20Token,
        uint256 _lTokenId,
        uint256 _bTokenId
    )
        public
        isPause
        checkCollateralStatus(_nftTokenId, _nftToken, _bTokenId, _erc20Token)
    {
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        uint256 time = _nft.borrowTimestamp;
        // An emergency can be triggered after 30 days
        require(
            (block.timestamp - time) > cycle,
            "Can do not execute emergency."
        );
        // set trigger emergency timestamp for withdraw collateral
        _changeCollateralStatus(
            _nftTokenId,
            _nftToken,
            _nft.marks.isBorrow,
            _nft.marks.isRepay,
            _nft.marks.hasWithdraw,
            _nft.borrowTimestamp,
            _nft.repayAmount,
            block.timestamp
        );
        // send lToken for verify
        IERC721(lToken).safeTransferFrom(msg.sender, address(this), _lTokenId);
        IERC721(lToken).safeTransferFrom(address(this), msg.sender, _lTokenId);
        emit ExecuteEmergency(
            _nftTokenId,
            _nftToken,
            _erc20Token,
            _lTokenId,
            _bTokenId
        );
    }

    function liquidate(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        IERC20 _erc20Token,
        uint256 _lTokenId,
        uint256 _bTokenId
    )
        public
        isPause
        checkCollateralStatus(_nftTokenId, _nftToken, _bTokenId, _erc20Token)
    {
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        // send lToken for verify
        IERC721(lToken).safeTransferFrom(msg.sender, address(0), _lTokenId);
        uint256 _emerTime = _nft.emergencyTimestamp;
        // An emergency withdraw can be triggered after 15 days
        require(
            (block.timestamp - _emerTime) > emergencyCycle,
            "Can do not liquidate."
        );
        // send collateral to lToken holder
        IERC721(_nftToken).safeTransferFrom(
            address(this),
            msg.sender,
            _nftTokenId
        );
        _changeCollateralStatus(
            _nftTokenId,
            _nftToken,
            false,
            true,
            true,
            _nft.borrowTimestamp,
            _nft.repayAmount,
            _nft.emergencyTimestamp
        );
        emit Liquidate(
            _nftTokenId,
            _nftToken,
            _erc20Token,
            _lTokenId,
            _bTokenId
        );
    }

    function _changeCollateralStatus(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        bool isBorrow,
        bool isRepay,
        bool hasWithdraw,
        uint256 _borrowTimestamp,
        uint256 _repayAmount,
        uint256 _emergencyTimestamp
    ) internal {
        Nft[] storage nftList = NftMap[_nftToken];
        Nft storage nft;
        bool _hasNft = false;
        for (uint256 index = nftList.length - 1; index >= 0; index--) {
            nft = nftList[index];
            if (nft.tokenId == _nftTokenId && _nftToken == nft.nftToken) {
                _hasNft = true;
                nft.marks.isBorrow = isBorrow;
                nft.marks.isRepay = isRepay;
                nft.marks.hasWithdraw = hasWithdraw;
                if (isBorrow) nft.borrowBlock = block.number;
                nft.borrowTimestamp = _borrowTimestamp;
                nft.repayAmount = _repayAmount;
                nft.emergencyTimestamp = _emergencyTimestamp;
                break;
            }
        }
        require(_hasNft, "Not find this nft -> changeCollateralStatus");
    }

    function calcInterestRate(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        uint256 _bTokenId,
        IERC20 _erc20Token,
        bool _isRepay
    ) public view returns (uint256 repayAmount) {
        uint256 _borrowBlock;
        uint256 base = _isRepay ? 100 : 101;
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        // repayAmount = _nft.amount;
        _borrowBlock = block.number - _nft.borrowBlock;
        uint256 _interestRate =
            (_borrowBlock * interestRate * _nft.amount) / 10**18;
        // repayAmount = _interestRate + (_nft.amount / 100) * base;
        repayAmount = _interestRate.add(_nft.amount.mul(base).div(100));
    }

    function calcLenderAmount(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        uint256 _bTokenId,
        IERC20 _erc20Token
    ) public view returns (uint256 tempAmount) {
        Nft memory _nft =
            _findNft(_nftTokenId, _nftToken, _bTokenId, _erc20Token);
        tempAmount = _nft.amount.mul(10000 + fee).div(10000); // tempAmount = (_nft.amount / 10000) * (10000 + fee);
    }

    function _setCollateralLTokenId(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        uint256 _bTokenId,
        uint256 _lTokenId
    ) internal {
        Nft[] storage nftList = NftMap[_nftToken];
        Nft storage nft;
        bool _hasNft = false;
        for (uint256 index = nftList.length - 1; index >= 0; index--) {
            nft = nftList[index];
            if (
                nft.tokenId == _nftTokenId &&
                _nftToken == nft.nftToken &&
                nft.bTokenId == _bTokenId
            ) {
                _hasNft = true;
                nft.lTokenId = _lTokenId;
                break;
            }
        }
        require(_hasNft, "Not find this nft -> _setCollateralLTokenId");
    }

    function _findNft(
        uint256 _nftTokenId,
        IERC721 _nftToken,
        uint256 _bTokenId,
        IERC20 _erc20Token
    ) internal view returns (Nft memory) {
        bool _hasNft = false;
        Nft[] memory nftList = NftMap[_nftToken];
        Nft memory _nft;
        for (uint256 index = nftList.length - 1; index >= 0; index--) {
            _nft = nftList[index];
            if (
                _nft.tokenId == _nftTokenId &&
                _nft.nftToken == _nftToken &&
                _nft.bTokenId == _bTokenId &&
                _nft.erc20Token == _erc20Token
            ) {
                _hasNft = true;
                break;
            }
        }
        require(_hasNft, "Not find this nft -> _findNft");
        return _nft;
    }
}
