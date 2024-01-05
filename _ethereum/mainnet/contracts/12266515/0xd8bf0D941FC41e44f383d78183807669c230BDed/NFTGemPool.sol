// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./Initializable.sol";
import "./INFTGemMultiToken.sol";
import "./INFTGemFeeManager.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./INFTGemPool.sol";
import "./INFTGemGovernor.sol";
import "./ISwapQueryHelper.sol";

import "./SafeMath.sol";
import "./NFTGemPoolData.sol";

contract NFTGemPool is Initializable, NFTGemPoolData, INFTGemPool {
    using SafeMath for uint256;

    // governor and multitoken target
    address private _multitoken;
    address private _governor;
    address private _feeTracker;
    address private _swapHelper;

    /**
     * @dev initializer called when contract is deployed
     */
    function initialize (
        string memory __symbol,
        string memory __name,
        uint256 __ethPrice,
        uint256 __minTime,
        uint256 __maxTime,
        uint256 __diffstep,
        uint256 __maxClaims,
        address __allowedToken
    ) external override initializer {
        _symbol = __symbol;
        _name = __name;
        _ethPrice = __ethPrice;
        _minTime = __minTime;
        _maxTime = __maxTime;
        _diffstep = __diffstep;
        _maxClaims = __maxClaims;

        if(__allowedToken != address(0)) {
            _allowedTokens.push(__allowedToken);
            _isAllowedMap[__allowedToken] = true;
        }
    }

    /**
     * @dev set the governor. pool uses the governor to issue gov token issuance requests
     */
    function setGovernor(address addr) external override {
        require(_governor == address(0), "IMMUTABLE");
        _governor = addr;
    }

    /**
     * @dev set the governor. pool uses the governor to issue gov token issuance requests
     */
    function setFeeTracker(address addr) external override {
        require(_feeTracker == address(0), "IMMUTABLE");
        _feeTracker = addr;
    }

    /**
     * @dev set the multitoken that this pool will mint new tokens on. Must be a controller of the multitoken
     */
    function setMultiToken(address token) external override {
        require(_multitoken == address(0), "IMMUTABLE");
        _multitoken = token;
    }

    /**
     * @dev set the multitoken that this pool will mint new tokens on. Must be a controller of the multitoken
     */
    function setSwapHelper(address helper) external override {
        require(_swapHelper == address(0), "IMMUTABLE");
        _swapHelper = helper;
    }

    /**
     * @dev mint the genesis gems earned by the pools creator and funder
     */
    function mintGenesisGems(address creator, address funder) external override {
        require(_multitoken != address(0), "NO_MULTITOKEN");
        require(creator != address(0) && funder != address(0), "ZERO_DESTINATION");
        require(_nextGemId == 0, "ALREADY_MINTED");

        uint256 gemHash = _nextGemHash();
        INFTGemMultiToken(_multitoken).mint(creator, gemHash, 1);
        _addToken(gemHash, 2);

        gemHash = _nextGemHash();
        INFTGemMultiToken(_multitoken).mint(creator, gemHash, 1);
        _addToken(gemHash, 2);
    }

    /**
     * @dev the external version of the above
     */
    function createClaim(uint256 timeframe) external payable override {
        _createClaim(timeframe);
    }

    /**
     * @dev the external version of the above
     */
    function createClaims(uint256 timeframe, uint256 count) external payable override {
        _createClaims(timeframe, count);
    }

    /**
     * @dev create a claim using a erc20 token
     */
    function createERC20Claim(address erc20token, uint256 tokenAmount) external override {
        _createERC20Claim(erc20token, tokenAmount);
    }

    /**
     * @dev create a claim using a erc20 token
     */
    function createERC20Claims(address erc20token, uint256 tokenAmount, uint256 count) external override {
        _createERC20Claims(erc20token, tokenAmount, count);
    }


    /**
     * @dev default receive. tries to issue a claim given the received ETH or
     */
    receive() external payable {
        uint256 incomingEth = msg.value;

        // compute the mimimum cost of a claim and revert if not enough sent
        uint256 minClaimCost = _ethPrice.div(_maxTime).mul(_minTime);
        require(incomingEth >= minClaimCost, "INSUFFICIENT_ETH");

        // compute the minimum actual claim time
        uint256 actualClaimTime = _minTime;

        // refund ETH above max claim cost
        if (incomingEth <= _ethPrice)  {
            actualClaimTime = _ethPrice.div(incomingEth).mul(_minTime);
        }

        // create the claim using minimum possible claim time
        _createClaim(actualClaimTime);
    }

    /**
     * @dev attempt to create a claim using the given timeframe
     */
    function _createClaim(uint256 timeframe) internal {
        // minimum timeframe
        require(timeframe >= _minTime, "TIMEFRAME_TOO_SHORT");

        // maximum timeframe
        require((_maxTime != 0 && timeframe <= _maxTime) || _maxTime == 0, "TIMEFRAME_TOO_LONG");

        // cost given this timeframe
        uint256 cost = _ethPrice.mul(_minTime).div(timeframe);
        require(msg.value > cost, "INSUFFICIENT_ETH");

        // get the nest claim hash, revert if no more claims
        uint256 claimHash = _nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // mint the new claim to the caller's address
        INFTGemMultiToken(_multitoken).mint(msg.sender, claimHash, 1);
        _addToken(claimHash, 1);

        // record the claim unlock time and cost paid for this claim
        uint256 _claimUnlockTime = block.timestamp.add(timeframe);
        claimLockTimestamps[claimHash] = _claimUnlockTime;
        claimAmountPaid[claimHash] = cost;
        claimQuant[claimHash] = 1;

        // increase the staked eth balance
        _totalStakedEth = _totalStakedEth.add(cost);

        // maybe mint a governance token for the claimant
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, cost);

        emit NFTGemClaimCreated(msg.sender, address(this), claimHash, timeframe, 1, cost);

        if (msg.value > cost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value.sub(cost)}("");
            require(success, "REFUND_FAILED");
        }
    }

    /**
     * @dev attempt to create a claim using the given timeframe
     */
    function _createClaims(uint256 timeframe, uint256 count) internal {
        // minimum timeframe
        require(timeframe >= _minTime, "TIMEFRAME_TOO_SHORT");
        // no ETH
        require(msg.value != 0, "ZERO_BALANCE");
        // zero qty
        require(count != 0, "ZERO_QUANTITY");
        // maximum timeframe
        require((_maxTime != 0 && timeframe <= _maxTime) || _maxTime == 0, "TIMEFRAME_TOO_LONG");

        uint256 adjustedBalance = msg.value.div(count);
        // cost given this timeframe

        uint256 cost = _ethPrice.mul(_minTime).div(timeframe);
        require(adjustedBalance >= cost, "INSUFFICIENT_ETH");

        // get the nest claim hash, revert if no more claims
        uint256 claimHash = _nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // mint the new claim to the caller's address
        INFTGemMultiToken(_multitoken).mint(msg.sender, claimHash, 1);
        _addToken(claimHash, 1);

        // record the claim unlock time and cost paid for this claim
        uint256 _claimUnlockTime = block.timestamp.add(timeframe);
        claimLockTimestamps[claimHash] = _claimUnlockTime;
        claimAmountPaid[claimHash] = cost;
        claimQuant[claimHash] = count;

        // maybe mint a governance token for the claimant
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, cost);

        emit NFTGemClaimCreated(msg.sender, address(this), claimHash, timeframe, count, cost);

        // increase the staked eth balance
        _totalStakedEth = _totalStakedEth.add(cost.mul(count));

        if (msg.value > cost.mul(count)) {
            (bool success, ) = payable(msg.sender).call{value: msg.value.sub(cost.mul(count))}("");
            require(success, "REFUND_FAILED");
        }
    }

    /**
     * @dev crate a gem claim using an erc20 token. this token must be tradeable in Uniswap or this call will fail
     */
    function _createERC20Claim(address erc20token, uint256 tokenAmount) internal {
        // must be a valid address
        require(erc20token != address(0), "INVALID_ERC20_TOKEN");

        // token is allowed
        require((_allowedTokens.length > 0 && _isAllowedMap[erc20token]) || _allowedTokens.length == 0, "TOKEN_DISALLOWED");

        // Uniswap pool must exist
        require(ISwapQueryHelper(_swapHelper).hasPool(erc20token) == true, "NO_UNISWAP_POOL");

        // must have an amount specified
        require(tokenAmount >= 0, "NO_PAYMENT_INCLUDED");

        // get a quote in ETH for the given token.
        (uint256 ethereum, uint256 tokenReserve, uint256 ethReserve) = ISwapQueryHelper(_swapHelper).coinQuote(erc20token, tokenAmount);

        // get the min liquidity from fee tracker
        uint256 liquidity = INFTGemFeeManager(_feeTracker).liquidity(erc20token);

        // make sure the convertible amount is has reserves > 100x the token
        require(ethReserve >= ethereum.mul(liquidity), "INSUFFICIENT_ETH_LIQUIDITY");

        // make sure the convertible amount is has reserves > 100x the token
        require(tokenReserve >= tokenAmount.mul(liquidity), "INSUFFICIENT_TOKEN_LIQUIDITY");

        // make sure the convertible amount is less than max price
        require(ethereum <= _ethPrice, "OVERPAYMENT");

        // calculate the maturity time given the converted eth
        uint256 maturityTime = _ethPrice.mul(_minTime).div(ethereum);

        // make sure the convertible amount is less than max price
        require(maturityTime >= _minTime, "INSUFFICIENT_TIME");

        // get the next claim hash, revert if no more claims
        uint256 claimHash = _nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // transfer the caller's ERC20 tokens into the pool
        IERC20(erc20token).transferFrom(msg.sender, address(this), tokenAmount);

        // mint the new claim to the caller's address
        INFTGemMultiToken(_multitoken).mint(msg.sender, claimHash, 1);
        _addToken(claimHash, 1);

        // record the claim unlock time and cost paid for this claim
        uint256 _claimUnlockTime = block.timestamp.add(maturityTime);
        claimLockTimestamps[claimHash] = _claimUnlockTime;
        claimAmountPaid[claimHash] = ethereum;
        claimLockToken[claimHash] = erc20token;
        claimTokenAmountPaid[claimHash] = tokenAmount;
        claimQuant[claimHash] = 1;

        _totalStakedEth = _totalStakedEth.add(ethereum);

        // maybe mint a governance token for the claimant
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, ethereum);

        // emit a message indicating that an erc20 claim has been created
        emit NFTGemERC20ClaimCreated(msg.sender, address(this), claimHash, maturityTime, erc20token, 1, ethereum);
    }

    /**
     * @dev crate multiple gem claim using an erc20 token. this token must be tradeable in Uniswap or this call will fail
     */
    function _createERC20Claims(address erc20token, uint256 tokenAmount, uint256 count) internal {
        // must be a valid address
        require(erc20token != address(0), "INVALID_ERC20_TOKEN");

        // token is allowed
        require((_allowedTokens.length > 0 && _isAllowedMap[erc20token]) || _allowedTokens.length == 0, "TOKEN_DISALLOWED");

        // zero qty
        require(count != 0, "ZERO_QUANTITY");

        // Uniswap pool must exist
        require(ISwapQueryHelper(_swapHelper).hasPool(erc20token) == true, "NO_UNISWAP_POOL");

        // must have an amount specified
        require(tokenAmount >= 0, "NO_PAYMENT_INCLUDED");

        // get a quote in ETH for the given token.
        (uint256 ethereum, uint256 tokenReserve, uint256 ethReserve) = ISwapQueryHelper(_swapHelper).coinQuote(
            erc20token,
            tokenAmount.div(count)
        );

        // make sure the convertible amount is has reserves > 100x the token
        require(ethReserve >= ethereum.mul(100).mul(count), "INSUFFICIENT_ETH_LIQUIDITY");

        // make sure the convertible amount is has reserves > 100x the token
        require(tokenReserve >= tokenAmount.mul(100).mul(count), "INSUFFICIENT_TOKEN_LIQUIDITY");

        // make sure the convertible amount is less than max price
        require(ethereum <= _ethPrice, "OVERPAYMENT");

        // calculate the maturity time given the converted eth
        uint256 maturityTime = _ethPrice.mul(_minTime).div(ethereum);

        // make sure the convertible amount is less than max price
        require(maturityTime >= _minTime, "INSUFFICIENT_TIME");

        // get the next claim hash, revert if no more claims
        uint256 claimHash = _nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // mint the new claim to the caller's address
        INFTGemMultiToken(_multitoken).mint(msg.sender, claimHash, 1);
        _addToken(claimHash, 1);

        // record the claim unlock time and cost paid for this claim
        uint256 _claimUnlockTime = block.timestamp.add(maturityTime);
        claimLockTimestamps[claimHash] = _claimUnlockTime;
        claimAmountPaid[claimHash] = ethereum;
        claimLockToken[claimHash] = erc20token;
        claimTokenAmountPaid[claimHash] = tokenAmount;
        claimQuant[claimHash] = count;

        // increase staked eth amount
        _totalStakedEth = _totalStakedEth.add(ethereum);

        // maybe mint a governance token for the claimant
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, ethereum);

        // emit a message indicating that an erc20 claim has been created
        emit NFTGemERC20ClaimCreated(msg.sender, address(this), claimHash, maturityTime, erc20token, count, ethereum);

        // transfer the caller's ERC20 tokens into the pool
        IERC20(erc20token).transferFrom(msg.sender, address(this), tokenAmount);
    }

    /**
     * @dev collect an open claim (take custody of the funds the claim is redeeemable for and maybe a gem too)
     */
    function collectClaim(uint256 claimHash) external override {
        // validation checks - disallow if not owner (holds coin with claimHash)
        // or if the unlockTime amd unlockPaid data is in an invalid state
        require(IERC1155(_multitoken).balanceOf(msg.sender, claimHash) == 1, "NOT_CLAIM_OWNER");
        uint256 unlockTime = claimLockTimestamps[claimHash];
        uint256 unlockPaid = claimAmountPaid[claimHash];
        require(unlockTime != 0 && unlockPaid > 0, "INVALID_CLAIM");

        // grab the erc20 token info if there is any
        address tokenUsed = claimLockToken[claimHash];
        uint256 unlockTokenPaid = claimTokenAmountPaid[claimHash];

        // check the maturity of the claim - only issue gem if mature
        bool isMature = unlockTime < block.timestamp;

        //  burn claim and transfer money back to user
        INFTGemMultiToken(_multitoken).burn(msg.sender, claimHash, 1);

        // if they used erc20 tokens stake their claim, return their tokens
        if (tokenUsed != address(0)) {
            // calculate fee portion using fee tracker
            uint256 feePortion = 0;
            if (isMature == true) {
                uint256 poolDiv = INFTGemFeeManager(_feeTracker).feeDivisor(address(this));
                uint256 divisor = INFTGemFeeManager(_feeTracker).feeDivisor(tokenUsed);
                uint256 feeNum = poolDiv != divisor ? divisor : poolDiv;
                feePortion = unlockTokenPaid.div(feeNum);
            }
            // assess a fee for minting the NFT. Fee is collectec in fee tracker
            IERC20(tokenUsed).transferFrom(address(this), _feeTracker, feePortion);
            // send the principal minus fees to the caller
            IERC20(tokenUsed).transferFrom(address(this), msg.sender, unlockTokenPaid.sub(feePortion));

            // emit an event that the claim was redeemed for ERC20
            emit NFTGemERC20ClaimRedeemed(
                msg.sender,
                address(this),
                claimHash,
                tokenUsed,
                unlockPaid,
                unlockTokenPaid,
                feePortion
            );
        } else {
            // calculate fee portion using fee tracker
            uint256 feePortion = 0;
            if (isMature == true) {
                uint256 divisor = INFTGemFeeManager(_feeTracker).feeDivisor(address(0));
                feePortion = unlockPaid.div(divisor);
            }
            // transfer the ETH fee to fee tracker
            payable(_feeTracker).transfer(feePortion);
            // transfer the ETH back to user
            payable(msg.sender).transfer(unlockPaid.sub(feePortion));

            // emit an event that the claim was redeemed for ETH
            emit NFTGemClaimRedeemed(msg.sender, address(this), claimHash, unlockPaid, feePortion);
        }

        // deduct the total staked ETH balance of the pool
        _totalStakedEth = _totalStakedEth.sub(unlockPaid);

        // if all this is happening before the unlocktime then we exit
        // without minting a gem because the user is withdrawing early
        if (!isMature) {
            return;
        }

        // get the next gem hash, increase the staking sifficulty
        // for the pool, and mint a gem token back to account
        uint256 nextHash = this.nextGemHash();

        // mint the gem
        INFTGemMultiToken(_multitoken).mint(msg.sender, nextHash, claimQuant[claimHash]);
        _addToken(nextHash, 2);

        // maybe mint a governance token
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, unlockPaid);

        // emit an event about a gem getting created
        emit NFTGemCreated(msg.sender, address(this), claimHash, nextHash, claimQuant[claimHash]);
    }

}
