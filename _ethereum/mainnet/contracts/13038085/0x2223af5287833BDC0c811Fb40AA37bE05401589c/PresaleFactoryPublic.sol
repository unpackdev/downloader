// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./ERC20.sol";
import "./PresalePublic.sol";

contract PresaleFactoryPublic {
    LessLibrary public immutable safeLibrary;
    /* ERC20 public lessToken;
    PresalePublic presale; */
    address public owner;

    uint256 private lastTierTime = 6900;

    struct PresaleInfo {
        address tokenAddress;
        uint256 tokenPriceInWei;
        uint256 hardCapInWei;
        uint256 softCapInWei;
        uint256 openVotingTime;
        uint256 openTime;
        uint256 closeTime;
        uint256 _tokenAmount;
        bytes _signature;
        uint256 _timestamp;
        uint8[4] poolPercentages;
        uint256[5] stakingTiers;
    }

    struct PresalePancakeSwapInfo {
        uint256 listingPriceInWei;
        uint256 lpTokensLockDurationInDays;
        uint8 liquidityPercentageAllocation;
        uint256 liquidityAllocationTime;
    }

    struct PresaleStringInfo {
        bytes32 saleTitle;
        bytes32 linkTelegram;
        bytes32 linkGithub;
        bytes32 linkTwitter;
        bytes32 linkWebsite;
        string linkLogo;
        string description;
        string whitepaper;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyDev {
        require(msg.sender == owner || safeLibrary.getDev() == msg.sender);
        _;
    }

    event PublicPresaleCreated(
        uint256 presaleId,
        address creator,
        address presaleAddress,
        address tokenAddress,
        uint256 timeForLiquidity
    );
    event Received(address indexed from, uint256 amount);

    constructor(address _bscsInfoAddress) {
        safeLibrary = LessLibrary(_bscsInfoAddress);
        owner = msg.sender;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function createPresale(
        PresaleInfo calldata _info,
        PresalePancakeSwapInfo calldata _cakeInfo,
        PresaleStringInfo calldata _stringInfo
    ) external payable returns (uint256 presaleId) {
        require(!safeLibrary.getSignUsed(_info._signature), "used sign");
        // signature check
        require(
            safeLibrary._verifySigner(
                keccak256(abi.encodePacked(
                    _info.tokenAddress,
                    msg.sender,
                    _info._tokenAmount,
                    _info._timestamp
                )),
                _info._signature,
                0
            ),
            "invalid sign"
        );
        require(
            safeLibrary.getMinCreatorStakedBalance() <= _info._tokenAmount,
            "not enough staked tkns"
        );
        //timing check
        require(
            _info.openTime > block.timestamp &&
                _info.openVotingTime + safeLibrary.getVotingTime() + safeLibrary.getRegistrationTime() <= 
                _info.openTime &&
                _info.closeTime - _info.openTime > lastTierTime &&
                _info.closeTime < _cakeInfo.liquidityAllocationTime,
            "timing err"
        );
        require(
            _info.tokenPriceInWei > 0 &&
                _info.softCapInWei > 0 &&
                _info.hardCapInWei > 0 &&
                _info.hardCapInWei >= _info.softCapInWei &&
                _cakeInfo.listingPriceInWei > 0 &&
                _cakeInfo.liquidityPercentageAllocation > 0 &&
                _cakeInfo.lpTokensLockDurationInDays >= 30,
            "Wrong params"
        );

        ERC20 _token = ERC20(_info.tokenAddress);

      
        uint256 feeEth = Calculations.usdtToEthFee(address(safeLibrary));
        // uint256 feeEth = 50000000000000;
        require(msg.value >= feeEth && feeEth > 0, "value<=0");

        // maxLiqPoolTokenAmount, maxTokensToBeSold, requiredTokenAmount
        uint256[] memory tokenAmounts = new uint256[](3);
        
        tokenAmounts = Calculations.countAmountOfTokens(
            _info.hardCapInWei,
            _info.tokenPriceInWei,
            _cakeInfo.listingPriceInWei,
            _cakeInfo.liquidityPercentageAllocation,
            _token.decimals()
        );

        PresalePublic presale = new PresalePublic(
            payable(address(this)),
            address(safeLibrary),
            safeLibrary.owner(),
            safeLibrary.getDev()
        );
        require(
            _token.transferFrom(msg.sender, address(presale), tokenAmounts[2]),
            "cant get ur tkns"
        );
        payable(address(presale)).transfer(feeEth);
        initializePresalePublic(
            presale,
            [tokenAmounts[1], tokenAmounts[0], feeEth],
            _info,
            _cakeInfo,
            _stringInfo
        );
        presaleId = safeLibrary.addPresaleAddress(
            address(presale),
            _stringInfo.saleTitle,
            _stringInfo.description,
            false,
            _info.openVotingTime
        );
        presale.setPresaleId(presaleId);
        safeLibrary.setSingUsed(_info._signature, address(presale));
        emit PublicPresaleCreated(
            presaleId,
            msg.sender,
            address(presale),
            _info.tokenAddress,
            _cakeInfo.liquidityAllocationTime
        );
    }

    function initializePresalePublic(
        PresalePublic _presale,
        uint256[3] memory _tokensForSaleLiquidityFee,
        PresaleInfo calldata _info,
        PresalePancakeSwapInfo calldata _cakeInfo,
        PresaleStringInfo calldata _stringInfo
    ) internal {
        _presale.init(
            [msg.sender, _info.tokenAddress],
            [
                _info.tokenPriceInWei,
                _tokensForSaleLiquidityFee[0],
                _tokensForSaleLiquidityFee[1],
                _info.softCapInWei,
                _info.hardCapInWei,
                _info.openVotingTime,
                _info.openTime,
                _info.closeTime,
                _tokensForSaleLiquidityFee[2]
            ]
        );
        _presale.setUniswapInfo(
            _cakeInfo.listingPriceInWei,
            _cakeInfo.lpTokensLockDurationInDays,
            _cakeInfo.liquidityPercentageAllocation,
            _cakeInfo.liquidityAllocationTime
        );
        _presale.setStringInfo(
            _stringInfo.saleTitle,
            _stringInfo.linkTelegram,
            _stringInfo.linkGithub,
            _stringInfo.linkTwitter,
            _stringInfo.linkWebsite,
            _stringInfo.linkLogo,
            _stringInfo.description,
            _stringInfo.whitepaper
        );
        _presale.setArrays(_info.poolPercentages, _info.stakingTiers);
    }

    function migrateTo(address payable _newFactory) external onlyDev {
        _newFactory.transfer(address(this).balance);
    }
}
