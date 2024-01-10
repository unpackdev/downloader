// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import "./ERC20Token.sol";
import "./Owned.sol";
import "./TeamTranche.sol";
import "./TokenSale.sol";

contract TruthereumToken is ERC20Token, Owned {

    // Constants
    string constant private NAME = "Truthereum";
    string constant private SYMBOL = "TRE";
    uint8 constant private DECIMALS = 18;

    uint256 constant private TOKEN_UNIT = 10 ** DECIMALS;
    uint256 constant private TOTAL_SUPPLY = 5488039296144 * TOKEN_UNIT;
    uint256 constant public PUBLIC_SUPPLY = 4168188989144 * TOKEN_UNIT;
    uint256 constant public TEAM_SUPPLY = 1319850307000 * TOKEN_UNIT;
    
    uint256 constant public CROWDSALE_END_TIME = 1650151353; // 1650151353 April 16th, 2022 11:22:33 GMT
    uint256 constant public MAX_SALE_AMOUNT = 120736864515 * TOKEN_UNIT; // Never more than 2.2% of the total supply

    // 12.5% every 3 months is distributed to the teams
    TeamTranche[] private TEAM_TRANCHES = [
        new TeamTranche(1654041600, 164981288375 * TOKEN_UNIT), // June 1st 2022, 00:00 GMT
        new TeamTranche(1661990400, 164981288375 * TOKEN_UNIT), // September 1st 2022, 00:00 GMT
        new TeamTranche(1669852800, 164981288375 * TOKEN_UNIT), // December 1st 2022, 00:00 GMT
        new TeamTranche(1677628800, 164981288375 * TOKEN_UNIT), // March 1st 2023, 00:00 GMT
        new TeamTranche(1685577600, 164981288375 * TOKEN_UNIT), // June 1st 2023, 00:00 GMT
        new TeamTranche(1693526400, 164981288375 * TOKEN_UNIT), // September 1st 2023, 00:00 GMT
        new TeamTranche(1701388800, 164981288375 * TOKEN_UNIT), // December 1st 2023, 00:00 GMT
        new TeamTranche(1709251200, 164981288375 * TOKEN_UNIT) // March 1st 2024, 00:00 GMT
    ];

    // Variables
    uint256 public totalAllocated = 0;
    uint256 public totalTeamReleased = 0;

    address public publicAddress;
    address public teamAddress;
    address public saleAddress = address(0);

    TokenSale tokenSale;

    // Modifiers
    modifier saleAddressRestricted() {
        require(msg.sender == saleAddress, 'ERROR: Can only be called from the saleAddress');
        _;
    }

    constructor(address _publicAddress, address _teamAddress) ERC20Token(NAME, SYMBOL, DECIMALS, TOTAL_SUPPLY) {
        publicAddress = _publicAddress;
        teamAddress = _teamAddress;
        balanceOf[_publicAddress] = PUBLIC_SUPPLY;
    }

    /**
        Starts a new token sale, only one can be active at a time and the total amount for sale must be
        less than the public supply still available for distribution
    */
    function addTokenSale(address payable _saleAddress) isValidAddress(_saleAddress) ownerRestricted public {
        require(isSaleWindow() == false, 'ERROR: There is already an active sale');
        tokenSale = TokenSale(_saleAddress);
        require(tokenSale.isStartable() == true, 'ERROR: The sale is not in a startable state');
        uint256 tokensForSale = tokenSale.tokensForSale();
        require(
            tokensForSale <= balanceOf[publicAddress] &&
            (hasCrowdsaleEnded() == false || tokensForSale <= MAX_SALE_AMOUNT),
            'ERROR: There sale amount exceeds the public balance or max sale amount'
        );
        saleAddress = _saleAddress;
        allowance[publicAddress][saleAddress] = tokensForSale;
    }

    /**
        Ends the current token sale and returns and outstanding unsold amount to the public address
    */
    function endTokenSale() saleAddressRestricted public {
        require(isSaleWindow() == true, 'ERROR: There is no sale active');
        address unsoldAddress = tokenSale.unsoldAddress();

        // The crowdsale will not have an unsold address
        if (unsoldAddress != address(0)) {
            uint256 unsoldTokens = tokenSale.availableForSale();
            balanceOf[unsoldAddress] = unsoldTokens;
            balanceOf[publicAddress] = safeSub(balanceOf[publicAddress], unsoldTokens);
        }
        
        allowance[publicAddress][saleAddress] = 0;
        saleAddress = address(0);
    }

    /**
        Handles the transfer if the crowdsale has ended or the sender is the public address
    */
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        if (hasCrowdsaleEnded() == true || msg.sender == publicAddress) {
            assert(super.transfer(_to, _value));
            return true;
        }
        revert();        
    }

    /**
        Handles the transfer from if the crowdsale has ended or the sender is the public address
    */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        if (hasCrowdsaleEnded() == true || _from == publicAddress) {  
            assert(super.transferFrom(_from, _to, _value));
            return true;
        }
        revert();
    }

    /**
        Iterates through all of the team tranches and attempts to release them
    */
    function releaseTeamTranches() ownerRestricted public {
        require(totalTeamReleased < TEAM_SUPPLY, 'ERROR: The entire team supply has already been released');
        for (uint index = 0; index < TEAM_TRANCHES.length; index++) {
            releaseTeamTranche(TEAM_TRANCHES[index]);
        }
    }

    /**
        Releases the team tranche if the release conditions are met
    */
    function releaseTeamTranche(TeamTranche _tranche) internal returns(bool) {
        if (_tranche.isReleasable() == false) {
            return false;
        }
        balanceOf[teamAddress] = safeAdd(balanceOf[teamAddress], _tranche.amount());
        emit Transfer(address(0), teamAddress, _tranche.amount());
        totalAllocated = safeAdd(totalAllocated, _tranche.amount());
        totalTeamReleased = safeAdd(totalTeamReleased, _tranche.amount());
        _tranche.setReleased();
        return true;
    }

    /**
        Adds to the total amount of tokens allocated
    */
    function addToAllocation(uint256 _amount) public saleAddressRestricted {
        totalAllocated = safeAdd(totalAllocated, _amount);
    }

    /**
        Checks if the crowdsale has ended
    */
    function hasCrowdsaleEnded() public view returns(bool) {
        if (block.timestamp > CROWDSALE_END_TIME) {
            return true;
        }
        return false;
    }

    /**
        Checks if it is currently a sale window
    */
    function isSaleWindow() public view returns(bool) {
        if (saleAddress == address(0)) {
            return false;
        }
        return true;
    }
}