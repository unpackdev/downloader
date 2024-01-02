// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";


contract ElosysCommunitySale {
    address private                         _owner;
    IERC20 private                          _eloToken;
    mapping(address => uint256) private     _wallets_investment;
    mapping(address => uint256) private     _wallets_elo_amount;
    address[] public                        _whitelistedAddresses;

    // Round 1 : parameters
    uint256 private                          _r1StartTime;            
    uint256 private                          _r1EndTime;
    uint256 private                          _r1EloPerEther;
    uint256 private                          _r1TotalEth;
    uint256 private                          _r1MaxBuyEth;
    uint256 private                          _r1MinBuyEth;
    uint256 private                          _r1TotalEthRaised;
    uint256 private                          _r1TotalEloSoled;


    // Round 2 : parameters
    uint256 private                          _r2StartTime;            
    uint256 private                          _r2EndTime;
    uint256 private                          _r2EloPerEther;
    uint256 private                          _r2TotalEth;
    uint256 private                          _r2MaxBuyEth;
    uint256 private                          _r2MinBuyEth;
    uint256 private                          _r2TotalEthRaised;
    uint256 private                          _r2TotalEloSoled;

    // Claim
    bool public                             _claim = false;
    
    // Total $ELO amount of claimed by users
    uint256 public                          _rTotalClaimed;



    event SoldElo(uint256 srcAmount, uint256 eloPerEth, uint256 eloAmount);
    event StateChange();
    event WhitelistAdded(uint256 whitelistCount);

    /**
     * @dev Constructing the contract basic informations, containing the ELO token addr, the ratio price eth:elo
     * and the max authorized eth amount per wallet
     */
    constructor() {
        require(msg.sender != address(0), "Deploy from the zero address");
        _owner = msg.sender;
        _eloToken = IERC20(0x61b34A012646cD7357f58eE9c0160c6d0021fA41);

        // Round 1 : parameters
        _r1StartTime = 1703001600; // December 19, 2023 4:00:00 PM GMT
        _r1EndTime = 1703088000; // December 20, 2023 4:00:00 PM GMT
        _r1EloPerEther = 316 * (10 ** 10); // 0.00000316 ETH 
        _r1TotalEth = 30 * (10 ** 18); // 30 ETH
        _r1MaxBuyEth = 3 * (10 ** 17); // 0.3 ETH
        _r1MinBuyEth = 1 * (10 ** 17); // 0.1 ETH
        _r1TotalEthRaised = 0;
        _r1TotalEloSoled = 0;


        // Round 2 : parameters
        _r2StartTime = 1703091600; // December 20, 2023 5:00:00 PM GMT
        _r2EndTime = 1703178000; // December 21, 2023 5:00:00 PM GMT
        _r2EloPerEther = 368 * (10 ** 10); // 0.00000368 ETH 
        _r2TotalEth = 50 * (10 ** 18); // 50 ETH
        _r2MaxBuyEth = 5 * (10 ** 17); // 0.5 ETH
        _r2MinBuyEth = 1 * (10 ** 17); // 0.1 ETH
        _r2TotalEthRaised = 0;
        _r2TotalEloSoled = 0;

        _rTotalClaimed = 0;
    }

    /**
     * @dev Check that the transaction sender is the ELO owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can do this action");
        _;
    }

    /**
     * @dev Check the sender have depassed the limit of max eth
     */
    modifier onlyOnceInvestable() {
        uint256 totalInvested = _wallets_investment[msg.sender];
        require(totalInvested == 0, "You have already bought the ELO token.");
        _;
    }

    /**
     * @dev Receive eth payment for the presale raise
     */
    function buy() external payable onlyOnceInvestable {
        _allocateElo(msg.value);
    }

    

    /**
     * @dev Set the presale claim mode 
     */
    function setClaim(bool value) external onlyOwner {
        require(block.timestamp> _r2EndTime, "Presale is not finished.");
        _claim = value;
        emit StateChange();
    }

    /**
     * @dev Claim the ELO once the presale is done
     */
    function claimElo() public
    {
        require(_claim == true, "You cant claim your ELO yet");
        uint256 srcAmount =  _wallets_investment[msg.sender];
        require(srcAmount > 0, "You dont have any ELO to claim");
        
        uint256 eloAmount =_wallets_elo_amount[msg.sender];
        require(
            _eloToken.balanceOf(address(this)) >= eloAmount,
            "The ELO amount on the contract is insufficient."
        );
        _wallets_investment[msg.sender] = 0;
        _eloToken.transfer(msg.sender, eloAmount);

        _rTotalClaimed += eloAmount;
    }

    /**
     * @dev Return the Current Round Id ( 1 => Round 1, 2 => Round 2, 3 => Finished).
     */
    function getRoundId() public view returns(uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime < _r1EndTime) {
            return 1;
        } else if (currentTime < _r2EndTime) {
            return 2;
        } else {
            return 3;
        }
    }


    /**
     * @dev Return the start time of the Presale in Round
     */
    function getRoundStartTime(uint roundId) public view returns(uint256) {
        if (roundId == 1) {
            return _r1StartTime;
        } else if (roundId == 2) {
            return _r2StartTime;
        }
        return 0;
    }

    /**
     * @dev Return the end time of the Presale in Round
     */
    function getRoundEndTime(uint roundId) public view returns(uint256) {
        if (roundId == 1) {
            return _r1EndTime;
        } else if (roundId == 2) {
            return _r2EndTime;
        }
        return 0;
    }
    
    /**
     * @dev Return the rate of Elo/Eth from the Presale in Round
     */
    function getEloPerEther(uint roundId) public view returns(uint256) {
        if (roundId == 1) {
            return _r1EloPerEther;
        } else if (roundId == 2) {
            return _r2EloPerEther;
        }
        return 0;
    }

    /**
     * @dev Return the limited amount from the Presale (as ETH) in Round
     */
    function getTotalEth(uint roundId) public view returns(uint256) {
        if (roundId == 1) {
            return _r1TotalEth;
        } else if (roundId == 2) {
            return _r2TotalEth;
        }
        return 0;
    }

    /**
     * @dev Return the max buy value per wallet (as ETH) in Round
     */
    function getMaxBuyEthPerWallet(uint roundId) public view returns(uint256) {
        if (roundId == 1) {
            return _r1MaxBuyEth;
        } else if (roundId == 2) {
            return _r2MaxBuyEth;
        }
        return 0;
    }

    /**
     * @dev Return the min buy value per wallet (as ETH) in Round
     */
    function getMinBuyEthPerWallet(uint roundId) public view returns(uint256) {
        if (roundId == 1) {
            return _r1MinBuyEth;
        } else if (roundId == 2) {
            return _r2MinBuyEth;
        }
        return 0;
    }

    /**
     * @dev Return the amount raised from the Presale (as ETH) in Round
     */
    function getTotalRaisedEth(uint roundId) public view returns(uint256) {
        if (roundId == 1) {
            return _r1TotalEthRaised;
        } else if (roundId == 2) {
            return _r2TotalEthRaised;
        }
        return 0;
    }

    /**
     * @dev Return the amount soled from the Presale (as ELO) in Round
     */
    function getTotalSoledElo(uint roundId) public view returns(uint256) {
        if (roundId == 1) {
            return _r1TotalEloSoled;
        } else if (roundId == 2) {
            return _r2TotalEloSoled;
        }
        return 0;
    }


    /**
     * @dev Return the total amount invested from a specific address
     */
    function getAddressInvestment(address addr) public view returns(uint256) {
        return  _wallets_investment[addr];
    }

    /**
     * @dev Return the total amount of ELO bought for a specific address
     */
    function getAddressBoughtElo(address addr) public view returns(uint256) {
        return  _wallets_elo_amount[addr];
    }

    /**
     * @dev Allocate the specific ELO amount to the payer address
     */
    function _allocateElo(uint256 _srcAmount) private {
        uint256 _eloPerEth = 0;
        uint256 currentTime = block.timestamp;
        if (currentTime < _r1StartTime) {
            revert('You should wait for Round 1');
        } else if (currentTime < _r1EndTime) {
            // Check if wallet is in whitelist : Round 1
            require(checkWhitelist(msg.sender), "You are not whitelisted");
            require(_srcAmount >= _r1MinBuyEth, "Too small deposite");
            require(_srcAmount <= _r1MaxBuyEth, "Too much deposite");
            require(_r1TotalEthRaised + _srcAmount <= _r1TotalEth, "Total Ether limited");
            _eloPerEth = _r1EloPerEther;
        } else if (currentTime < _r2StartTime) {
            revert('You should wait for Round 2');
        } else if (currentTime < _r2EndTime) {
            require(_srcAmount >= _r2MinBuyEth, "Too small deposite");
            require(_srcAmount <= _r2MaxBuyEth, "Too much deposite");
            require(_r2TotalEthRaised + _srcAmount <= _r2TotalEth, "Total Ether limited");
            
            _eloPerEth = _r2EloPerEther;
        } else {
            revert('Presale is over');
        }

        uint256 eloAmount = _srcAmount * (10 ** 18) / _eloPerEth; 

        require(
            _eloToken.balanceOf(address(this)) >= eloAmount + _r1TotalEloSoled + _r2TotalEloSoled,
                "The ELO amount on the contract is insufficient."
        );


        emit SoldElo(_srcAmount, _eloPerEth, eloAmount);

        if (currentTime < _r1EndTime) {
            _r1TotalEthRaised += _srcAmount;
            _r1TotalEloSoled += eloAmount;
        } else {
            _r2TotalEthRaised += _srcAmount;
            _r2TotalEloSoled += eloAmount;
        }
        
        _wallets_investment[msg.sender] += _srcAmount;
        _wallets_elo_amount[msg.sender] += eloAmount;
    }

    /**
     * @dev Authorize the contract owner to withdraw the raised funds from the presale
     */
    function withdraw() public onlyOwner {
        require(block.timestamp > _r2EndTime, "Presale is running yet.");
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Authorize the contract owner to withdraw the remaining ELO from the presale
     */
    function withdrawRemainingELO(uint256 _amount) public onlyOwner {
        require(
            _eloToken.balanceOf(address(this)) >= _amount,
            "ELO amount asked exceed the contract amount"
        );

        // Calculate how many $ELO should be in this contract.
        // The $ELOs are for the users who haven't claimed yet.
        uint256 _totalForUsers = _r1TotalEloSoled + _r2TotalEloSoled - _rTotalClaimed;

        require(
            _eloToken.balanceOf(address(this)) >= _amount + _totalForUsers,
            "ELO amount asked exceed the amount for users"
        );
        _eloToken.transfer(msg.sender, _amount);
    }

    /**
     * @dev Add wallets in whitelist 
     */
    function addInWhitelist(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++)  {
            if ( !checkWhitelist(_users[i]) )
                _whitelistedAddresses.push(_users[i]);
        }
        emit WhitelistAdded(_whitelistedAddresses.length);
    }

    /**
     * @dev remove wallets in whitelist 
     */
    function removeFromWhitelist(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++)  {
            for ( uint k = 0; k < _whitelistedAddresses.length; k++ ) {
                if (_whitelistedAddresses[k] == _users[i]) {
                    _whitelistedAddresses[k] = _whitelistedAddresses[_whitelistedAddresses.length - 1];
                    _whitelistedAddresses.pop();
                }
            }
        }
    }


    /**
     * @dev Check the whitelist
     */
    function checkWhitelist(address _user) public view returns (bool) {
        for (uint i = 0; i < _whitelistedAddresses.length; i++) {
            if (_whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Get number of whitelist
     */
    function getWhitelistCount() public view returns (uint) {
        return _whitelistedAddresses.length;
    }
}
