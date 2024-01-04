// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./IHegicOptions.sol";
import "./IPriceProvider.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

/**
 * @author jmonteer
 * @title Hegic NFT options
 * @notice ERC721 that holds Hegic Options 
 */
abstract contract HegicOptionsNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    event Created(
        address indexed account,
        uint indexed tokenId,
        uint indexed optionId
    );

    event Tokenized(
        address indexed account,
        uint indexed tokenId,
        uint indexed optionId
    );

    event Detokenized(
        address indexed account,
        uint indexed tokenId,
        uint indexed optionId,
        bool burned
    );

    event Exercised(
        address indexed account,
        uint indexed tokenId,
        uint indexed optionId,
        uint profit
    );

    IHegicOptions public optionsProvider;
    IPriceProvider public priceProvider;

    // tokenId => underlyingOptionId
    mapping(uint => uint) public underlyingOptionId;

    // optionId => tokenId
    mapping(uint => uint) public holdingToken;

    // tokenId => (cached 'is the underlying Option owned by the contract?')
    mapping(uint => bool) ownedByThis;

    // tokenId => target price at which will be auto exercised
    mapping(uint => uint) public targetPrice;

    address public autoExerciser = address(0x6b405609B78241112a3030E8a85570F06fbd3aca);
    mapping(address => bool) public autoExerciseDisabled;

    constructor(string memory _name, string memory _symbol) public ERC721(_name, _symbol){}

    function setAutoExerciser(address _autoExerciser) external onlyOwner {
        autoExerciser = _autoExerciser;
    }

    function setTargetPrice(uint _tokenId, uint _newTargetPrice) external onlyTokenOwnerOrApproved(_tokenId) {
        targetPrice[_tokenId] = _newTargetPrice;
    }

    function setAutoExerciseDisabled(bool disabled) external {
        autoExerciseDisabled[msg.sender] = disabled;
    }

    /**
     * @notice Creates a new option and tokenizes it
     * @param _period Option period in seconds (1 days <= period <= 4 weeks)
     * @param _amount Option amount
     * @param _strike Strike price of the option
     * @param _optionType Call or Put option type
     * @return newTokenId ID of the token that holds that specific option
     */
    function createOption(
        uint _period,
        uint _amount,
        uint _strike,
        IHegicOptions.OptionType _optionType,
        address _to
    ) 
        payable
        external
        returns (uint newTokenId)
    {   
        uint optionId = optionsProvider.create{value: msg.value}(_period, _amount, _strike, _optionType);
        if(address(this).balance > 0) _transferBalance(msg.sender); // if sender sent more than needed, contract will return excess
        newTokenId = tokenize(optionId, _to);
        
        emit Created(_to, newTokenId, optionId);
    }

    /**
     * @notice Exercises underlying option
     * @param _tokenId ID of the token that holds the option to be exercised
     */
    function exerciseOption(uint _tokenId) external onlyTokenOwnerOrApproved(_tokenId) returns (uint profit){
        uint optionId = underlyingOptionId[_tokenId];
        optionsProvider.exercise(optionId);
        profit = _transferBalance(msg.sender);
        
        emit Exercised(ownerOf(_tokenId), _tokenId, optionId, profit);
    }

    function exercise(uint _tokenId) external returns (address, uint256){
        require(msg.sender == autoExerciser, "HONFT/not-authorized");
        require(isAutoExercisable(_tokenId), "HONFT/not-exercisable");

        uint optionId = underlyingOptionId[_tokenId];
        optionsProvider.exercise(optionId);

        uint profit = _transferBalance(msg.sender);

        address owner = ownerOf(_tokenId);
        
        emit Exercised(owner, _tokenId, optionId, profit);

        return (owner, profit);
    }

    function isAutoExercisable(uint _tokenId) public view returns (bool) {
        if(autoExerciseDisabled[ownerOf(_tokenId)]) return false;

        (IHegicOptions.State state, , uint strike, , , , uint expiration , IHegicOptions.OptionType optionType) = getUnderlyingOptionParams(_tokenId);

        if(state != IHegicOptions.State.Active || expiration < block.timestamp) {
            return false;
        }

        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        uint currentPrice = uint(latestPrice);

        bool ITM = false;

        if(optionType == IHegicOptions.OptionType.Call) {
            ITM = currentPrice > strike;
        } else if (optionType == IHegicOptions.OptionType.Put) {
            ITM = currentPrice < strike;
        }

        // if option is In The Money and the option is going to expire in the next minutes
        if (ITM && (expiration.sub(30 minutes) <= block.timestamp)) {
            return true;
        }

        // exercisable if underlying reached target price
        uint target = targetPrice[_tokenId];
        if (optionType == IHegicOptions.OptionType.Call && target != 0) {
            return (currentPrice >= target) && ITM;
        } else if (optionType == IHegicOptions.OptionType.Put && target != 0) {
            return (currentPrice <= target) && ITM;
        }

        return false;
    }

    /**
     * @notice External function for tokenizing an option.
     * @dev User has to transfer option's ownership for the token to be transferable.
     * It will revert if the holder of the to be tokenized option is not msg.sender
     * @param _optionId ID of the option to be tokenized
     * @return newTokenId ID of the token that holds that specific option
     */
    function tokenizeOption(uint _optionId, address _to) external returns (uint newTokenId) {
        (, address holder, , , , , ,) = optionsProvider.options(_optionId);
        require(holder != address(this), "HONFT/already-tokenized");
        require(holder == msg.sender, "HONFT/invalid-holder");
        newTokenId = tokenize(_optionId, _to);
    }

    /**
     * @notice Transfers underlying option's ownership to tokenholder. Optionally, it burns the token
     * @param _tokenId ID of the token that holds the option to be detokenized
     * @param _burnToken True to burn the token, false to keep the token
     */
    function detokenizeOption(uint _tokenId, bool _burnToken) external onlyTokenOwnerOrApproved(_tokenId) {
        require(checkValidToken(_tokenId), "HONFT/option-not-owned-by-contract");
        uint optionId = underlyingOptionId[_tokenId];
        address owner = ownerOf(_tokenId);
        // checks if optionsProvider will allow to transfer option ownership
        (IHegicOptions.State state, , , , , , uint expiration , ) = getUnderlyingOptionParams(_tokenId);
        if(state == IHegicOptions.State.Active && expiration > block.timestamp)
            optionsProvider.transfer(optionId, payable(ownerOf(_tokenId)));
        
        delete ownedByThis[_tokenId];
        
        if(_burnToken) {
            delete holdingToken[optionId];
            _burn(_tokenId);
        }
            
        emit Detokenized(owner, _tokenId, optionId, _burnToken);
    }

    /**
     * @notice Tokenizes an existing option
     * @dev User has to transfer option's ownership for the token to be transferable
     * @param _optionId ID of the option to be tokenized
     * @return newTokenId ID of the token that holds that specific option
     */
    function tokenize(uint _optionId, address _to) 
        internal
        returns (uint newTokenId) {
        _tokenIds.increment();
        newTokenId = _tokenIds.current();

        underlyingOptionId[newTokenId] = _optionId;

        // if this option Id has already been minted and is owned by another account
        // the previously minted token will be burnt
        uint _holdingToken = holdingToken[_optionId];
        if(_holdingToken != 0) {
            (, address holder, , , , , ,) = getUnderlyingOptionParams(_holdingToken);
            require(holder != address(this), "HONFT/already-tokenized");
            _burn(_holdingToken);
        }
        
        holdingToken[_optionId] = newTokenId;

        _mint(_to, newTokenId);

        emit Tokenized(_to, newTokenId, _optionId);
    }

    /**
     * @notice Burns NFT if it does not hold any option
     * @param _tokenId ID of the token to be burnt
     */
    function burnToken(uint _tokenId) external onlyTokenOwnerOrApproved(_tokenId) {
        (IHegicOptions.State state, , , , , , uint expiration , ) = getUnderlyingOptionParams(_tokenId);
        
        // only allows to burn inactive options, even if still owned by the contract
        if(state == IHegicOptions.State.Active || expiration > block.timestamp)
            require(!ownedByThis[_tokenId], "HONFT/cannot-burn-option");

        delete holdingToken[underlyingOptionId[_tokenId]];
        _burn(_tokenId);
    }

    /**
     * @notice Returns cost in ETH of buying an option with passed params
     * @param _period Option period in seconds (1 days <= period <= 4 weeks)
     * @param _amount Option amount
     * @param _strike Strike price of the option
     * @param _optionType Call or Put option type
     * @return ethCost cost of the option
     */
    function getOptionCostETH(
        uint _period,
        uint _amount,
        uint _strike,
        IHegicOptions.OptionType _optionType
    ) 
        external
        view
        virtual
        returns (uint ethCost);

    /**
     * @notice Returns the underlying option Id
     * @param _tokenId ID of the token to be queried
     */
    function getUnderlyingOptionId(uint _tokenId) external view returns (uint) {
        require(_exists(_tokenId), "HONFT/invalid-token-id");
        return underlyingOptionId[_tokenId];
    }

    /**
     * @notice Returns underlying options params
     * @param _tokenId ID of the token to be queried
     * @return state
     * @return holder
     * @return strike
     * @return amount
     * @return lockedAmount
     * @return premium
     * @return expiration
     * @return optionType
     */
    function getUnderlyingOptionParams(uint _tokenId) 
        public
        view 
        returns (
        IHegicOptions.State state,
        address payable holder,
        uint256 strike,
        uint256 amount,
        uint256 lockedAmount,
        uint256 premium,
        uint256 expiration,
        IHegicOptions.OptionType optionType)
    {
        require(_exists(_tokenId), "HONFT/invalid-token-id");
        (state,
         holder,
         strike,
         amount,
         lockedAmount,
         premium,
         expiration, 
         optionType) = optionsProvider.options(underlyingOptionId[_tokenId]);
    }

    /**
     * @notice Pays contract's balance to account
     * @param account Account to receive balance
     */
    function _transferBalance(address account) internal virtual returns (uint balance);

    /**
     * @notice Executed before a token transfer. Checks if this contracts own the underlying option before
     * transfering it. If owner != this, it will revert
     * @param _from from
     * @param _to to
     * @param _tokenId ID of token to be transfered
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        require(checkValidToken(_tokenId) || _from == address(0) || _to == address(0), "HONFT/invalid-holder");
    }

    /**
     * @notice checks if this token is owned by this contract
     * @param _tokenId ID of the token to be queried
     * @return whether or not it is owned by the contract
     */
    function isValidToken(uint _tokenId) external view returns (bool){
        (, address holder, , , , , ,) = getUnderlyingOptionParams(_tokenId);
        return holder == address(this);
    }

    /**
     * @notice checks and updates status of ownedByThis. returns true if this contract owns
     * and controls underlying hegic option
     * @param _tokenId ID of the token to be queried
     * @return whether or not it is owned by the contract
     */
    function checkValidToken(uint _tokenId) internal returns (bool) {
        if(!ownedByThis[_tokenId]){
            ( , address holder, , , , , , ) = optionsProvider.options(underlyingOptionId[_tokenId]);
            ownedByThis[_tokenId] = holder == address(this);
            return holder == address(this);
        }
        return true;
    }

    modifier onlyTokenOwnerOrApproved(uint _itemId) {
        require(_isApprovedOrOwner(msg.sender, _itemId) , "HONFT/not-token-owner-or-approved");
        _;
    }
}