// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./RetrieveTokensFeature.sol";

/**
 * Contract that acts as a freeze (timelocked) vault to an immuntable beneficiary.
 */
contract TimelockedTokenVault is RetrieveTokensFeature {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 internal _token;

    // beneficiary of tokens after they are released
    address internal immutable _beneficiary;

    // the duration of the lock in seconds
    uint256 internal immutable _duration;

    // initial start balance
    uint256 internal _startBalance;

    // indiacted wheter vault started or not
    bool internal _started;

    // startDate of the lock in a unix timestamp
    uint256 internal _startDate;

    // the amount of tokens already retrieved
    uint256 internal _retrievedTokens;

    /**
     * @dev Initalizes a new instanc of the TimelockedTokenVault Vault
     * @param beneficiary_ the beneficiary who can collect the holdings
     * @param duration_ the duration of the vault in seconds
     */
    constructor(address beneficiary_, uint256 duration_) {
        require(beneficiary_ != address(0), 'Address 0 as beneficary is not allowed');
        _beneficiary = beneficiary_;
        _duration = duration_;
        _retrievedTokens = 0;
    }

    /**
     * @dev starts the vault
     */
    function start(IERC20 token_) public onlyOwner {
        require(!_started, 'Lock already started');
        require(address(token_) != address(0), 'Token must be set');
        _token = token_;
        _startDate = block.timestamp;
        _startBalance = _token.balanceOf(address(this));
        _started = true;
    }

    /**
     * @return the duration being held in seconds
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the state of the vault
     */
    function started() public view returns (bool) {
        return _started;
    }

    /**
     * @return the retrieved tokens
     */
    function retrievedTokens() public view returns (uint256) {
        return _retrievedTokens;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the start balance
     */
    function startBalance() public view returns (uint256) {
        return _startBalance;
    }

    /**
     * @return the startDate of the vault
     */
    function startDate() public view returns (uint256) {
        return _startDate;
    }

    /**
     * @return the enddate of the token being held as timestamp
     */
    function endDate() public view returns (uint256) {
        return _startDate + _duration;
    }

    /**
     * @dev payout the locked amount of token
     */
    function retrieveLockedTokens() public virtual onlyOwner {
        require(_started, 'Lock not started');
        require(block.timestamp >= endDate(), 'Duration not over');

        uint256 tokensToRetrieve = _token.balanceOf(address(this));
        _token.safeTransfer(beneficiary(), tokensToRetrieve);
    }

    /**
     * @dev retrieve wrongly assigned tokens, in situation lock wasn't initialized allow full access
     */
    function retrieveTokens(address to, address anotherToken) public override onlyOwner {
        require(address(_token) != anotherToken, 'The withdraw is restriected to extraneous tokens.');
        super.retrieveTokens(to, anotherToken);
    }
}
