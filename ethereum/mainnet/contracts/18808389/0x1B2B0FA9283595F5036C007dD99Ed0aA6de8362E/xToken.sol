// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./Context.sol";
import "./ERC1155Holder.sol";
import "./TransferHelper.sol";
import "./ISwapRouter.sol";
import "./IKeyProtocolVariables.sol";
import "./ILandXNFT.sol";
import "./IxTokenRouter.sol";
import "./IOraclePrices.sol";
import "./IRentFoundation.sol";
import "./IcToken.sol";
import "./IxToken.sol";
import "./ILNDX.sol";
import "./ITWAP.sol";

//xToken NFT in = shards. xToken in = NFT
//1 xToken = (tillableArea * cropShare) /  10000
contract XToken is Context, ERC20Permit, ERC20Burnable, Ownable, ERC1155Holder, IxToken {
     struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    string public crop;
    address public xBasketContract;
    address public lndx;
    address public usdc;

    ILandXNFT public landXNFT; //address of landXNFT
    IxTokenRouter public xTokenRouter; // address of xTokenRouter
    IRentFoundation public rentFoundation;
    IOraclePrices public oraclePrices;
    IKeyProtocolVariables public keyProtocolValues;

    ISwapRouter public uniswapRouter;
    ITWAP public twap;

    //only the initial owner of the NFT can redeem it
    mapping(uint256 => address) public initialOwner;

    mapping(address => uint256) public Claimed;

    mapping(address => Stake) public Staked;
    mapping(address => uint256) public Yield;

    mapping(uint256 => uint256) public SecurityDepositedAmount;

    Stake public TotalStaked;
    uint256 public TotalYield;

    Stake public NonStakedTokens;
    uint256 public NonDistributedYield;

    event Sharded(uint256 nftID, uint256 amount, string name);
    event BuyOut(uint256 nftID, uint256 amount, string name);
    event TokenStaked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);
    event YieldClaimed(address staker, uint256 amount);

    constructor(
        address _landXNFT,
        address _lndx,
        address _usdc,
        address _rentFoundation,
        address _xTokenRouter,
        address _keyProtocolValues,
        address _oraclePrices,
        string memory _crop// "SOY, CORN etc",
    ) ERC20Permit(string(abi.encodePacked("x", _crop))) ERC20("LandX xToken", string(abi.encodePacked("x", _crop))) {
        require(_landXNFT != address(0), "zero address is not allowed");
        require(_lndx != address(0), "zero address is not allowed");
        require(_usdc != address(0), "zero address is not allowed");
        require(_rentFoundation != address(0), "zero address is not allowed");
        require(_xTokenRouter != address(0), "zero address is not allowed");
        require(_keyProtocolValues != address(0), "zero address is not allowed");
        landXNFT = ILandXNFT(_landXNFT);
        crop = _crop;
        lndx = _lndx;
        usdc = _usdc;
        rentFoundation = IRentFoundation(_rentFoundation);
        xTokenRouter = IxTokenRouter(_xTokenRouter);
        keyProtocolValues = IKeyProtocolVariables(_keyProtocolValues);
        oraclePrices = IOraclePrices(_oraclePrices);
        twap = ITWAP(0x5eb612F924dAD205eAb02911b198520eFfE96e5C);
        uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    }

    //deposits an NFT to get shards equivalence
    function getShards(uint256 _id) external {
        require(
            landXNFT.tillableArea(_id) > 0,
            "this NFT has no land area set"
        );
        require(landXNFT.cropShare(_id) > 0, "this NFT has no crop share set");
        require(
            landXNFT.initialOwner(_id) == msg.sender,
            "only initial owner can shard"
        );
        require(
            keccak256(abi.encodePacked(landXNFT.crop(_id))) ==
                keccak256(abi.encodePacked(crop)),
            "wrong crop"
        );
        require(
            xTokenRouter.getXToken(crop) == address(this),
            "tokens are not set for this crop"
        );
        require(
            landXNFT.balanceOf(msg.sender, _id) > 0,
            "you must own this NFT"
        );

        require(
            rentFoundation.initialRentApplied(_id) == false,
            "rent was already applied"
        );

        initialOwner[_id] = msg.sender; //set the initial owner

        //transfers the nft. must have setApprovalForAll
        landXNFT.safeTransferFrom(msg.sender, address(this), _id, 1, "");

        uint256 shards = landXNFT.tillableArea(_id) *
            (landXNFT.cropShare(_id)) *
            (1e6) / 10000; // xTokens has 6 decimal
        _mint(address(this), shards);

        uint256 fee = _calcFee(shards);
        uint256 validatorFee = _validatorFee(_id, shards);

        uint256 annualRent = getAnnualRentAmount(_id);
        uint256 xTokensAnnualRent = ((annualRent * oraclePrices.prices(crop)) /
            oraclePrices.getXTokenPrice(address(this))) * 1e3; // oraclePrices.prices returns price per megatonne, to to get value per KG we multiply by 10 ** 3
        uint256 toSecurityDepositsAmount = (xTokensAnnualRent / 12) *
            keyProtocolValues.securityDepositMonths();

        if (keyProtocolValues.preLaunch()) {
            _transfer(
                address(this),
                keyProtocolValues.landxOperationalWallet(),
                xTokensAnnualRent
            );
            _transfer(
                address(this),
                keyProtocolValues.landxOperationalWallet(),
                fee
            );
        } else {
            // transfer xTokens to securityDeposit
            uint256 usdcFee = _convertToUsdc(fee);
            uint256 usdcAnnualRent = _convertToUsdc(xTokensAnnualRent);
            uint256 toHedgeFund = (usdcAnnualRent *
                keyProtocolValues.hedgeFundAllocation()) / 10000;
            ERC20(usdc).transfer(
                keyProtocolValues.hedgeFundWallet(),
                toHedgeFund
            );
            ERC20(usdc).transfer(
                address(rentFoundation),
                usdcAnnualRent - toHedgeFund
            );
            _feeDistributor(usdcFee);
        }
        _transfer(
            address(this),
            keyProtocolValues.xTokensSecurityWallet(),
            toSecurityDepositsAmount
        );
        if (landXNFT.validator(_id) != address(0)) {
             _transfer(address(this), landXNFT.validator(_id), validatorFee);
        }
        _transfer(
            address(this),
            msg.sender,
            shards - fee - xTokensAnnualRent - toSecurityDepositsAmount - validatorFee
        );
        SecurityDepositedAmount[_id] = toSecurityDepositsAmount;
        rentFoundation.payInitialRent(_id, annualRent);
        _calculateNonDistributedYield();
        emit Sharded(_id, shards, symbol());
    }

    //returns the NFT after if caller has enough xTokens to burn. requires allowance!
    function getTheNFT(uint256 _id) external {
        require(
            initialOwner[_id] == msg.sender,
            "only initial owner can redeem the NFT"
        );

        uint256 remainingRentUSDC;
        remainingRentUSDC = rentFoundation.buyOut(_id);

        uint256 securityDepositedAmount = SecurityDepositedAmount[_id];
        if (rentFoundation.spentSecurityDeposit(_id)) {
            securityDepositedAmount = 0;
        }

        uint256 xTokens = 0;
        if (remainingRentUSDC > 0) {
            xTokens = _convertToXToken(remainingRentUSDC);
        }

        uint256 shards = landXNFT.tillableArea(_id) *
            landXNFT.cropShare(_id) *
            1e6 / 10000; // xToken has 6 decimals

        //approval required for xTokensSecurityWalle
        if (securityDepositedAmount > 0) {
            _burn(keyProtocolValues.xTokensSecurityWallet(), securityDepositedAmount);
        }
        
        _burn(address(this), xTokens);
        
        //burns shards!
        burn(shards - securityDepositedAmount - xTokens);
        _calculateNonDistributedYield();

        //transfer the NFTs
        landXNFT.safeTransferFrom(address(this), msg.sender, _id, 1, "");
        emit BuyOut(_id, shards, symbol());
    }

    function getTheNFTPreview(uint256 _id) public view returns(uint256) {
        bool allow;
        uint256 remainingRentUSDC;
        (allow, remainingRentUSDC) = rentFoundation.buyOutPreview(_id);
        require(allow, "there is a debt");

        uint256 securityDepositedAmount = SecurityDepositedAmount[_id];
        if (rentFoundation.spentSecurityDeposit(_id)) {
            securityDepositedAmount = 0;
        }

        uint256 xTokens = remainingRentUSDC * 1e6 / oraclePrices.getXTokenPrice(address(this)); //xToken has 6 decimals

        uint256 shards = landXNFT.tillableArea(_id) *
            landXNFT.cropShare(_id) *
            1e6 / 10000; // xToken has 6 decimals

        return (shards - securityDepositedAmount - xTokens);
    }


    function stake(uint256 amount) public {
        _transfer(msg.sender, address(this), amount);
        uint256 yield = _calculateYield(Staked[msg.sender]);
        TotalYield += _calculateTotalYield();
        Yield[msg.sender] += yield;
        Staked[msg.sender].startTime = block.timestamp;
        TotalStaked.startTime = block.timestamp;
        TotalStaked.amount += amount;
        Staked[msg.sender].amount += amount;
        _calculateNonDistributedYield();
        emit TokenStaked(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        require(Staked[msg.sender].amount >= amount);
        _transfer(address(this), msg.sender, amount);
        claim();
        Staked[msg.sender].amount -= amount;
        TotalStaked.amount -= amount;
        _calculateNonDistributedYield();
        emit Unstaked(msg.sender, amount);
    }

    function claim() public {
        address cToken = xTokenRouter.getCToken(crop);
        uint256 yield = _calculateYield(Staked[msg.sender]);
        TotalYield =
            TotalYield +
            _calculateTotalYield() -
            (Yield[msg.sender] + yield);
        IcToken(cToken).mint(msg.sender, (Yield[msg.sender] + yield));
        Claimed[msg.sender] += (Yield[msg.sender] + yield);
        Staked[msg.sender].startTime = block.timestamp;
        TotalStaked.startTime = block.timestamp;
        Yield[msg.sender] = 0;
        emit YieldClaimed(msg.sender, yield);
    }

    function _feeDistributor(uint256 _fee) internal {
        uint256 lndxFee = (_fee * keyProtocolValues.lndxHoldersPercentage()) /
            10000;
        uint256 operationalFee = (_fee *
            keyProtocolValues.landXOperationsPercentage()) / 10000;
        ERC20(usdc).transfer(lndx, lndxFee);
        ILNDX(lndx).feeToDistribute(lndxFee);
        ERC20(usdc).transfer(
            keyProtocolValues.landxOperationalWallet(),
            operationalFee
        );
        ERC20(usdc).transfer(
            keyProtocolValues.landxChoiceWallet(),
            _fee - lndxFee - operationalFee
        );
    }

    function availableToClaim(address account) public view returns (uint256) {
        return Yield[account] + _calculateYield(Staked[account]);
    }

    function totalAvailableToClaim() public view returns (uint256) {
        return TotalYield + _calculateTotalYield();
    }

    // calculate cTokanes amount generated since amount was staked
    function _calculateYield(Stake storage s) internal view returns (uint256) {
        uint256 elapsedSeconds = block.timestamp - s.startTime;
        uint256 delimeter = 365 * 1 days;
        return (s.amount * elapsedSeconds) / delimeter;
    }

    function _calculateTotalYield() internal view returns (uint256) {
        uint256 elapsedSeconds = block.timestamp - TotalStaked.startTime;
        uint256 delimeter = 365 * 1 days;
        return (TotalStaked.amount * elapsedSeconds) / delimeter;
    }

    function xBasketTransfer(address _from, uint256 amount) external {
        require(msg.sender == xBasketContract, "not authorized");
        _transfer(_from, xBasketContract, amount);
    }

    // change the address of xBasket.
    function changeXBasketAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "zero address is not allowed");
        xBasketContract = _newAddress;
    }

    function _calcFee(uint256 amount) internal view returns (uint256) {
        uint256 fee = keyProtocolValues.xTokenMintFee();
        return (amount * fee) / 10000;
    }

    function _validatorFee(uint256 tokenID, uint256 amount) internal view returns(uint256) {
        if (landXNFT.validator(tokenID) == address(0)) {
            return 0;
        }
        uint256 validatorFee = landXNFT.validatorFee(tokenID);
        if (validatorFee == 0) {
            return 0;
        }
        return  (amount* validatorFee) / 10000;
    }

    function setXTokenRouter(address _router) public onlyOwner {
        require(_router != address(0), "zero address is not allowed");
        xTokenRouter = IxTokenRouter(_router);
    }

    // return annual rent amount in kg
    function getAnnualRentAmount(uint256 tokenID)
        public
        view
        returns (uint256)
    {
        uint256 rent = landXNFT.cropShare(tokenID);
        uint256 area = landXNFT.tillableArea(tokenID);

        return (rent * area) / 10000;
    }

    function quoteAmountOut(uint _amount) public view returns (uint) {
        uint price = twap.getPrice(address(this), usdc);
        uint256 amountOut = _amount * price / 1e6;
        return amountOut;
    }

    function _convertToXToken(uint256 amount) internal returns (uint256) {
        uint256 slippage =  keyProtocolValues.buyXTokenSlippage();
        uint price = twap.getPrice(usdc, address(this));
        uint256 predictedAmountOut = amount * price / 10 ** decimals();
        uint256 minAmountOut = predictedAmountOut * 10000 / (10000 + slippage);

        TransferHelper.safeApprove(usdc, address(uniswapRouter), amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams(
            usdc,
            address(this),
            3000,
            address(this),
            block.timestamp + 15,
            amount,
            minAmountOut,
            0
        );
        return uniswapRouter.exactInputSingle(params);
    }

    function _convertToUsdc(uint256 amount) internal returns (uint256) {
        uint256 slippage =  keyProtocolValues.sellXTokenSlippage();
        uint256 predictedAmountOut = quoteAmountOut(amount);
        uint256 minAmountOut = predictedAmountOut * 10000 / (10000 + slippage);

        TransferHelper.safeApprove(
            address(this),
            address(uniswapRouter),
            amount
        );
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams(
            address(this),
            usdc,
            3000,
            address(this),
            block.timestamp + 15,
            amount,
            minAmountOut,
            0
        );
        return uniswapRouter.exactInputSingle(params);
    }

    function preview(uint256 id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(landXNFT.tillableArea(id) > 0, "this NFT has no land area set");
        require(landXNFT.cropShare(id) > 0, "this NFT has no crop share set");
        require(
            keccak256(abi.encodePacked(landXNFT.crop(id))) ==
                keccak256(abi.encodePacked(crop)),
            "wrong crop"
        );
        require(
            xTokenRouter.getXToken(landXNFT.crop(id)) == address(this),
            "Unable to shard this NFT"
        );
        
        uint256 shards = (landXNFT.tillableArea(id) *
            landXNFT.cropShare(id) *
            1e6) / 10000;
        uint256 annualRent = getAnnualRentAmount(id);
        uint256 xTokensAnnualRent = ((annualRent * oraclePrices.prices(crop)) /
            oraclePrices.getXTokenPrice(xTokenRouter.getXToken(crop))) * 1e3;
        uint256 toSecurityDepositsAmount = (xTokensAnnualRent / 12) *
            keyProtocolValues.securityDepositMonths();
        uint256 fee = _calcFee(shards);
        uint256 validatorFee = _validatorFee(id, shards);
        uint256 toBeReceived = shards -
            fee -
            xTokensAnnualRent -
            toSecurityDepositsAmount - validatorFee;
        return (
            shards,
            fee,
            xTokensAnnualRent + toSecurityDepositsAmount,
            toBeReceived
        );
    }

    function _calculateNonDistributedYield() internal {
        uint256 elapsedSeconds = block.timestamp - NonStakedTokens.startTime;
        uint256 delimeter = 365 * 1 days;
        NonDistributedYield += NonStakedTokens.amount * elapsedSeconds / delimeter;
        NonStakedTokens.amount = totalSupply() - TotalStaked.amount;
        NonStakedTokens.startTime = block.timestamp;
    }

    function previewNonDistributedYield() external view returns(uint256) {
        uint256 elapsedSeconds = block.timestamp - NonStakedTokens.startTime;
        uint256 delimeter = 365 * 1 days;
        return NonDistributedYield + NonStakedTokens.amount * elapsedSeconds / delimeter;
    }

    // returns cTokens amount
    function getNonDistributedYield() external returns(uint256) {
        require(msg.sender == address(rentFoundation), "only rentFoundation can take it");
        _calculateNonDistributedYield();
        uint256 amount = NonDistributedYield;
        NonDistributedYield = 0;
        return amount;
    }

    function renounceOwnership() public view override onlyOwner {
        revert ("can 't renounceOwnership here");
    }

    // for test only purposes
    function updateUniswapContracts(address _twap, address _uniswapRouter) public onlyOwner {
        twap = ITWAP(_twap);
        uniswapRouter = ISwapRouter(_uniswapRouter);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}