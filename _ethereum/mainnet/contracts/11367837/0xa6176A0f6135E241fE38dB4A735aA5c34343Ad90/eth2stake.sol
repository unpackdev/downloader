/*
███████╗████████╗██╗  ██╗██████╗ ███████╗████████╗ █████╗ ██╗  ██╗███████╗    ██████╗ ██████╗ ███╗   ███╗
██╔════╝╚══██╔══╝██║  ██║╚════██╗██╔════╝╚══██╔══╝██╔══██╗██║ ██╔╝██╔════╝   ██╔════╝██╔═══██╗████╗ ████║
█████╗     ██║   ███████║ █████╔╝███████╗   ██║   ███████║█████╔╝ █████╗     ██║     ██║   ██║██╔████╔██║
██╔══╝     ██║   ██╔══██║██╔═══╝ ╚════██║   ██║   ██╔══██║██╔═██╗ ██╔══╝     ██║     ██║   ██║██║╚██╔╝██║
███████╗   ██║   ██║  ██║███████╗███████║   ██║   ██║  ██║██║  ██╗███████╗██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ERC20Pausable.sol";
import "./IERC20.sol";

struct Eth2Deposit {
    bytes pubkey;
    bytes withdrawal_credentials;
    bytes signature;
    bytes32 deposit_data_root;
    uint256 depositAmount;
}

interface IDepositContract {
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}

contract Eth2Stake is ERC20Pausable, Ownable {
    // https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa
    IDepositContract public depositContract;
    /* lastSetPrice10_6 
       1 token / 1 ether   =  1000000 */
    uint256 public lastSetPrice10_6 = 1000000;
    /*  priceDayIncriment10_6 
        100%    PER DAY = 1000000
          5%    PER DAY =   50000
          0.05% PER DAY =     500     */
    uint256 public priceDayIncriment10_6 = 0;
    // priceTime - unix time second 2020-11-05T09:18:10 UTC
    uint256 public priceTime = 1604567890;
    Eth2Deposit[] public validators;

    constructor(IDepositContract argDepositContract)
        public
        ERC20("eth2stake.com", "E2S")
    {
        depositContract = argDepositContract;
    }

    receive() external payable {
        mint();
    }

    function mint() public payable whenNotPaused {
        uint256 tokensAmount = (msg.value * 1000000) / price10_6();
        if (tokensAmount > 0) _mint(msg.sender, tokensAmount);
        sendToDepositContract();
    }

    function sendToDepositContract() public {
        while (
            /* gas using 
                0 deposit - 75455
                1 deposit - 108857?
                2 deposit - 176962 
                3 deposit - 234273 */
            (gasleft() > 200000) &&
            (validators.length > 0) &&
            ((payable(address(this))).balance >=
                validators[validators.length - 1].depositAmount)
        ) {
            //TODO узнать, на что влияют данные указатели (memory)
            Eth2Deposit memory validator = validators[validators.length - 1];
            depositContract.deposit{value: validator.depositAmount}(
                validator.pubkey,
                validator.withdrawal_credentials,
                validator.signature,
                validator.deposit_data_root
            );
            validators.pop();
        }
    }

    function setPrice(
        uint256 argLastSetPrice10_6,
        uint256 argPriceDayIncriment10_6,
        uint256 argPriceTime
    ) external onlyOwner {
        lastSetPrice10_6 = argLastSetPrice10_6;
        priceDayIncriment10_6 = argPriceDayIncriment10_6;
        priceTime = argPriceTime;
    }

    function price10_6() public view returns (uint256) {
        require(now >= priceTime, "future price error");
        return
            lastSetPrice10_6 +
            (lastSetPrice10_6 * priceDayIncriment10_6 * (now - priceTime)) /
            (1000000 * 1 days);
    }

    function addValidator(
        bytes calldata _pubkey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root,
        uint256 _depositAmount
    ) external onlyOwner {
        validators.push(
            Eth2Deposit({
                pubkey: _pubkey,
                withdrawal_credentials: _withdrawal_credentials,
                signature: _signature,
                deposit_data_root: _deposit_data_root,
                depositAmount: _depositAmount
            })
        );
    }

    function removeValidator(uint256 count) public onlyOwner {
        for (
            uint256 index = 0;
            index < count && validators.length > 0;
            index++
        ) {
            validators.pop();
        }
    }

    function validatorsLength() public view returns (uint256) {
        return validators.length;
    }

    function ifNeedReturnEther(address payable sendTo, uint256 amount)
        public
        onlyOwner
    {
        sendTo.transfer(amount);
    }

    function ifNeedReturnTokens(
        IERC20 token,
        address sendTo,
        uint256 amount
    ) public onlyOwner {
        token.transfer(sendTo, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
