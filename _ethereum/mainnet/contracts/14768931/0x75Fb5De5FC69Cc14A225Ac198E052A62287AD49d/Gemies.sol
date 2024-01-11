// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
      _____                   _______                   _____                    _____                    _____                    _____          
     |\    \                 /::\    \                 /\    \                  /\    \                  /\    \                  /\    \         
     |:\____\               /::::\    \               /::\    \                /::\    \                /::\    \                /::\    \        
     |::|   |              /::::::\    \             /::::\    \               \:::\    \              /::::\    \              /::::\    \       
     |::|   |             /::::::::\    \           /::::::\    \               \:::\    \            /::::::\    \            /::::::\    \      
     |::|   |            /:::/~~\:::\    \         /:::/\:::\    \               \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
     |::|   |           /:::/    \:::\    \       /:::/  \:::\    \               \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
     |::|   |          /:::/    / \:::\    \     /:::/    \:::\    \              /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
     |::|___|______   /:::/____/   \:::\____\   /:::/    / \:::\    \    ____    /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /::::::::\    \ |:::|    |     |:::|    | /:::/    /   \:::\ ___\  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /::::::::::\____\|:::|____|     |:::|    |/:::/____/  ___\:::|    |/::\   \/:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/~~~~/~~       \:::\    \   /:::/    / \:::\    \ /\  /:::|____|\:::\  /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    /           \:::\    \ /:::/    /   \:::\    /::\ \::/    /  \:::\/:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /             \:::\    /:::/    /     \:::\   \:::\ \/____/    \::::::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /               \:::\__/:::/    /       \:::\   \:::\____\       \::::/____/              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                 \::::::::/    /         \:::\  /:::/    /        \:::\    \               \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                   \::::::/    /           \:::\/:::/    /          \:::\    \               \:::\   \/____/          \:::\/:::/    /     
                            \::::/    /             \::::::/    /            \:::\    \               \:::\    \               \::::::/    /      
                             \::/____/               \::::/    /              \:::\____\               \:::\____\               \::::/    /       
                              ~~                      \::/____/                \::/    /                \::/    /                \::/    /        
                                                                                \/____/                  \/____/                  \/____/                                                                                                                                                                 
 */

import "./ERC20.sol";
import "./Ownable.sol";

contract IStakingProvider {
    function getAccumulatedGemies(address user) external view returns (uint256) {}
}

contract IAttackProvider {
    function userToStolen(address user) external view returns(uint256) {}
}

contract IBank {
    function isAllowedToTransfer(address user, address recipient, uint256 amount) external view returns (bool) {}
    function isAllowedToSpend(address user, uint256 amount) external view returns (bool) {}
    function isAllowedToWithdraw(address user, uint256 amount) external view returns (bool) {}
    function isAllowedToDeposit(address , uint256 amount) external view returns (bool) {}
}

