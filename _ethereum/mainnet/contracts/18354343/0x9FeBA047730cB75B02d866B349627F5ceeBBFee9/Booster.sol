// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./Ownable.sol";
import "./IToken.sol";
import "./IBondedToken.sol";
import "./ECDSA.sol";


contract Booster is Ownable {
    using ECDSA for bytes32;

    IToken public muonToken;
    IERC20 public usdcToken;

    IBondedToken public bondedToken;

    address public treasury;

    IUniswapV2Pair public uniswapV2Pair;

    // multiplier * 1e18
    uint256 public boostValue;

    uint256 public signatureValidityPeriod = 300;

    uint8 public tolerancePercentage = 5;

    address public signer;

    event Boosted(
        uint256 indexed nftId,
        address indexed addr,
        uint256 usdcAmount,
        uint256 tokenPrice,
        uint256 boostedAmount
    );

    constructor(
        address muonTokenAddress,
        address usdcAddress,
        address bondedTokenAddress,
        address _treasury,
        address _uniswapV2Pair,
        uint256 _boostValue,
        address _signer
    ){
        muonToken = IToken(muonTokenAddress);
        usdcToken = IERC20(usdcAddress);
        bondedToken = IBondedToken(bondedTokenAddress);

        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);

        treasury = _treasury;
        boostValue = _boostValue;
        signer = _signer;
    }

    function boost(
        uint256 nftId,
        uint256 amount, 
        uint256 signedPrice,
        uint256 timestamp,
        bytes memory signature
    ) public {
        require(amount > 0, "0 amount");
        require(
            block.timestamp <= timestamp + signatureValidityPeriod,
            "Signature expired."
        );

        bytes32 messageHash = keccak256(
            abi.encodePacked(msg.sender, signedPrice, timestamp)
        );
        messageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = messageHash.recover(signature);
        require(recoveredSigner == signer, "Invalid signature.");

        require(
            usdcToken.transferFrom(msg.sender, treasury, amount),
            "transferFrom error"
        );

        (uint112 reserve0, uint112 reserve1, ) = uniswapV2Pair.getReserves();

        uint256 muonAmountOnchain;
        if (uniswapV2Pair.token0() == address(usdcToken)) {
            muonAmountOnchain = (amount * reserve1) / reserve0;
        } else {
            muonAmountOnchain = (amount * reserve0) / reserve1;
        }

        uint256 muonAmount = amount * signedPrice / 1e18;

        require(validateAmount(muonAmountOnchain, muonAmount), 
            "Invalid oracle price");

        // allow 5% tolerance to handle slippage
        require(muonAmount <= (getBoostableAmount(nftId)*(100+tolerancePercentage)/100), "> boostableAmount");

        address[] memory tokens = new address[](1);
        tokens[0] = address(muonToken);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = (muonAmount * boostValue) / 1e18;

        bondedToken.addBoostedBalance(nftId, amounts[0]+muonAmount);

        muonToken.mint(address(this), amounts[0]);
        muonToken.approve(address(bondedToken), amounts[0]);
        
        bondedToken.lock(nftId, tokens, amounts);
        
        emit Boosted(
            nftId,
            msg.sender,
            amount,
            signedPrice,
            amounts[0]
        );
    }

    function createAndBoost(uint256 muonAmount, uint256 usdcAmount,
        uint256 signedPrice,
        uint256 timestamp,
        bytes memory signature) public returns(uint256){
        require(muonAmount > 0 && usdcAmount > 0, "0 amount");
        require(
            muonToken.transferFrom(msg.sender, address(this), muonAmount),
            "transferFrom error"
        );
        address[] memory tokens = new address[](1);
        tokens[0] = address(muonToken);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = muonAmount;

        muonToken.approve(address(bondedToken), muonAmount);
        uint256 nftId = bondedToken.mintAndLock(tokens, amounts, msg.sender);
        
        boost(nftId, usdcAmount, signedPrice, timestamp, signature);
        return nftId;
    }

    function adminWithdraw(
        uint256 amount,
        address _to,
        address _tokenAddr
    ) public onlyOwner {
        require(_to != address(0));
        if (_tokenAddr == address(0)) {
            payable(_to).transfer(amount);
        } else {
            IERC20(_tokenAddr).transfer(_to, amount);
        }
    }

    /// @notice Sets the treasury address
    /// @param _treasury The new treasury address
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "0x0 treasury");
        treasury = _treasury;
    }

    /// @notice Sets the boostValue
    /// @param _value The new boost value
    function setBoostValue(uint256 _value) external onlyOwner {
        boostValue = _value;
    }

    function setTokenInfo(IERC20 _usdc, IUniswapV2Pair _pair) external onlyOwner {
        usdcToken = _usdc;
        uniswapV2Pair = _pair;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setSignatureValidityPeriod(uint256 _newValidityPeriod)
        external
        onlyOwner
    {
        signatureValidityPeriod = _newValidityPeriod;
    }

    function setTolerancePercentage(uint8 percentage)
        external
        onlyOwner
    {
        tolerancePercentage = percentage;
    }

    function getBoostableAmount(
        uint256 nftId
    ) public view returns(uint256){
        address[] memory tokens = new address[](1);
        tokens[0] = address(muonToken);
        uint256 balance = bondedToken.getLockedOf(nftId, tokens)[0];
        uint256 boostedBalance = bondedToken.boostedBalance(nftId);

        return boostedBalance >= balance ? 0 : balance-boostedBalance;
    }

    function validateAmount(
        uint256 chainAmount,
        uint256 oracleAmount
    ) public view returns(bool){
        uint256 maxPrice = chainAmount*(100+tolerancePercentage)/100;
        uint256 minPrice = chainAmount*(100-tolerancePercentage)/100;
        if(oracleAmount > maxPrice || oracleAmount < minPrice){
            return false;
        }
        return true;
    }
}
