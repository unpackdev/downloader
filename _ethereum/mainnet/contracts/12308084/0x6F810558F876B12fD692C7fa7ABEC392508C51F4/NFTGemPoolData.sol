// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./SafeMath.sol";
import "./Initializable.sol";
import "./INFTGemPoolData.sol";


contract NFTGemPoolData is INFTGemPoolData, Initializable {
    using SafeMath for uint256;

    // it all starts with a symbol and a nams
    string internal _symbol;
    string internal _name;

    // magic economy numbers
    uint256 internal _ethPrice;
    uint256 internal _minTime;
    uint256 internal _maxTime;
    uint256 internal _diffstep;
    uint256 internal _maxClaims;

    mapping(uint256 => uint8) internal _tokenTypes;
    mapping(uint256 => uint256) internal _tokenIds;
    uint256[] internal _tokenHashes;

    // next ids of things
    uint256 internal _nextGemId;
    uint256 internal _nextClaimId;
    uint256 internal _totalStakedEth;

    // records claim timestamp / ETH value / ERC token and amount sent
    mapping(uint256 => uint256) internal claimLockTimestamps;
    mapping(uint256 => address) internal claimLockToken;
    mapping(uint256 => uint256) internal claimAmountPaid;
    mapping(uint256 => uint256) internal claimQuant;
    mapping(uint256 => uint256) internal claimTokenAmountPaid;

    address[] internal _allowedTokens;
    mapping(address => bool) internal _isAllowedMap;

    constructor() {}

    /**
     * @dev The symbol for this pool / NFT
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev The name for this pool / NFT
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev The ether price for this pool / NFT
     */
    function ethPrice() external view override returns (uint256) {
        return _ethPrice;
    }

    /**
     * @dev min time to stake in this pool to earn an NFT
     */
    function minTime() external view override returns (uint256) {
        return _minTime;
    }

    /**
     * @dev max time to stake in this pool to earn an NFT
     */
    function maxTime() external view override returns (uint256) {
        return _maxTime;
    }

    /**
     * @dev difficulty step increase for this pool.
     */
    function difficultyStep() external view override returns (uint256) {
        return _diffstep;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function maxClaims() external view override returns (uint256) {
        return _maxClaims;
    }

    /**
     * @dev number of claims made thus far
     */
    function claimedCount() external view override returns (uint256) {
        return _nextClaimId;
    }

    /**
     * @dev the number of gems minted in this
     */
    function mintedCount() external view override returns (uint256) {
        return _nextGemId;
    }

    /**
     * @dev the number of gems minted in this
     */
    function totalStakedEth() external view override returns (uint256) {
        return _totalStakedEth;
    }

    /**
     * @dev get token type of hash - 1 is for claim, 2 is for gem
     */
    function tokenType(uint256 tokenHash) external view override returns (uint8) {
        return _tokenTypes[tokenHash];
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function tokenId(uint256 tokenHash) external view override returns (uint256) {
        return _tokenIds[tokenHash];
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function allTokenHashesLength() external view override returns (uint256) {
        return _tokenHashes.length;
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function allTokenHashes(uint256 ndx) external view override returns (uint256) {
        return _tokenHashes[ndx];
    }

    /**
     * @dev the external version of the above
     */
    function nextClaimHash() external view override returns (uint256) {
        return _nextClaimHash();
    }

    /**
     * @dev the external version of the above
     */
    function nextGemHash() external view override returns (uint256) {
        return _nextGemHash();
    }

    /**
     * @dev the external version of the above
     */
    function nextClaimId() external view override returns (uint256) {
        return _nextClaimId;
    }

    /**
     * @dev the external version of the above
     */
    function nextGemId() external view override returns (uint256) {
        return _nextGemId;
    }

    /**
     * @dev the external version of the above
     */
    function allowedTokensLength() external view override returns (uint256) {
        return _allowedTokens.length;
    }

    /**
     * @dev the external version of the above
     */
    function allowedTokens(uint256 idx) external view override returns (address) {
        return _allowedTokens[idx];
    }

    /**
     * @dev the external version of the above
     */
    function isTokenAllowed(address token) external view override returns (bool) {
        return _isAllowedMap[token];
    }

    /**
     * @dev the external version of the above
     */
    function addAllowedToken(address token) external override {
        if(!_isAllowedMap[token]) {
            _allowedTokens.push(token);
            _isAllowedMap[token] = true;
        }
    }

    /**
     * @dev the external version of the above
     */
    function removeAllowedToken(address token) external override {
        if(_isAllowedMap[token]) {
            for(uint256 i = 0; i < _allowedTokens.length; i++) {
                if(_allowedTokens[i] == token) {
                   _allowedTokens[i] = _allowedTokens[_allowedTokens.length - 1];
                    delete _allowedTokens[_allowedTokens.length - 1];
                    _isAllowedMap[token] = false;
                    return;
                }
            }
        }
    }

    /**
     * @dev the claim amount for the given claim id
     */
    function claimAmount(uint256 claimHash) external view override returns (uint256) {
        return claimAmountPaid[claimHash];
    }

    /**
     * @dev the claim quantity (count of gems staked) for the given claim id
     */
    function claimQuantity(uint256 claimHash) external view override returns (uint256) {
        return claimQuant[claimHash];
    }

    /**
     * @dev the lock time for this claim. once past lock time a gema is minted
     */
    function claimUnlockTime(uint256 claimHash) external view override returns (uint256) {
        return claimLockTimestamps[claimHash];
    }

    /**
     * @dev claim token amount if paid using erc20
     */
    function claimTokenAmount(uint256 claimHash) external view override returns (uint256) {
        return claimTokenAmountPaid[claimHash];
    }

    /**
     * @dev the staked token if staking with erc20
     */
    function stakedToken(uint256 claimHash) external view override returns (address) {
        return claimLockToken[claimHash];
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function _addToken(uint256 tokenHash, uint8 tt) internal {
        require(tt == 1 || tt == 2, "INVALID_TOKENTYPE");
        _tokenHashes.push(tokenHash);
        _tokenTypes[tokenHash] = tt;
        _tokenIds[tokenHash] = tt == 1 ? __nextClaimId() : __nextGemId();
        if(tt == 2) {
            _increaseDifficulty();
        }
    }

    /**
     * @dev get the next claim id
     */
    function __nextClaimId() private returns (uint256) {
        uint256 ncId = _nextClaimId;
        _nextClaimId = _nextClaimId.add(1);
        return ncId;
    }

    /**
     * @dev get the next gem id
     */
    function __nextGemId() private returns (uint256) {
        uint256 ncId = _nextGemId;
        _nextGemId = _nextGemId.add(1);
        return ncId;
    }

    /**
     * @dev increase the pool's difficulty by calculating the step increase portion and adding it to the eth price of the market
     */
    function _increaseDifficulty() private {
        uint256 diffIncrease = _ethPrice.div(_diffstep);
        _ethPrice = _ethPrice.add(diffIncrease);
    }

    /**
     * @dev the hash of the next gem to be minted
     */
    function _nextGemHash() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked("gem", address(this), _nextGemId)));
    }

    /**
     * @dev the hash of the next claim to be minted
     */
    function _nextClaimHash() internal view returns (uint256) {
        return
            (_maxClaims != 0 && _nextClaimId <= _maxClaims) || _maxClaims == 0
                ? uint256(keccak256(abi.encodePacked("claim", address(this), _nextClaimId)))
                : 0;
    }

}
