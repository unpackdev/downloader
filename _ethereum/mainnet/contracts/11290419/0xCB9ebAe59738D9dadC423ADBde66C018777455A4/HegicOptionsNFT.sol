// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Interfaces.sol";

/**
 * @author jmonteer
 * @title Hegic NFT options
 * @notice ERC721 that holds Hegic Options 
 */
abstract contract HegicOptionsNFT is ERC721, Ownable{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    event Tokenized(
        address account,
        uint optionId
    );

    event Detokenized(
        address account,
        uint tokenId,
        bool burned
    );

    // tokenId => underlyingOptionId
    mapping(uint => uint) public underlyingOptionId;

    IHegicOptions public optionsProvider;

    // tokenId => (cached 'is the underlying Option owned by the contract?')
    mapping(uint => bool) ownedByThis;

    constructor(
        string memory _name, 
        string memory _symbol
        ) 
        public 
        ERC721(_name, _symbol)
    {}

    /** 
     * @notice Updates options provider in case Hegic upgrades its contracts
     * @param _newOptionsProvider New IHegicOptions contract
     */
    function updateOptionsProvider(IHegicOptions _newOptionsProvider) external onlyOwner {
        optionsProvider = _newOptionsProvider;
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
        IHegicOptions.OptionType _optionType
    ) 
        payable
        external
        returns (uint newTokenId)
    {   
        uint optionId = optionsProvider.create{value: msg.value}(_period, _amount, _strike, _optionType);
        _transferBalance(msg.sender); // if sender sent more than needed, contract will return excess
        newTokenId = tokenizeOption(optionId);
    }

    /**
     * @notice Exercises underlying option
     * @param _tokenId ID of the token that holds the option to be exercised
     */
    function exerciseOption(uint _tokenId) external onlyTokenOwner(_tokenId) {
        optionsProvider.exercise(underlyingOptionId[_tokenId]);
        _transferBalance(msg.sender); // PENDING: calcular profit y enviar solo eso?
    }

    /**
     * @notice Tokenizes an existing option
     * @dev User has to transfer option's ownership for the token to be transferable
     * @param _optionId ID of the option to be tokenized
     * @return newTokenId ID of the token that holds that specific option
     */
    function tokenizeOption(uint _optionId) 
        public
        returns (uint newTokenId) {
        _tokenIds.increment();
        newTokenId = _tokenIds.current();

        underlyingOptionId[newTokenId] = _optionId;

        (, address holder, , , , , ,) = getUnderlyingOptionParams(newTokenId);
        require(holder == msg.sender || holder == address(this), "HONFT/owner-not-valid");

        _mint(msg.sender, newTokenId);

        emit Tokenized(msg.sender, _optionId);
    }

    /**
     * @notice Transfers underlying option's ownership to tokenholder. Optionally, it burns the token
     * @param _tokenId ID of the token that holds the option to be detokenized
     * @param _burnToken True to burn the token, false to keep the token
     */
    function detokenizeOption(uint _tokenId, bool _burnToken) external onlyTokenOwner(_tokenId) {
        require(checkValidToken(_tokenId), "HONFT/option-not-owned-by-contract");

        // checks if optionsProvider will allow to transfer option ownership
        (IHegicOptions.State state, , , , , , uint expiration , ) = getUnderlyingOptionParams(_tokenId);
        if(state == IHegicOptions.State.Active || expiration >= block.timestamp)
            optionsProvider.transfer(underlyingOptionId[_tokenId], msg.sender);
        
        ownedByThis[_tokenId] = false;

        if(_burnToken)
            _burn(_tokenId);
        
        emit Detokenized(msg.sender, _tokenId, _burnToken);
    }

    /**
     * @notice Burns NFT if it does not hold any option
     * @param _tokenId ID of the token to be burnt
     */
    function burnToken(uint _tokenId) external onlyTokenOwner(_tokenId) {
        (IHegicOptions.State state, , , , , , uint expiration , ) = getUnderlyingOptionParams(_tokenId);
        
        // allows to burn inactive options, even if still owned by the contract
        if(state == IHegicOptions.State.Active || expiration >= block.timestamp)
            require(!ownedByThis[_tokenId], "HONFT/cannot-burn-option-owned-by-contract");
        
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
    function _transferBalance(address account) internal virtual;

    /**
     * @notice Executed before a token transfer. Checks if this contracts own the underlying option before
     * transfering it. If owner != this, it will revert
     * @param _from from
     * @param _to to
     * @param _tokenId ID of token to be transfered
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        require(checkValidToken(_tokenId) || _from == address(0) || _to == address(0), "HONFT/invalid-owner");
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
    function checkValidToken(uint _tokenId) public returns (bool) {
        if(!ownedByThis[_tokenId]){
            ( , address holder, , , , , , ) = optionsProvider.options(underlyingOptionId[_tokenId]);
            ownedByThis[_tokenId] = holder == address(this);
            return holder == address(this);
        }
        return true;
    }

    modifier onlyTokenOwner(uint _itemId) {
        require(msg.sender == ownerOf(_itemId), "HONFT/not-token-owner");
        _;
    }
}