// contracts/Paper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./IDebtCity.sol";
import "./IProperty.sol";


contract Paper is ERC20BurnableUpgradeable, OwnableUpgradeable {

/*

██████╗░░█████╗░██████╗░███████╗██████╗░
██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
██████╔╝███████║██████╔╝█████╗░░██████╔╝
██╔═══╝░██╔══██║██╔═══╝░██╔══╝░░██╔══██╗
██║░░░░░██║░░██║██║░░░░░███████╗██║░░██║
╚═╝░░░░░╚═╝░░╚═╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝


*/

    using SafeMathUpgradeable for uint256;

    address nullAddress;

    address public debtCityAddress;
    address public propertyAddress;


    struct Loan {
        uint256 loanTime;
        uint256 loanPeriod;
        bool exists;
    }


    mapping(uint256 => uint256) internal bankerIdToTimeStamp;
    mapping(uint256 => address) internal bankerIdToStaker;
    mapping(address => uint256[]) internal stakerToBankerIds;
    mapping(uint256 => Loan) internal bankerIdToLoanTime;

    mapping(uint256 => uint256) internal propIdToTimeStamp;
    mapping(uint256 => address) internal propIdToStaker;
    mapping(address => uint256[]) internal stakerToPropIds;


    function initialize() initializer public {
        __Ownable_init();
        __ERC20_init("Paper", "PAPER-DC");
        nullAddress = 0x0000000000000000000000000000000000000000;
    }


    function setPaperAddresses(address _debtCityAddress, address _propertyAddress) public onlyOwner {
        debtCityAddress = _debtCityAddress;
        propertyAddress = _propertyAddress;
        return;
    }



    /** *********************************** **/
    /** ********* Helper Functions ******* **/
    /** *********************************** **/

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToBankerIds[staker].length) return;

        for (uint256 i = index; i < stakerToBankerIds[staker].length - 1; i++) {
            stakerToBankerIds[staker][i] = stakerToBankerIds[staker][i + 1];
        }
        stakerToBankerIds[staker].pop();
    }

    function removeBankerIdFromStaker(address staker, uint256 bankerId) internal {
        for (uint256 i = 0; i < stakerToBankerIds[staker].length; i++) {
            if (stakerToBankerIds[staker][i] == bankerId) {
                remove(staker, i);
            }
        }
    }


    function removeProp(address staker, uint256 index) internal {
        if (index >= stakerToPropIds[staker].length) return;

        for (uint256 i = index; i < stakerToPropIds[staker].length - 1; i++) {
            stakerToPropIds[staker][i] = stakerToPropIds[staker][i + 1];
        }
        stakerToPropIds[staker].pop();
    }

    function removePropIdFromStaker(address staker, uint256 bankerId) internal {
        for (uint256 i = 0; i < stakerToPropIds[staker].length; i++) {
            if (stakerToPropIds[staker][i] == bankerId) {
                removeProp(staker, i);
            }
        }
    }

    

    /** *********************************** **/
    /** ********* Staking Functions ******* **/
    /** *********************************** **/

    function stakePropertyByIds(uint256[] memory propIds) public {
        
        for (uint256 i = 0; i < propIds.length; i++) {
            uint256 propId = propIds[i];

            require(
                IERC721(propertyAddress).ownerOf(propId) == msg.sender &&
                    propIdToStaker[propId] == nullAddress,
                "Property must be stakable by you!"
            );

            IERC721(propertyAddress).transferFrom(
                msg.sender,
                address(this),
                propId
            );

            stakerToPropIds[msg.sender].push(propId);

            propIdToTimeStamp[propId] = block.timestamp;
            propIdToStaker[propId] = msg.sender;

        }
    }

    function simpleStakeByIds(uint256[] memory bankerIds) public {

        for (uint256 i = 0; i < bankerIds.length; i++) {
            uint256 bankerId = bankerIds[i];
            require(
                IERC721(debtCityAddress).ownerOf(bankerId) == msg.sender &&
                    bankerIdToStaker[bankerId] == nullAddress,
                "Banker must be stakable by you!"
            );

            IERC721(debtCityAddress).transferFrom(
                msg.sender,
                address(this),
                bankerId
            );

            stakerToBankerIds[msg.sender].push(bankerId);

            bankerIdToTimeStamp[bankerId] = block.timestamp;
            bankerIdToStaker[bankerId] = msg.sender;

            bankerIdToLoanTime[bankerId] = Loan(0, 0, false);
        }
    }




    function loanStakeByIds(uint256[] memory bankerIds, uint256 numLoanDays) public {

        uint256 totalRewards = 0;

        require(
            numLoanDays > 0 && numLoanDays <= 5,
            "Max number of loan days is 5"
        );

        for (uint256 i = 0; i < bankerIds.length; i++) {
            uint256 bankerId = bankerIds[i];

            if (IERC721(debtCityAddress).ownerOf(bankerId) == msg.sender) {
                IERC721(debtCityAddress).transferFrom(
                    msg.sender,
                    address(this),
                    bankerId
                );

                stakerToBankerIds[msg.sender].push(bankerId);

                bankerIdToTimeStamp[bankerId] = block.timestamp;
                bankerIdToStaker[bankerId] = msg.sender;

                bankerIdToLoanTime[bankerId] = Loan(0, 0, false);
            }

            require(
                IERC721(debtCityAddress).ownerOf(bankerId) == address(this) &&
                    bankerIdToStaker[bankerId] == msg.sender,
                "Banker must be stakable by you!"
            );

            require (bankerIdToLoanTime[bankerId].exists == false, "Cannot loan a banker thats already loaned out");

            uint256 loanPeriod = numLoanDays; 
            bankerIdToLoanTime[bankerId] = Loan(block.timestamp, loanPeriod, true);

            uint8 pay_rate = IDebtCity(debtCityAddress).getPayForBanker(bankerId);

            totalRewards = totalRewards + ((loanPeriod) * (pay_rate * 2));

        }

        _mint(msg.sender, totalRewards);

    }


    /** *********************************** **/
    /** ********* Unstake Functions ******* **/
    /** *********************************** **/

    function unstakeAllProps() public {
        require(
            stakerToPropIds[msg.sender].length > 0,
            "Must have at least one property staked!"
        );

        uint256 totalRewards = 0;

        for (uint256 i = stakerToPropIds[msg.sender].length; i > 0; i--) {
            uint256 propId = stakerToPropIds[msg.sender][i - 1];

            require(
                propIdToStaker[propId] == msg.sender,
                "Message Sender was not original property staker!"
            );

            uint8 pay_rate = IProperty(propertyAddress).getPayForProperty(propId);
            uint256 stakeTime = block.timestamp - propIdToTimeStamp[propId];
            uint256 daysStaked = stakeTime / 86400;

            uint256 propReward = daysStaked * pay_rate;

            IERC721(propertyAddress).transferFrom(
                address(this),
                msg.sender,
                propId
            );

            totalRewards = totalRewards + propReward;
            removePropIdFromStaker(msg.sender, propId);
            propIdToStaker[propId] = nullAddress;

        }

        _mint(msg.sender, totalRewards);
    }


    function unstakePropsByIds(uint256[] memory propIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < propIds.length; i++) {
            
            uint256 propId = propIds[i];

            require(
                propIdToStaker[propId] == msg.sender,
                "Message Sender was not original property staker!"
            );

            uint8 pay_rate = IProperty(propertyAddress).getPayForProperty(propId);
            uint256 stakeTime = block.timestamp - propIdToTimeStamp[propId];
            uint256 daysStaked = stakeTime / 86400;
            uint256 propReward = daysStaked * pay_rate;

            IERC721(propertyAddress).transferFrom(
                address(this),
                msg.sender,
                propId
            );

            totalRewards = totalRewards + propReward;

            removePropIdFromStaker(msg.sender, propId);
            propIdToStaker[propId] = nullAddress;
        }

         _mint(msg.sender, totalRewards);
    }



    function unstakeAllBankers() public {
        require(
            stakerToBankerIds[msg.sender].length > 0,
            "Must have at least one banker staked!"
        );
        uint256 totalRewards = 0;

        for (uint256 i = stakerToBankerIds[msg.sender].length; i > 0; i--) {
            uint256 bankerId = stakerToBankerIds[msg.sender][i - 1];

            require(
                bankerIdToStaker[bankerId] == msg.sender,
                "Message sender was not original staker!"
            );

            // make sure this banker isn't time locked from loan stake still
            Loan memory l = bankerIdToLoanTime[bankerId];
            uint256 loanTime = l.loanTime;
            uint256 loanPeriod = l.loanPeriod;
            // loan period is in days so we convert to seconds, (60 * 60 * 24 = 600)
            uint256 loanPeriodSeconds = loanPeriod * 86400;

            require(block.timestamp > (loanTime + loanPeriodSeconds), "Must have loaned banker for full loan time period");

            uint256 rewardTime;

            if (loanTime > 0) {
                rewardTime = (loanTime - bankerIdToTimeStamp[bankerId]) + (block.timestamp - (loanTime + loanPeriodSeconds));
            } else { 
                rewardTime = block.timestamp - bankerIdToTimeStamp[bankerId];
            }

            uint8 pay_rate = IDebtCity(debtCityAddress).getPayForBanker(bankerId);
            uint256 rewardDays = rewardTime / 86400;
            uint256 bankerReward = (rewardDays * pay_rate) - 5;

            require (bankerReward > 0, "must have staked for at least a day to unstake");

            IERC721(debtCityAddress).transferFrom(
                address(this),
                msg.sender,
                bankerId
            );

            totalRewards = totalRewards + bankerReward;

            removeBankerIdFromStaker(msg.sender, bankerId);

            bankerIdToStaker[bankerId] = nullAddress;
            bankerIdToLoanTime[bankerId] = Loan(0, 0, false);
        }

        _mint(msg.sender, totalRewards);
    }



    function unstakeByIds(uint256[] memory bankerIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < bankerIds.length; i++) {
            
            uint256 bankerId = bankerIds[i];

            require(
                bankerIdToStaker[bankerId] == msg.sender,
                "Message sender was not original staker!"
            );

            // make sure this banker isn't time locked from loan stake still
            Loan memory l = bankerIdToLoanTime[bankerId];
            uint256 loanTime = l.loanTime;
            uint256 loanPeriod = l.loanPeriod;
            // loan period is in days so we convert to seconds, (60 * 60 * 24 = 600)
            uint256 loanPeriodSeconds = loanPeriod * 86400;

            require(block.timestamp > (loanTime + loanPeriodSeconds), "Must have loaned banker for full loan time seconds");

            uint256 rewardTime;

            if (loanTime > 0) {
                rewardTime = (loanTime - bankerIdToTimeStamp[bankerId]) + (block.timestamp - (loanTime + loanPeriodSeconds));
            } else {
                rewardTime = block.timestamp - bankerIdToTimeStamp[bankerId];
            }

            uint8 pay_rate = IDebtCity(debtCityAddress).getPayForBanker(bankerId);
            uint256 rewardDays = rewardTime / 86400;
            uint256 bankerReward = (rewardDays * pay_rate) - 5;

            require (bankerReward > 0, "must have staked for at least a day to unstake");

            IERC721(debtCityAddress).transferFrom(
                address(this),
                msg.sender,
                bankerId
            );

            totalRewards = totalRewards + bankerReward;

            removeBankerIdFromStaker(msg.sender, bankerId);

            bankerIdToStaker[bankerId] = nullAddress;
            bankerIdToLoanTime[bankerId] = Loan(0, 0, false);
        }

        _mint(msg.sender, totalRewards);
    }



    /** *********************************** **/
    /** ********* Claiming Functions ******* **/
    /** *********************************** **/


    function claimBankersById(uint256[] memory bankerIds) public {

        uint256 totalRewards = 0;

        for (uint256 i = 0; i < bankerIds.length; i++) {
            
            uint256 bankerId = bankerIds[i];

            require(
                bankerIdToStaker[bankerId] == msg.sender,
                "Message sender was not original staker!"
            );

            // make sure this banker isn't time locked from loan stake still
            Loan memory l = bankerIdToLoanTime[bankerId];
            uint256 loanTime = l.loanTime;
            uint256 loanPeriod = l.loanPeriod;
            // loan period is in days so we convert to seconds, (60 * 60 * 24 = 600)
            uint256 loanPeriodSeconds = loanPeriod * 86400;

            require(block.timestamp > (loanTime + loanPeriodSeconds), "Must have loaned banker for full loan time seconds");

            uint256 rewardTime;

            if (loanTime > 0) {
                rewardTime = (loanTime - bankerIdToTimeStamp[bankerId]) + (block.timestamp - (loanTime + loanPeriodSeconds));
            } else {
                rewardTime = block.timestamp - bankerIdToTimeStamp[bankerId];
            }

            uint8 pay_rate = IDebtCity(debtCityAddress).getPayForBanker(bankerId);
            uint256 rewardDays = rewardTime / 86400;

            require (rewardDays > 0, "must have staked for at least a day to claim anything");

            totalRewards += (rewardDays * pay_rate);
            bankerIdToTimeStamp[bankerId] = block.timestamp;
            bankerIdToLoanTime[bankerId] = Loan(0, 0, false);
        }

        _mint(msg.sender, totalRewards);
    }


    function claimPropsById(uint256[] memory propIds) public {

        uint256 totalRewards = 0;

        for (uint256 i = 0; i < propIds.length; i++) {
            uint256 propId = propIds[i];

            require(
                propIdToStaker[propId] == msg.sender,
                "Message sender was not original staker!"
            );

            uint8 pay_rate = IProperty(propertyAddress).getPayForProperty(propId);
            uint256 claimTime = block.timestamp - propIdToTimeStamp[propId];
            uint256 daysStaked = claimTime / 86400;

            require (daysStaked > 0, "must have staked for at least a day to claim anything");

            totalRewards = totalRewards + (daysStaked * pay_rate);
            propIdToTimeStamp[propId] = block.timestamp;
        }
        
        _mint(msg.sender, totalRewards);

    }


    function claimAllRewards() public {

        require(
            stakerToBankerIds[msg.sender].length > 0 || stakerToPropIds[msg.sender].length > 0,
            "Must have at least one banker or prop staked!"
        );

        uint256 totalRewards = 0;

        for (uint256 i = stakerToBankerIds[msg.sender].length; i > 0; i--) {
            uint256 bankerId = stakerToBankerIds[msg.sender][i - 1];

            require(
                bankerIdToStaker[bankerId] == msg.sender,
                "Message sender was not original staker!"
            );

            Loan memory l = bankerIdToLoanTime[bankerId];
            uint256 loanTime = l.loanTime;
            uint256 loanPeriod = l.loanPeriod;
            // loan period is in days so we convert to seconds, (60 * 60 * 24 = 600)
            uint256 loanPeriodSeconds = loanPeriod * 86400;

            if (block.timestamp > (loanTime + loanPeriodSeconds)) {
                
                uint256 rewardTime;

                if (loanTime > 0) {
                    rewardTime = (loanTime - bankerIdToTimeStamp[bankerId]) + (block.timestamp - (loanTime + loanPeriodSeconds));
                } else {
                    rewardTime = block.timestamp - bankerIdToTimeStamp[bankerId];
                }

                uint8 pay_rate = IDebtCity(debtCityAddress).getPayForBanker(bankerId);
                uint256 rewardDays = rewardTime / 86400;

                if (rewardDays > 0) {
                    totalRewards = totalRewards + (rewardDays * pay_rate);
                    bankerIdToTimeStamp[bankerId] = block.timestamp;
                    bankerIdToLoanTime[bankerId] = Loan(0, 0, false);
                }

            }
            
        }


        for (uint256 i = stakerToPropIds[msg.sender].length; i > 0; i--) {
            uint256 propId = stakerToPropIds[msg.sender][i - 1];

            require(
                propIdToStaker[propId] == msg.sender,
                "Message sender was not original staker!"
            );

            uint8 pay_rate = IProperty(propertyAddress).getPayForProperty(propId);
            uint256 claimTime = block.timestamp - propIdToTimeStamp[propId];
            uint256 daysStaked = claimTime / 86400;

            if (daysStaked > 0) {
                totalRewards = totalRewards + (daysStaked * pay_rate);
                propIdToTimeStamp[propId] = block.timestamp;
            }
            

        }


        _mint(msg.sender, totalRewards);
    }





    /** *********************************** **/
    /** ********* Public Getters ********** **/
    /** *********************************** **/

    function getBankersStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToBankerIds[staker];
    }


    function getBankersLoaned(address staker)
        public
        view
        returns (uint256[] memory)
    {

        uint256[] memory loanBankers = new uint256[](stakerToBankerIds[staker].length);

        for (uint256 i = 0; i < stakerToBankerIds[staker].length; i++) {
            uint256 bankerId = stakerToBankerIds[staker][i];

            Loan memory l = bankerIdToLoanTime[bankerId];
            uint256 loanTime = l.loanTime;
            uint256 loanPeriod = l.loanPeriod;

            if (loanTime > 0 && loanPeriod > 0) {
                loanBankers[i] = bankerId;
            }

        }

        return loanBankers;
    }

    function getPropsStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToPropIds[staker];
    }


    function getRewardsByBankerId(uint256 bankerId)
        public
        view
        returns (uint256)
    {
        require(
            bankerIdToStaker[bankerId] != nullAddress,
            "Banker is not staked!"
        );


        Loan memory l = bankerIdToLoanTime[bankerId];
        uint256 loanTime = l.loanTime;
        uint256 loanPeriod = l.loanPeriod;
        uint256 loanPeriodSeconds = loanPeriod * 86400;

        require(block.timestamp > (loanTime + loanPeriodSeconds), "Banker is still loan time locked so there is no current rewards");

        uint256 rewardTime;

        if (loanTime > 0) {
            rewardTime = (loanTime - bankerIdToTimeStamp[bankerId]) + (block.timestamp - (loanTime + loanPeriodSeconds));
        } else {
            rewardTime = block.timestamp - bankerIdToTimeStamp[bankerId];
        }

        uint8 pay_rate = IDebtCity(debtCityAddress).getPayForBanker(bankerId);

        uint256 rewardDays = rewardTime / 86400;
        uint256 totalRewards = rewardDays * pay_rate;

        return totalRewards;
    }


    function getRewardsByPropertyId(uint256 propId)
        public
        view
        returns (uint256)
    {
        require(
            propIdToStaker[propId] != nullAddress,
            "Property is not staked!"
        );

        uint256 secondsStaked = block.timestamp - propIdToTimeStamp[propId];
        uint256 daysStaked = secondsStaked / 86400;

        uint8 pay_rate = IProperty(propertyAddress).getPayForProperty(propId);

        return (pay_rate * daysStaked);
    }

    

    function getStaker(uint256 bankerId) public view returns (address) {
        return bankerIdToStaker[bankerId];
    }





    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual override {
        uint256 currentAllowance = allowance(account, _msgSender());

        if (_msgSender() != address(propertyAddress)) {
            require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        }

        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

}
