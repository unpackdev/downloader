// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ERC777.sol";
import "AccessControl.sol";
import "SafeMath.sol";
import "ReentrancyGuard.sol";

contract BPC is ERC777, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant m_tokens_per_eth = 100;
    address private m_company_account;

    uint256 private m_entry_fee;
    uint256 private m_exit_fee;

    uint256 private m_max_supply;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _default_operators,
        uint256 _max_supply,
        uint256 _initial_supply,
        uint256 _entry_fee,
        uint256 _exit_fee,
        address _managing_account,
        address _company_account
    ) ERC777(_name, _symbol, _default_operators) {
        _grantRole(DEFAULT_ADMIN_ROLE, _managing_account);
        _grantRole(MINTER_ROLE, _company_account);

        m_max_supply = _max_supply;
        _mint(_company_account, _initial_supply, "", "", false);

        m_company_account = _company_account;

        m_entry_fee = _entry_fee;
        m_exit_fee = _exit_fee;
    }

    function mint(uint256 amount) public onlyRole(MINTER_ROLE) {
        require(
            totalSupply().add(amount) <= m_max_supply,
            "Amount that is about to be minted reaches the Max Supply"
        );
        _mint(msg.sender, amount, bytes(""), bytes(""), false);
    }

    //burn and operatorBurn of ERC777 make all required checks and update _totalSupply that holds current Tokens qty
    //no need to override those funcs

    function fromEtherToTokens() public payable {
        uint256 tokens_to_buy = msg.value * m_tokens_per_eth;
        uint256 company_token_balance = this.balanceOf(m_company_account);

        require(
            tokens_to_buy > 0,
            "You need to send some more ether, what you provide is not enough for transaction"
        );
        require(
            tokens_to_buy <= company_token_balance,
            "Not enough tokens in the reserve"
        );

        uint256 updated_value = getEntryFeeValue(tokens_to_buy);
        _send(
            m_company_account,
            msg.sender,
            updated_value,
            bytes(""),
            bytes(""),
            false
        );
    }

    function fromTokensToEther(uint256 tokens_to_sell) public nonReentrant {
        require(tokens_to_sell > 0, "You need to sell at least some tokens");

        // Check that the user's token balance is enough to do the swap
        uint256 user_token_balance = this.balanceOf(msg.sender);
        require(
            user_token_balance >= tokens_to_sell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        uint256 updated_value = getExitFeeValue(tokens_to_sell);

        uint256 eth_to_transfer = updated_value / m_tokens_per_eth;
        uint256 company_eth_balance = address(this).balance;
        require(
            company_eth_balance >= eth_to_transfer,
            "BPC Owner doesn't have enough funds to accept this sell request"
        );

        _send(
            msg.sender,
            m_company_account,
            tokens_to_sell,
            bytes(""),
            bytes(""),
            false
        );
        payable(msg.sender).transfer(eth_to_transfer);
    }

    function getTokenPrice() public view returns (uint256) {
        return m_tokens_per_eth;
    }

    function getEntryFee() public view returns (uint256) {
        return m_entry_fee;
    }

    function getExitFee() public view returns (uint256) {
        return m_exit_fee;
    }

    function setEntryFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            fee >= 0 && fee <= 100,
            "Fee must be an integer percentage, ie 42"
        );
        m_entry_fee = fee;
    }

    function setExitFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            fee >= 0 && fee <= 100,
            "Fee must be an integer percentage, ie 42"
        );
        m_exit_fee = fee;
    }

    function getEntryFeeValue(uint256 value) private view returns (uint256) {
        if (m_entry_fee != 0) {
            uint256 fee_value = (m_entry_fee * value) / 100;
            uint256 updated_value = value - fee_value;
            return updated_value;
        } else {
            return value;
        }
    }

    function getExitFeeValue(uint256 value) private view returns (uint256) {
        if (m_exit_fee != 0) {
            uint256 fee_value = (m_exit_fee * value) / 100;
            uint256 updated_value = value - fee_value;
            return updated_value;
        } else {
            return value;
        }
    }
}