contract Gemies is ERC20, Ownable {
    bool public withdrawalsEnabled;
    bool public depositsEnabled;
    bool public spendingEnabled;
    bool public transfersEnabled;
    bool public useBank;

    mapping(address => bool) public yogiesOperator;
    mapping(address => bool) public yogiesApprovalBypasser;

    /// @dev track users ecosystem deposits and spendings
    /// - first 128 bits are deposited balance
    /// - last 128 bits are spent balance
    mapping(address => uint256) public ecoSystemBalance;
    mapping(address => uint256) public attackRewards;

    IStakingProvider public stakingProvider;
    IAttackProvider public attackProvider;
    IBank public bank;

    address public communityWallet;
    uint256 public communityWalletAllocation;

    modifier onlyOperator() {
        require(yogiesOperator[msg.sender] || msg.sender == owner(), "Sender not authorized");
        _;
    }

    constructor(
        address[] memory _wallets,
        uint256[] memory _amounts
    ) ERC20("Gemies", "$Gemies") {
    }

    function _getEcoSystemBalance(address user) 
        internal
        view 
        returns (uint256) {
            uint256 ecoSystemData = ecoSystemBalance[user];
            uint256 deposit = _getDepositBalance(ecoSystemData);
            uint256 spent = _getSpentBalance(ecoSystemData);

            uint256 positiveBalance = stakingProvider.getAccumulatedGemies(user) + attackProvider.userToStolen(user) + deposit;

            if (spent > positiveBalance)
                return 0;
            
            return positiveBalance - spent;
        }

    function depositInEcosystem(uint256 amount) external {
        require(depositsEnabled, "Deposits disabled");
        if (useBank)
            require(bank.isAllowedToDeposit(msg.sender, amount), "Deposit not allowed by bank");

        require(balanceOf(msg.sender) >= amount, "Sender has not enough balance for deposit");

        _burn(msg.sender, amount);
        
        uint256 ecoSystemData = ecoSystemBalance[msg.sender];
        uint256 deposited = _getDepositBalance(ecoSystemData);
        uint256 spent = _getSpentBalance(ecoSystemData);

        ecoSystemBalance[msg.sender] = _getUpdatedEcoSystemBalance(deposited + amount, spent);
    }

    function withdrawFromEcosystem(uint256 amount) external {
        require(withdrawalsEnabled, "Withdrawals disabled");
        if (useBank)
            require(bank.isAllowedToWithdraw(msg.sender, amount), "Withdraw not allowed by bank");

        require(_getEcoSystemBalance(msg.sender) >= amount, "Cannot withdraw more than available");

        _mint(msg.sender, amount);

        uint256 ecoSystemData = ecoSystemBalance[msg.sender];
        uint256 deposited = _getDepositBalance(ecoSystemData);
        uint256 spent = _getSpentBalance(ecoSystemData);

        ecoSystemBalance[msg.sender] = _getUpdatedEcoSystemBalance(deposited, spent + amount);
    }

    function transferEcosystemBalance(uint256 amount, address to) external {
        require(transfersEnabled, "Transfers disabled");
        if (useBank)
            require(bank.isAllowedToTransfer(msg.sender, to, amount), "Transfer not allowed by bank");

        require(_getEcoSystemBalance(msg.sender) >= amount, "Cannot transfer more than available");

        uint256 ecoSystemDataSender = ecoSystemBalance[msg.sender];
        uint256 ecoSystemDataReceiver = ecoSystemBalance[to];

        uint256 depositedSender = _getDepositBalance(ecoSystemDataSender);
        uint256 spentSender = _getSpentBalance(ecoSystemDataSender);
        
        uint256 depositedReceiver = _getDepositBalance(ecoSystemDataReceiver);
        uint256 spentReceiver = _getSpentBalance(ecoSystemDataReceiver);

        ecoSystemBalance[msg.sender] = _getUpdatedEcoSystemBalance(depositedSender, spentSender + amount);
        ecoSystemBalance[to] = _getUpdatedEcoSystemBalance(depositedReceiver + amount, spentReceiver);
    }

    function spendEcosystemBalance(uint256 amount, address user) external onlyOperator {
        require(spendingEnabled, "Spending disabled");
        if (useBank)
            require(bank.isAllowedToSpend(msg.sender, amount), "Spending not allowed by bank");

        require(_getEcoSystemBalance(user) >= amount, "Cannot spend more than available");

        uint256 ecoSystemData = ecoSystemBalance[user];
        uint256 deposited = _getDepositBalance(ecoSystemData);
        uint256 spent = _getSpentBalance(ecoSystemData);

        ecoSystemBalance[user] = _getUpdatedEcoSystemBalance(deposited, spent + amount);
        ecoSystemBalance[communityWallet] += amount * communityWalletAllocation / 1000;
    }

    function registerAttack(address victim, uint256 amount) external onlyOperator {        
        uint256 ecoSystemDataReceiver = ecoSystemBalance[victim];
        
        uint256 depositedReceiver = _getDepositBalance(ecoSystemDataReceiver);
        uint256 spentReceiver = _getSpentBalance(ecoSystemDataReceiver);

        ecoSystemBalance[victim] = _getUpdatedEcoSystemBalance(depositedReceiver, spentReceiver + amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        if (!yogiesApprovalBypasser[spender]) {
            super._spendAllowance(owner, spender, amount);
        }       
    }

    /** === Getters === */
    function _getDepositBalance(uint256 ecoSystemData) 
        internal
        pure
        returns (uint256) {
            return uint256(uint128(ecoSystemData));
        }
    
    function _getSpentBalance(uint256 ecoSystemData) 
        internal
        pure
        returns (uint256) {
            return uint256(uint128(ecoSystemData >> 128));
        }

    function _getUpdatedEcoSystemBalance(uint256 deposited, uint256 spent)
        internal
        pure
        returns (uint256) {
            uint256 data = deposited;
            data |= spent << 128;
            return data;
        }

    /** === View === */
    function getEcoSystemBalance(address user) 
        external
        view 
        returns (uint256) {
            return _getEcoSystemBalance(user);
        } 

    function getDeposited(address user)
        external
        view 
        returns (uint256) {
            uint256 ecoSystemData = ecoSystemBalance[user];
            return _getDepositBalance(ecoSystemData);
        }

    function getSpent(address user)
        external
        view 
        returns (uint256) {
            uint256 ecoSystemData = ecoSystemBalance[user];
            return _getSpentBalance(ecoSystemData);
        }

    function hasDebt(address user)
        external
        view
        returns (bool) {
            uint256 ecoSystemData = ecoSystemBalance[user];
            uint256 deposit = _getDepositBalance(ecoSystemData);
            uint256 spent = _getSpentBalance(ecoSystemData);

            uint256 positiveBalance = stakingProvider.getAccumulatedGemies(user) + attackProvider.userToStolen(user) + deposit;

            return spent > positiveBalance;
        }

    function debtOfUser(address user)
        external
        view
        returns (uint256) {
            uint256 ecoSystemData = ecoSystemBalance[user];
            uint256 deposit = _getDepositBalance(ecoSystemData);
            uint256 spent = _getSpentBalance(ecoSystemData);

            uint256 positiveBalance = stakingProvider.getAccumulatedGemies(user) + attackProvider.userToStolen(user) + deposit;

            if (spent > positiveBalance)
                return spent - positiveBalance;

            return 0;
        }

    /** === Only Owner === */

    function airdropGemies(address to, uint256 amount) external onlyOwner {
        uint256 ecoSystemData = ecoSystemBalance[to];
        uint256 deposited = _getDepositBalance(ecoSystemData);
        uint256 spent = _getSpentBalance(ecoSystemData);

        ecoSystemBalance[to] = _getUpdatedEcoSystemBalance(deposited + amount, spent);
    }

    function setYogiesOperator(address _operator, bool isOperator)
        external
        onlyOwner {
            yogiesOperator[_operator] = isOperator;
        }

    function setYogiesApprovalBypasser(address _bypasser, bool isOperator)
        external
        onlyOwner {
            yogiesApprovalBypasser[_bypasser] = isOperator;
        }

    function setStakingProvider(address provider)
        external
        onlyOwner {
            stakingProvider = IStakingProvider(provider);
        }
    
    function setAttackProvider(address provider)
        external
        onlyOwner {
            attackProvider = IAttackProvider(provider);
        }

    function setFlags(bool _withdrawals, bool _deposits, bool _spending, bool _transfers, bool _useBank, bool killSwitch)
        external
        onlyOwner {
            if (killSwitch) {
                withdrawalsEnabled = false;
                depositsEnabled = false;
                spendingEnabled = false;
                transfersEnabled = false;
                useBank = false;
            } else {
                withdrawalsEnabled = _withdrawals;
                depositsEnabled = _deposits;
                spendingEnabled = _spending;
                transfersEnabled = _transfers;
                useBank = _useBank;
            }
        }

    function setBank(address _bank) external onlyOwner {
        bank = IBank(_bank);
    }

    function setCommunityWallet(address _wallet, uint256 allocation) external onlyOwner {
        require(allocation <= 1000, "Cannot have a higher allocation than 1000");

        communityWallet = _wallet;
        communityWalletAllocation = allocation;
    }

    function withdrawEth(uint256 percentage, address _to)
        external
        onlyOwner {
            payable(_to).transfer((address(this).balance * percentage) / 100);
        }

    function withdrawERC20(
        uint256 percentage,
        address _erc20Address,
        address _to
    ) external onlyOwner {
        uint256 amountERC20 = ERC20(_erc20Address).balanceOf(address(this));
        ERC20(_erc20Address).transfer(_to, (amountERC20 * percentage) / 100);
    }
}
